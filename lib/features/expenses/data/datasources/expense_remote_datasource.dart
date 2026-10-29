// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Firestore datasource for expenses: atomic add, delete, note edit
// ignore_for_file: prefer_initializing_formals

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/expenses/data/models/expense_model.dart';
import 'package:changa_app/features/expenses/domain/entities/new_expense_input.dart';
import 'package:changa_app/features/expenses/domain/logic/apply_credits.dart';
import 'package:changa_app/features/expenses/domain/logic/split_calculator.dart';
import 'package:changa_app/features/notifications/data/notification_templates.dart';
import 'package:changa_app/features/notifications/data/notification_writer.dart';

/// Thrown when an expense action breaks a business rule (bad input, not the
/// creator, a debt is already settled). The repository turns it into a
/// `Result.failure`.
class ExpenseException implements Exception {
  const ExpenseException(this.failure);

  final Failure failure;

  @override
  String toString() => 'ExpenseException: ${failure.message}';
}

class ExpenseRemoteDataSource {
  ExpenseRemoteDataSource({
    required FirebaseFirestore firestore,
    required ActivityWriter activityWriter,
    required NotificationWriter notificationWriter,
    required String? Function() currentUid,
  }) : _firestore = firestore,
       _activityWriter = activityWriter,
       _notificationWriter = notificationWriter,
       _currentUid = currentUid;

  final FirebaseFirestore _firestore;
  final ActivityWriter _activityWriter;
  final NotificationWriter _notificationWriter;
  final String? Function() _currentUid;

  static const int _maxAmount = 100000000;
  static const int _minTitleLength = 3;
  static const int _maxTitleLength = 60;

