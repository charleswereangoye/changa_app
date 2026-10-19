// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: States for NotificationsCubit

part of 'notifications_cubit.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsStateInitial extends NotificationsState {}
