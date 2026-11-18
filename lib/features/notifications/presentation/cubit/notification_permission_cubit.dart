import 'package:flutter_bloc/flutter_bloc.dart';

enum NotificationPermissionStatus {
  initial,
  requesting,
  granted,
  denied,
  failure,
}

class NotificationPermissionCubit extends Cubit<NotificationPermissionStatus> {
  NotificationPermissionCubit(this._requestPermission)
    : super(NotificationPermissionStatus.initial);

  final Future<bool?> Function() _requestPermission;

  Future<void> request() async {
    if (isClosed || state == NotificationPermissionStatus.requesting) {
      return;
    }

    emit(NotificationPermissionStatus.requesting);

    try {
      final granted = await _requestPermission();

      if (isClosed) return;

      emit(
        granted == true
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied,
      );
    } catch (_) {
      if (!isClosed) {
        emit(NotificationPermissionStatus.failure);
      }
    }
  }
}
