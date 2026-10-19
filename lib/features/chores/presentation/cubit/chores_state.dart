// Owner: E - Person E (Chores, Harmony Score, Preferences)
// Description: States for ChoresCubit

part of 'chores_cubit.dart';

abstract class ChoresState extends Equatable {
  const ChoresState();

  @override
  List<Object?> get props => [];
}

class ChoresStateInitial extends ChoresState {}
