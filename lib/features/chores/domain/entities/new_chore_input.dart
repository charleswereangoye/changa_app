import 'package:equatable/equatable.dart';

import 'package:changa/features/chores/domain/entities/chore.dart';

class NewChoreInput extends Equatable {
  const NewChoreInput({
    required this.householdId,
    required this.title,
    required this.difficulty,
    required this.assignedToUid,
    required this.dueDate,
    required this.createdByUid,
    this.description,
    this.rotate = false,
  });

  final String householdId;
  final String title;
  final String? description;
  final ChoreDifficulty difficulty;

  /// For a rotating chore this is who takes the first week.
  final String assignedToUid;
  final DateTime dueDate;
  final String createdByUid;

  /// The "Rotate between everyone" switch on the form.
  final bool rotate;

  @override
  List<Object?> get props => [
    householdId,
    title,
    description,
    difficulty,
    assignedToUid,
    dueDate,
    createdByUid,
    rotate,
  ];
}
