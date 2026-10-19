// Owner: E - Person E (Chores, Harmony Score, Preferences)
// Description: States for MissedChoreCubit

part of 'missed_chore_cubit.dart';

abstract class MissedChoreState extends Equatable {
  const MissedChoreState();

  @override
  List<Object?> get props => [];
}

class MissedChoreStateInitial extends MissedChoreState {}
