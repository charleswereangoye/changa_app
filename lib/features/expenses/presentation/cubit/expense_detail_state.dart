// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: States for ExpenseDetailCubit

part of 'expense_detail_cubit.dart';

enum ExpenseDetailStatus { viewing, editing, saving, saved, deleting, deleted }

class ExpenseDetailState extends Equatable {
  const ExpenseDetailState({
    required this.expense,
    required this.canManage,
    this.status = ExpenseDetailStatus.viewing,
    this.titleDraft = '',
    this.noteDraft = '',
    this.failure,
  });

  final Expense expense;

  /// Only the person who paid can edit or delete.
  final bool canManage;
  final ExpenseDetailStatus status;
  final String titleDraft;
  final String noteDraft;
  final Failure? failure;

  bool get isEditing =>
      status == ExpenseDetailStatus.editing ||
      status == ExpenseDetailStatus.saving;

  bool get isBusy =>
      status == ExpenseDetailStatus.saving ||
      status == ExpenseDetailStatus.deleting;

  String? get titleProblem {
    final length = titleDraft.trim().length;
    if (length < 3) return 'Give it a short title, at least 3 characters.';
    if (length > 60) return 'Keep the title under 60 characters.';
    return null;
  }

  /// True only when the draft is valid and different from what is saved.
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
  }) {
    return ExpenseDetailState(
      expense: expense ?? this.expense,
      canManage: canManage,
      status: status ?? this.status,
      titleDraft: titleDraft ?? this.titleDraft,
      noteDraft: noteDraft ?? this.noteDraft,
      failure: clearFailure ? null : (failure ?? this.failure),
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
  ];
}
