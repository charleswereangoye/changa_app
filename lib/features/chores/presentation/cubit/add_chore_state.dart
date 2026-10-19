// Owner: E - Person E (Chores, Harmony Score, Preferences)
// Description: States for AddChoreCubit

part of 'add_chore_cubit.dart';

abstract class AddChoreState extends Equatable {
  const AddChoreState();

  @override
  List<Object?> get props => [];
}

class AddChoreStateInitial extends AddChoreState {}
