// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: States for CreateHouseholdCubit

part of 'create_household_cubit.dart';

abstract class CreateHouseholdState extends Equatable {
  const CreateHouseholdState();

  @override
  List<Object?> get props => [];
}

class CreateHouseholdStateInitial extends CreateHouseholdState {}
