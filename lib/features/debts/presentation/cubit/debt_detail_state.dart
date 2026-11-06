part of 'debt_detail_cubit.dart';

enum DebtDetailStatus { initial, loading, loaded, failure }

enum NudgeStatus { idle, sending, sent, failure }

class DebtDetailState extends Equatable {
  DebtDetailState({
    this.status = DebtDetailStatus.initial,
    List<Debt> debts = const [],
    Map<String, Expense> expensesById = const {},
    this.netBalance = 0,
    this.failure,
    this.nudgeStatus = NudgeStatus.idle,
    this.nudgeFailure,
  }) : debts = List<Debt>.unmodifiable(debts),
       expensesById = Map<String, Expense>.unmodifiable(expensesById);

  final DebtDetailStatus status;

  /// Pending debts between the two members, newest first.
  final List<Debt> debts;

  final Map<String, Expense> expensesById;

  /// Positive: they owe me. Negative: I owe them.
  final int netBalance;

  final Failure? failure;
  final NudgeStatus nudgeStatus;
  final Failure? nudgeFailure;

  bool get canNudge =>
      status == DebtDetailStatus.loaded &&
      netBalance > 0 &&
      nudgeStatus != NudgeStatus.sending;

  bool get canSettle =>
      status == DebtDetailStatus.loaded &&
      debts.isNotEmpty &&
      nudgeStatus != NudgeStatus.sending;

  DebtDetailState copyWith({
    DebtDetailStatus? status,
    List<Debt>? debts,
    Map<String, Expense>? expensesById,
    int? netBalance,
    Failure? failure,
    bool clearFailure = false,
    NudgeStatus? nudgeStatus,
    Failure? nudgeFailure,
    bool clearNudgeFailure = false,
  }) {
    return DebtDetailState(
      status: status ?? this.status,
      debts: debts ?? this.debts,
      expensesById: expensesById ?? this.expensesById,
      netBalance: netBalance ?? this.netBalance,
      failure: clearFailure ? null : failure ?? this.failure,
      nudgeStatus: nudgeStatus ?? this.nudgeStatus,
      nudgeFailure: clearNudgeFailure
          ? null
          : nudgeFailure ?? this.nudgeFailure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    debts,
    expensesById,
    netBalance,
    failure,
    nudgeStatus,
    nudgeFailure,
  ];
}
