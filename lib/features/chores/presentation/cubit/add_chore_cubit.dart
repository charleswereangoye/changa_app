import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/entities/new_chore_input.dart';
import 'package:changa_app/features/chores/domain/usecases/create_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/delete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/update_chore.dart';

part 'add_chore_state.dart';

/// Runs the add / edit chore form. Pass [editing] to change an existing
/// chore; leave it out to create a new one.
class AddChoreCubit extends Cubit<AddChoreState> {
  AddChoreCubit({
    required this._createChore,
    required this._updateChore,
    required this._deleteChore,
    required this.householdId,
    required this.meUid,
    required List<ChoreAssignee> assignees,
    Chore? editing,
    DateTime Function()? clock,
  }) : _editing = editing,
       super(
         _initial(
           assignees: assignees,
           meUid: meUid,
           editing: editing,
           today: DateHelpers.startOfDay((clock ?? DateTime.now)()),
         ),
       );

  static const maxTitleLength = 40;

  final CreateChore _createChore;
  final UpdateChore _updateChore;
  final DeleteChore _deleteChore;
  final String householdId;
  final String meUid;
  final Chore? _editing;

  static AddChoreState _initial({
    required List<ChoreAssignee> assignees,
    required String meUid,
    required Chore? editing,
    required DateTime today,
  }) {
    if (editing != null) {
      return AddChoreState(
        assignees: assignees,
        title: editing.title,
        difficulty: editing.difficulty,
        assigneeUid: editing.assignedToUid,
        dueDate: DateHelpers.startOfDay(editing.dueDate),
        isEdit: true,
        isSeries: editing.isRecurring,
        isLocked: editing.isDone,
      );
    }

    final meIsMember = assignees.any((a) => a.uid == meUid);
    return AddChoreState(
      assignees: assignees,
      difficulty: ChoreDifficulty.medium,
      assigneeUid: meIsMember
          ? meUid
          : (assignees.isEmpty ? '' : assignees.first.uid),
      dueDate: today,
    );
  }

  void titleChanged(String value) =>
      emit(state.copyWith(title: value, showTitleError: false));

  void difficultyChanged(ChoreDifficulty value) =>
      emit(state.copyWith(difficulty: value));

  void assigneeChanged(String uid) {
    if (state.assignees.any((a) => a.uid == uid)) {
      emit(state.copyWith(assigneeUid: uid));
    }
  }

  void dueDateChanged(DateTime day) =>
      emit(state.copyWith(dueDate: DateHelpers.startOfDay(day)));

  void rotateChanged(bool value) {
    // A rotation is only set up when the chore is created.
    if (state.isEdit) return;
    emit(state.copyWith(rotate: value));
  }

  Future<void> submit() async {
    if (state.isBusy || state.isLocked) return;
    if (!state.hasValidTitle) {
      emit(state.copyWith(showTitleError: true));
      return;
    }
    if (state.assigneeUid.isEmpty) {
      emit(
        state.copyWith(
          status: AddChoreStatus.failure,
          message: 'Choose who is doing this chore.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AddChoreStatus.submitting, clearMessage: true));

    final title = state.title.trim();
    final editing = _editing;
    final result = editing == null
        ? await _createChore(
            NewChoreInput(
              householdId: householdId,
              title: title,
              difficulty: state.difficulty,
              assignedToUid: state.assigneeUid,
              dueDate: state.dueDate,
              createdByUid: meUid,
              rotate: state.rotate,
            ),
          )
        : await _updateChore(
            householdId,
            editing.copyWith(
              title: title,
              difficulty: state.difficulty,
              assignedToUid: state.assigneeUid,
              dueDate: state.dueDate,
            ),
          );

    if (isClosed) return;
    _finish(result, editing == null ? 'added' : 'updated');
  }

  /// Removes the chore being edited. With [wholeSeries] every weekly copy of
  /// a rotating chore goes with it.
  Future<void> delete({bool wholeSeries = false}) async {
    final editing = _editing;
    if (editing == null || state.isBusy) return;

    emit(state.copyWith(status: AddChoreStatus.submitting, clearMessage: true));
    final result = await _deleteChore(
      householdId,
      editing.id,
      wholeSeries: wholeSeries,
    );

    if (isClosed) return;
    _finish(result, 'deleted');
  }

  void _finish(Result<void> result, String verb) {
    if (result.isSuccess) {
      emit(
        state.copyWith(status: AddChoreStatus.success, message: 'Chore $verb.'),
      );
      return;
    }
    emit(
      state.copyWith(
        status: AddChoreStatus.failure,
        message:
            result.failureOrNull?.message ??
            'Something went wrong. Please try again.',
      ),
    );
  }
}
