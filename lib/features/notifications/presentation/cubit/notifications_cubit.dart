// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: Global NotificationsCubit managing in-app alerts and badge count

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(NotificationsStateInitial());
}
