part of 'add_chore_cubit.dart';

enum AddChoreStatus { editing, submitting, success, failure }

/// A housemate who can be given the chore.
class ChoreAssignee extends Equatable {
  const ChoreAssignee({required this.uid, required this.name});

  final String uid;
  final String name;

  @override
  List<Object?> get props => [uid, name];
}

class AddChoreState extends Equatable {
  const AddChoreState({
    required this.assignees,
    required this.difficulty,
    required this.assigneeUid,
    required this.dueDate,
    this.title = '',
    this.rotate = false,
    this.isEdit = false,
    this.isSeries = false,
    this.isLocked = false,
    this.showTitleError = false,
    this.status = AddChoreStatus.editing,
    this.message,
  });

  final List<ChoreAssignee> assignees;
  final String title;
  final ChoreDifficulty difficulty;
  final String assigneeUid;
  final DateTime dueDate;
  final bool rotate;

  /// True when an existing chore is being changed.
  final bool isEdit;

  /// The chore being edited belongs to a weekly rotation.
  final bool isSeries;

  /// A finished chore can no longer be changed.
  final bool isLocked;

  final bool showTitleError;
  final AddChoreStatus status;

  /// Success text, or the reason a save failed.
  final String? message;

  bool get isBusy => status == AddChoreStatus.submitting;

  bool get hasValidTitle {
    final length = title.trim().length;
    return length > 0 && length <= AddChoreCubit.maxTitleLength;
  }

  bool get canSubmit => hasValidTitle && !isBusy && !isLocked;

  String? get titleError =>
      showTitleError && !hasValidTitle ? 'Give the chore a short name.' : null;

  AddChoreState copyWith({
    String? title,
    ChoreDifficulty? difficulty,
    String? assigneeUid,
    DateTime? dueDate,
    bool? rotate,
    bool? showTitleError,
    AddChoreStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return AddChoreState(
      assignees: assignees,
      title: title ?? this.title,
      difficulty: difficulty ?? this.difficulty,
      assigneeUid: assigneeUid ?? this.assigneeUid,
      dueDate: dueDate ?? this.dueDate,
      rotate: rotate ?? this.rotate,
      isEdit: isEdit,
      isSeries: isSeries,
      isLocked: isLocked,
      showTitleError: showTitleError ?? this.showTitleError,
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    assignees,
    title,
    difficulty,
    assigneeUid,
    dueDate,
    rotate,
    isEdit,
    isSeries,
    isLocked,
    showTitleError,
    status,
    message,
  ];
}
