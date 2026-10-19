// Owner: E - Person E (Chores, Harmony Score, Preferences)
// Description: States for PreferencesCubit

part of 'preferences_cubit.dart';

abstract class PreferencesState extends Equatable {
  const PreferencesState();

  @override
  List<Object?> get props => [];
}

class PreferencesStateInitial extends PreferencesState {}
