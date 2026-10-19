// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: States for JoinHouseholdCubit

part of 'join_household_cubit.dart';

abstract class JoinHouseholdState extends Equatable {
  const JoinHouseholdState();

  @override
  List<Object?> get props => [];
}

class JoinHouseholdStateInitial extends JoinHouseholdState {}