  /// Saves the expense, one debt per housemate who owes, the credits those
  /// debts used, the activity line and the notifications in ONE batch.
  /// If any write fails nothing is saved.
  Future<ExpenseModel> addExpense(NewExpenseInput input) async {
    final actorUid = _requireUid();
    final householdId = input.householdId;
    final title = input.title.trim();

    _validateTitle(title);
    if (input.totalAmount <= 0 || input.totalAmount > _maxAmount) {
      throw const ExpenseException(
        ValidationFailure('Amount must be between 1 and 100,000,000 RWF.'),
      );
    }

    // Throws SplitInputException for bad percentages or amounts.
    final shares = SplitCalculator.calculate(
      total: input.totalAmount,
      participants: input.participantUids,
      splitType: input.splitType,
      weights: input.weights,
    );

    // The payer owes nobody, so only the other participants get a debt.
    final debtorUids = shares.keys
        .where((uid) => uid != input.paidByUid)
        .toList();
    if (debtorUids.isEmpty) {
      throw const ExpenseException(
        ValidationFailure('Choose at least one housemate besides the payer.'),
      );
    }

    final creditsByUid = await _readCredits(householdId, debtorUids);
    final payerName = await _readPayerName(input.paidByUid);

    final expenseRef = _firestore
        .collection(FirestorePaths.expenses(householdId))
        .doc();
    final expense = ExpenseModel(
      id: expenseRef.id,
      title: title,
      note: _cleanNote(input.note),
      category: input.category,
      totalAmount: input.totalAmount,
      paidByUid: input.paidByUid,
      splitType: input.splitType,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(expenseRef, expense.toMap(useServerTimestamp: true));

    for (final uid in debtorUids) {
      final share = shares[uid]!;
      final applied = ApplyCredits.apply(
        share: share,
        creditBalance: creditsByUid[uid]!,
      );
      final settled = applied.amountDue == 0;

      final debtRef = _firestore
          .collection(FirestorePaths.debts(householdId))
          .doc();
      batch.set(debtRef, {
        DebtFields.expenseId: expenseRef.id,
        DebtFields.debtorUid: uid,
        DebtFields.creditorUid: input.paidByUid,
        DebtFields.amount: applied.amountDue,
        DebtFields.creditsApplied: applied.creditsUsed,
        DebtFields.status: settled
            ? DebtStatus.settled.name
            : DebtStatus.pending.name,
        DebtFields.settlementMethod: settled
            ? SettlementMethod.credits.name
            : null,
        DebtFields.settledAt: settled ? FieldValue.serverTimestamp() : null,
        DebtFields.createdAt: FieldValue.serverTimestamp(),
      });

      if (applied.creditsUsed > 0) {
        batch.update(_firestore.doc(FirestorePaths.member(householdId, uid)), {
          MemberFields.credits: FieldValue.increment(-applied.creditsUsed),
        });
      }

      _notificationWriter.addToBatch(
        batch: batch,
        householdId: householdId,
        recipientUid: uid,
        actorUid: actorUid,
        type: 'newExpense',
        message: NotificationTemplates.newExpense(
          payer: payerName,
          title: title,
          amount: share,
        ),
        refId: expenseRef.id,
      );
    }

    _activityWriter.addToBatch(
      batch,
      householdId: householdId,
      type: ActivityType.expenseAdded,
      actorUid: actorUid,
      refId: expenseRef.id,
      amount: input.totalAmount,
    );

    await batch.commit();
    return expense;
  }

  /// Deletes an expense and its debts and gives the credits back.
  /// Only the person who paid can delete, and only while no debt on it has
  /// been paid.
  Future<void> deleteExpense({
    required String householdId,
    required String expenseId,
  }) async {
    final actorUid = _requireUid();
    final expenseRef = _firestore.doc(
      FirestorePaths.expense(householdId, expenseId),
    );

    final expenseSnap = await expenseRef.get();
    if (!expenseSnap.exists) {
      throw const ExpenseException(
        NotFoundFailure('This expense no longer exists.'),
      );
    }
    final expense = ExpenseModel.fromFirestore(expenseSnap);
    if (expense.paidByUid != actorUid) {
      throw const ExpenseException(
        PermissionFailure('Only the person who paid can delete this expense.'),
      );
    }

    final debtsSnap = await _firestore
        .collection(FirestorePaths.debts(householdId))
        .where(DebtFields.expenseId, isEqualTo: expenseId)
        .get();

    // A debt that credits covered completely when the expense was added has
    // amount 0 and is already "settled"; it does not block deleting.
    final hasPaidDebt = debtsSnap.docs.any((doc) {
      final data = doc.data();
      final amount = (data[DebtFields.amount] as num?)?.toInt() ?? 0;
      return data[DebtFields.status] == DebtStatus.settled.name && amount > 0;
    });
    if (hasPaidDebt) {
      throw const ExpenseException(
        ValidationFailure(
          'This expense cannot be deleted because someone has already paid their share.',
        ),
      );
    }

    final batch = _firestore.batch();
    batch.delete(expenseRef);

    for (final doc in debtsSnap.docs) {
      final data = doc.data();
      batch.delete(doc.reference);

      final creditsApplied =
          (data[DebtFields.creditsApplied] as num?)?.toInt() ?? 0;
      if (creditsApplied <= 0) continue;

      // Skip the refund if the debtor has since left the household.
      final memberRef = _firestore.doc(
        FirestorePaths.member(
          householdId,
          data[DebtFields.debtorUid] as String,
        ),
      );
      if ((await memberRef.get()).exists) {
        batch.update(memberRef, {
          MemberFields.credits: FieldValue.increment(creditsApplied),
        });
      }
    }

    _activityWriter.addToBatch(
      batch,
      householdId: householdId,
      type: ActivityType.expenseDeleted,
      actorUid: actorUid,
      refId: expenseId,
      amount: expense.totalAmount,
    );

    await batch.commit();
  }

  /// Changes only the title and the note.
  Future<void> updateExpenseNote({
    required String householdId,
    required String expenseId,
    required String title,
    String? note,
  }) async {
    _requireUid();
    final cleanTitle = title.trim();
    _validateTitle(cleanTitle);

    await _firestore.doc(FirestorePaths.expense(householdId, expenseId)).update(
      {ExpenseFields.title: cleanTitle, ExpenseFields.note: _cleanNote(note)},
    );
  }

  /// Newest expense first.
  Stream<List<ExpenseModel>> watchExpenses(String householdId) {
    return _firestore
        .collection(FirestorePaths.expenses(householdId))
        .orderBy(ExpenseFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ExpenseModel.fromFirestore).toList(),
        );
  }

  String _requireUid() {
    final uid = _currentUid();
    if (uid == null) {
      throw const ExpenseException(
        PermissionFailure('Please sign in again to continue.'),
      );
    }
    return uid;
  }

  void _validateTitle(String title) {
    if (title.length < _minTitleLength || title.length > _maxTitleLength) {
      throw const ExpenseException(
        ValidationFailure('Title must be 3 to 60 characters.'),
      );
    }
  }

  String? _cleanNote(String? note) {
    final trimmed = note?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<Map<String, int>> _readCredits(
    String householdId,
    List<String> uids,
  ) async {
    final snaps = await Future.wait(
      uids.map(
        (uid) => _firestore.doc(FirestorePaths.member(householdId, uid)).get(),
      ),
    );

    final credits = <String, int>{};
    for (var i = 0; i < uids.length; i++) {
      final snap = snaps[i];
      if (!snap.exists) {
        throw const ExpenseException(
          ValidationFailure(
            'A selected housemate is no longer in this household.',
          ),
        );
      }
      credits[uids[i]] =
          (snap.data()?[MemberFields.credits] as num?)?.toInt() ?? 0;
    }
    return credits;
  }

  /// Used in the notification text. Falls back to a friendly word if the
  /// profile cannot be read.
  Future<String> _readPayerName(String uid) async {
    try {
      final snap = await _firestore.doc(FirestorePaths.user(uid)).get();
      final name = snap.data()?[UserFields.fullName] as String?;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    } on FirebaseException {
      // Fall through to the default name.
    }
    return 'A housemate';
  }
}
