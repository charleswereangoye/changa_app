// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: States for ManageHouseholdCubit

part of 'manage_household_cubit.dart';

abstract class ManageHouseholdState extends Equatable {
  const ManageHouseholdState();

  @override
  List<Object?> get props => [];
}

class ManageHouseholdStateInitial extends ManageHouseholdState {}
