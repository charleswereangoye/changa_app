// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: States for ActivityCubit

part of 'activity_cubit.dart';

abstract class ActivityState extends Equatable {
  const ActivityState();

  @override
  List<Object?> get props => [];
}

class ActivityStateInitial extends ActivityState {}
