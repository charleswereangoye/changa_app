import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:changa_app/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/new_expense_input.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/notifications/data/notification_writer.dart';

void main() {
  const hid = 'house1';

  late FakeFirebaseFirestore db;
  late ExpenseRemoteDataSource amaraSource;

  ExpenseRemoteDataSource sourceFor(String uid) => ExpenseRemoteDataSource(
    firestore: db,
    activityWriter: ActivityWriter(firestore: db),
    notificationWriter: NotificationWriter(db),
    currentUid: () => uid,
  );

  NewExpenseInput equalInput({int total = 12000}) => NewExpenseInput(
    householdId: hid,
    title: 'Groceries',
    category: ExpenseCategory.groceries,
    totalAmount: total,
    paidByUid: 'amara',
    splitType: SplitType.equal,
    participantUids: const ['amara', 'bob', 'chloe'],
  );

  Future<void> seedMember(String uid, int credits) => db
      .doc(FirestorePaths.member(hid, uid))
      .set({MemberFields.credits: credits});

  Future<List<Map<String, dynamic>>> docsOf(String path) async {
    final snap = await db.collection(path).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<int> creditsOf(String uid) async {
    final snap = await db.doc(FirestorePaths.member(hid, uid)).get();
    return (snap.data()![MemberFields.credits] as num).toInt();
  }

  setUp(() async {
    db = FakeFirebaseFirestore();
    amaraSource = sourceFor('amara');
    await db.doc(FirestorePaths.user('amara')).set({
      UserFields.fullName: 'Amara K',
    });
    await seedMember('amara', 0);
    await seedMember('bob', 340); // 340 credits = RWF 3,400
    await seedMember('chloe', 0);
  });

  group('addExpense', () {
    test(
      'writes expense, debts, credits, activity and notifications',
      () async {
        final expense = await amaraSource.addExpense(equalInput());

        expect(expense.totalAmount, 12000);

        final expenses = await docsOf(FirestorePaths.expenses(hid));
        expect(expenses, hasLength(1));
        expect(expenses.single[ExpenseFields.paidByUid], 'amara');

        // 12,000 split three ways = 4,000 each. The payer owes nobody.
        final debts = await docsOf(FirestorePaths.debts(hid));
        expect(debts, hasLength(2));

        final bobDebt = debts.firstWhere(
          (d) => d[DebtFields.debtorUid] == 'bob',
        );
        expect(bobDebt[DebtFields.amount], 600); // 4,000 - 3,400 of credits
        expect(bobDebt[DebtFields.creditsApplied], 340);
        expect(bobDebt[DebtFields.status], 'pending');
        expect(bobDebt[DebtFields.creditorUid], 'amara');
        expect(bobDebt[DebtFields.expenseId], expense.id);

        final chloeDebt = debts.firstWhere(
          (d) => d[DebtFields.debtorUid] == 'chloe',
        );
        expect(chloeDebt[DebtFields.amount], 4000);
        expect(chloeDebt[DebtFields.creditsApplied], 0);

        expect(await creditsOf('bob'), 0);
        expect(await creditsOf('chloe'), 0);

        final activities = await docsOf(FirestorePaths.activities(hid));
        expect(activities, hasLength(1));
        expect(activities.single[ActivityFields.type], 'expenseAdded');
        expect(activities.single[ActivityFields.refId], expense.id);

        final notifications = await docsOf(FirestorePaths.notifications(hid));
        expect(notifications, hasLength(2));
      },
    );

    test(
      'a debt fully covered by credits is settled with method credits',
      () async {
        await seedMember('bob', 1000); // RWF 10,000 of credits

        await amaraSource.addExpense(equalInput());

        final debts = await docsOf(FirestorePaths.debts(hid));
        final bobDebt = debts.firstWhere(
          (d) => d[DebtFields.debtorUid] == 'bob',
        );
        expect(bobDebt[DebtFields.amount], 0);
        expect(bobDebt[DebtFields.creditsApplied], 400);
        expect(bobDebt[DebtFields.status], 'settled');
        expect(bobDebt[DebtFields.settlementMethod], 'credits');
        expect(await creditsOf('bob'), 600);
      },
    );

    test('rejects a title that is too short and saves nothing', () async {
      final input = NewExpenseInput(
        householdId: hid,
        title: 'ab',
        category: ExpenseCategory.other,
        totalAmount: 5000,
        paidByUid: 'amara',
        splitType: SplitType.equal,
        participantUids: const ['amara', 'bob'],
      );

      await expectLater(
        amaraSource.addExpense(input),
        throwsA(isA<ExpenseException>()),
      );
      expect(await docsOf(FirestorePaths.expenses(hid)), isEmpty);
    });
  });

  group('ExpenseRepositoryImpl', () {
    test(
      'turns a percent split that is not 100 into a ValidationFailure',
      () async {
        final repo = ExpenseRepositoryImpl(remoteDataSource: amaraSource);
        final input = NewExpenseInput(
          householdId: hid,
          title: 'Electricity',
          category: ExpenseCategory.utilities,
          totalAmount: 10000,
          paidByUid: 'amara',
          splitType: SplitType.percent,
          participantUids: const ['amara', 'bob'],
          weights: const {'amara': 50, 'bob': 40},
        );

        final result = await repo.addExpense(input);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(await docsOf(FirestorePaths.expenses(hid)), isEmpty);
      },
    );

    test('addExpense returns the saved expense on success', () async {
      final repo = ExpenseRepositoryImpl(remoteDataSource: amaraSource);

      final result = await repo.addExpense(equalInput());

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.title, 'Groceries');
    });
  });

  group('deleteExpense', () {
    test('removes expense and debts, refunds credits, adds activity', () async {
      final expense = await amaraSource.addExpense(equalInput());
      expect(await creditsOf('bob'), 0);

      await amaraSource.deleteExpense(householdId: hid, expenseId: expense.id);

      expect(await docsOf(FirestorePaths.expenses(hid)), isEmpty);
      expect(await docsOf(FirestorePaths.debts(hid)), isEmpty);
      expect(await creditsOf('bob'), 340);

      final activities = await docsOf(FirestorePaths.activities(hid));
      expect(
        activities.map((a) => a[ActivityFields.type]),
        containsAll(['expenseAdded', 'expenseDeleted']),
      );
    });

    test('only the person who paid can delete', () async {
      final expense = await amaraSource.addExpense(equalInput());

      await expectLater(
        sourceFor('bob').deleteExpense(householdId: hid, expenseId: expense.id),
        throwsA(
          isA<ExpenseException>().having(
            (e) => e.failure,
            'failure',
            isA<PermissionFailure>(),
          ),
        ),
      );
      expect(await docsOf(FirestorePaths.expenses(hid)), hasLength(1));
    });

    test('is blocked when someone has already paid their share', () async {
      final expense = await amaraSource.addExpense(equalInput());

      final debts = await db.collection(FirestorePaths.debts(hid)).get();
      final chloeDebt = debts.docs.firstWhere(
        (d) => d.data()[DebtFields.debtorUid] == 'chloe',
      );
      await chloeDebt.reference.update({DebtFields.status: 'settled'});

      await expectLater(
        amaraSource.deleteExpense(householdId: hid, expenseId: expense.id),
        throwsA(
          isA<ExpenseException>().having(
            (e) => e.failure,
            'failure',
            isA<ValidationFailure>(),
          ),
        ),
      );
      expect(await docsOf(FirestorePaths.expenses(hid)), hasLength(1));
      expect(await creditsOf('bob'), 0);
    });
  });

  group('updateExpenseNote', () {
    test('changes only the title and the note', () async {
      final expense = await amaraSource.addExpense(equalInput());

      await amaraSource.updateExpenseNote(
        householdId: hid,
        expenseId: expense.id,
        title: 'Simba Supermarket',
        note: '  bought rice  ',
      );

      final saved = (await docsOf(FirestorePaths.expenses(hid))).single;
      expect(saved[ExpenseFields.title], 'Simba Supermarket');
      expect(saved[ExpenseFields.note], 'bought rice');
      expect(saved[ExpenseFields.totalAmount], 12000);
    });
  });

  group('watchExpenses', () {
    test('emits the saved expenses', () async {
      await amaraSource.addExpense(equalInput());

      final list = await amaraSource.watchExpenses(hid).first;

      expect(list, hasLength(1));
      expect(list.single.title, 'Groceries');
    });
  });
}
