import 'package:equatable/equatable.dart';

import 'package:changa_app/core/constants/app_constants.dart';

enum ChoreDifficulty { easy, medium, hard }

enum ChoreStatus { pending, done }

extension ChoreDifficultyX on ChoreDifficulty {
  /// Credits earned for finishing a chore of this difficulty.
  int get credits => switch (this) {
    ChoreDifficulty.easy => AppConstants.creditsEasy,
    ChoreDifficulty.medium => AppConstants.creditsMedium,
    ChoreDifficulty.hard => AppConstants.creditsHard,
  };

  String get label => switch (this) {
    ChoreDifficulty.easy => 'Easy',
    ChoreDifficulty.medium => 'Medium',
    ChoreDifficulty.hard => 'Hard',
  };
}

class Chore extends Equatable {
  const Chore({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.assignedToUid,
    required this.dueDate,
    required this.status,
    required this.createdByUid,
    required this.createdAt,
    this.seriesId,
    this.description,
    this.completedAt,
    this.creditsAwarded,
  });

  final String id;
  final String? seriesId;
  final String title;
  final String? description;
  final ChoreDifficulty difficulty;
  final String assignedToUid;
  final DateTime dueDate;
  final ChoreStatus status;
  final DateTime? completedAt;
  final int? creditsAwarded;
  final String createdByUid;
  final DateTime createdAt;

  /// Derived from the series id so the two can never disagree.
  bool get isRecurring => seriesId != null;

  bool get isDone => status == ChoreStatus.done;

  Chore copyWith({
    String? title,
    String? description,
    ChoreDifficulty? difficulty,
    String? assignedToUid,
    DateTime? dueDate,
    ChoreStatus? status,
    DateTime? completedAt,
    int? creditsAwarded,
  }) {
    return Chore(
      id: id,
      seriesId: seriesId,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      creditsAwarded: creditsAwarded ?? this.creditsAwarded,
      createdByUid: createdByUid,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    seriesId,
    title,
    description,
    difficulty,
    assignedToUid,
    dueDate,
    status,
    completedAt,
    creditsAwarded,
    createdByUid,
    createdAt,
  ];
}
