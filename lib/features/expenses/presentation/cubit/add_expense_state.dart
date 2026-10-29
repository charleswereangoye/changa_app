// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: State of the Add Expense form: values, checks and live preview

import 'package:equatable/equatable.dart';

import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/logic/apply_credits.dart';
import 'package:changa_app/features/expenses/domain/logic/split_calculator.dart';

enum AddExpenseStatus { editing, submitting, success, failure }

/// A housemate who can pay for, or share, an expense.
class ExpenseParticipant extends Equatable {
  const ExpenseParticipant({
    required this.uid,
    required this.name,
    this.credits = 0,
  });

  final String uid;
  final String name;

  /// Credit balance in credits (1 credit = RWF 10).
  final int credits;

  @override
  List<Object?> get props => [uid, name, credits];
}

/// What the split would look like if the form were saved now.
class SplitPreview extends Equatable {
  const SplitPreview({required this.shares, required this.creditsUsed});

  /// uid -> share in whole RWF, for everyone who shares the expense.
  final Map<String, int> shares;

  /// Credits that would be used across everyone who owes the payer.
  final int creditsUsed;

  /// 1 credit = RWF 10.
  int get creditsInRwf => creditsUsed * 10;

  @override
  List<Object?> get props => [shares, creditsUsed];
}

class AddExpenseState extends Equatable {
  const AddExpenseState({
    required this.participants,
    required this.paidByUid,
    required this.selectedUids,
    required this.splitType,
    this.status = AddExpenseStatus.editing,
    this.failureMessage,
    this.amountText = '',
    this.title = '',
    this.category = ExpenseCategory.other,
    this.weightTexts = const {},
    this.amountTouched = false,
    this.titleTouched = false,
  });

  static const int _maxAmount = 100000000;

  final List<ExpenseParticipant> participants;
  final String paidByUid;

  /// Who shares the cost, in the order they were selected.
  final List<String> selectedUids;
  final SplitType splitType;
  final AddExpenseStatus status;
  final String? failureMessage;
  final String amountText;
  final String title;
  final ExpenseCategory category;

  /// Percent or RWF typed for each selected person (percent and exact only).
  final Map<String, String> weightTexts;
  final bool amountTouched;
  final bool titleTouched;

  int? get amount => int.tryParse(amountText);

  String? get amountProblem {
    final value = amount;
    if (value == null) return 'Enter the amount you paid.';
    if (value < 1 || value > _maxAmount) {
      return 'Amount must be between 1 and 100,000,000 RWF.';
    }
    return null;
  }

  String? get titleProblem {
    final length = title.trim().length;
    if (length < 3) return 'Give it a short title, at least 3 characters.';
    if (length > 60) return 'Keep the title under 60 characters.';
    return null;
  }

  /// Shown under the field only after the person has typed in it.
  String? get amountError => amountTouched ? amountProblem : null;
  String? get titleError => titleTouched ? titleProblem : null;

  String? get participantsProblem {
    final others = selectedUids.where((uid) => uid != paidByUid);
    return others.isEmpty
        ? 'Choose at least one housemate besides the payer.'
        : null;
  }

  /// Percent or RWF per selected person. Empty boxes count as 0.
  Map<String, int> get weights => {
    for (final uid in selectedUids)
      uid: int.tryParse(weightTexts[uid] ?? '') ?? 0,
  };

  int get weightsTotal => weights.values.fold(0, (a, b) => a + b);

  /// For an exact split: how much of the total is still unassigned.
  int get remaining => (amount ?? 0) - weightsTotal;

  String? get splitProblem => switch (splitType) {
    SplitType.equal => null,
    SplitType.percent =>
      weightsTotal == 100 ? null : 'Percentages must add up to 100.',
    SplitType.exact =>
      (amount == null || weightsTotal == amount)
          ? null
          : 'Amounts must add up to the total.',
  };

  /// Shown only once the person has started typing percentages or amounts.
  String? get visibleSplitProblem => weightTexts.isEmpty ? null : splitProblem;

  SplitPreview? get preview {
    final total = amount;
    if (total == null || amountProblem != null) return null;
    if (selectedUids.isEmpty || splitProblem != null) return null;

    try {
      final shares = SplitCalculator.calculate(
        total: total,
        participants: selectedUids,
        splitType: splitType,
        weights: splitType == SplitType.equal ? const {} : weights,
      );

      var creditsUsed = 0;
      for (final entry in shares.entries) {
        if (entry.key == paidByUid) continue; // the payer owes nobody
        creditsUsed += ApplyCredits.apply(
          share: entry.value,
          creditBalance: _creditsOf(entry.key),
        ).creditsUsed;
      }
      return SplitPreview(shares: shares, creditsUsed: creditsUsed);
    } on SplitInputException {
      return null;
    }
  }

  bool get isValid =>
      amountProblem == null &&
      titleProblem == null &&
      participantsProblem == null &&
      splitProblem == null &&
      preview != null;

  int _creditsOf(String uid) {
    for (final participant in participants) {
      if (participant.uid == uid) return participant.credits;
    }
    return 0;
  }

  AddExpenseState copyWith({
    String? paidByUid,
    List<String>? selectedUids,
    SplitType? splitType,
    AddExpenseStatus? status,
    String? failureMessage,
    String? amountText,
    String? title,
    ExpenseCategory? category,
    Map<String, String>? weightTexts,
    bool? amountTouched,
    bool? titleTouched,
  }) {
    return AddExpenseState(
      participants: participants,
      paidByUid: paidByUid ?? this.paidByUid,
      selectedUids: selectedUids ?? this.selectedUids,
      splitType: splitType ?? this.splitType,
      status: status ?? this.status,
      failureMessage: failureMessage ?? this.failureMessage,
      amountText: amountText ?? this.amountText,
      title: title ?? this.title,
      category: category ?? this.category,
      weightTexts: weightTexts ?? this.weightTexts,
      amountTouched: amountTouched ?? this.amountTouched,
      titleTouched: titleTouched ?? this.titleTouched,
    );
  }

  @override
  List<Object?> get props => [
    participants,
    paidByUid,
    selectedUids,
    splitType,
    status,
    failureMessage,
    amountText,
    title,
    category,
    weightTexts,
    amountTouched,
    titleTouched,
  ];
}
