// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: States for HouseholdCubit

part of 'household_cubit.dart';

abstract class HouseholdState extends Equatable {
  const HouseholdState();

  @override
  List<Object?> get props => [];
}

class HouseholdStateInitial extends HouseholdState {}
