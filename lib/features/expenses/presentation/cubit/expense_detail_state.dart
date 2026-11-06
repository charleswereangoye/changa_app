// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: States for ExpenseDetailCubit

part of 'expense_detail_cubit.dart';

enum ExpenseDetailStatus { viewing, editing, saving, saved, deleting, deleted }

/// Whether we know who has paid yet.
enum ExpenseDebtsStatus { loading, ready, failed }

class ExpenseDetailState extends Equatable {
  const ExpenseDetailState({
    required this.expense,
    required this.canManage,
    this.status = ExpenseDetailStatus.viewing,
    this.titleDraft = '',
    this.noteDraft = '',
    this.failure,
    this.debtsStatus = ExpenseDebtsStatus.loading,
    this.debts = const [],
  });

  final Expense expense;

  /// Only the person who paid can edit or delete.
  final bool canManage;
  final ExpenseDetailStatus status;
  final String titleDraft;
  final String noteDraft;
  final Failure? failure;

  final ExpenseDebtsStatus debtsStatus;
  final List<Debt> debts;

  bool get isEditing =>
      status == ExpenseDetailStatus.editing ||
      status == ExpenseDetailStatus.saving;

  bool get isBusy =>
      status == ExpenseDetailStatus.saving ||
      status == ExpenseDetailStatus.deleting;

  /// Per-person shares. Empty until the debts have loaded.
  List<ExpenseShare> get shares => debtsStatus == ExpenseDebtsStatus.ready
      ? ExpenseShares.from(expense, debts)
      : const [];

  /// Why Delete is off, or null when nobody has paid yet. Uses the last
  /// known debts, so a failed reload never re-enables it by mistake.
  String? get deleteBlockedReason {
    final paid = ExpenseShares.paidCount(debts);
    if (paid == 0) return null;
    return paid == 1
        ? 'One housemate has already paid their share, so this expense can '
              'no longer be deleted.'
        : '$paid housemates have already paid their share, so this expense '
              'can no longer be deleted.';
  }

  /// Delete is offered only to the payer, when nothing was paid yet and we
  /// know that. If the payments cannot be loaded the button stays on and the
  /// data layer still refuses a delete that is not allowed.
  bool get canDelete =>
      canManage &&
      !isBusy &&
      debtsStatus != ExpenseDebtsStatus.loading &&
      deleteBlockedReason == null;

  /// True only when the draft is valid and different from what is saved.
  String? get titleProblem {
    final length = titleDraft.trim().length;
    if (length < 3) return 'Give it a short title, at least 3 characters.';
    if (length > 60) return 'Keep the title under 60 characters.';
    return null;
  }

  bool get canSave {
    if (status != ExpenseDetailStatus.editing || titleProblem != null) {
      return false;
    }
    final titleChanged = titleDraft.trim() != expense.title;
    final noteChanged = noteDraft.trim() != (expense.note ?? '');
    return titleChanged || noteChanged;
  }

  ExpenseDetailState copyWith({
    Expense? expense,
    ExpenseDetailStatus? status,
    String? titleDraft,
    String? noteDraft,
    Failure? failure,
    bool clearFailure = false,
    ExpenseDebtsStatus? debtsStatus,
    List<Debt>? debts,
  }) {
    return ExpenseDetailState(
      expense: expense ?? this.expense,
      canManage: canManage,
      status: status ?? this.status,
      titleDraft: titleDraft ?? this.titleDraft,
      noteDraft: noteDraft ?? this.noteDraft,
      failure: clearFailure ? null : (failure ?? this.failure),
      debtsStatus: debtsStatus ?? this.debtsStatus,
      debts: debts ?? this.debts,
    );
  }

  @override
  List<Object?> get props => [
    expense,
    canManage,
    status,
    titleDraft,
    noteDraft,
    failure,
    debtsStatus,
    debts,
  ];
}
