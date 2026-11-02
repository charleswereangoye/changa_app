import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';

enum NotificationsStatus { initial, loading, loaded, failure }

class NotificationsState extends Equatable {
  NotificationsState({
    this.status = NotificationsStatus.initial,
    List<AppNotification> unread = const [],
    List<AppNotification> pendingAlerts = const [],
    this.failure,
  }) : unread = List<AppNotification>.unmodifiable(unread),
       pendingAlerts = List<AppNotification>.unmodifiable(pendingAlerts);

  final NotificationsStatus status;

  /// The recipient's unread notifications, newest first.
  final List<AppNotification> unread;

  /// New notifications queued for an in-app alert.
  /// Dismissing an alert does not automatically mark it as read.
  final List<AppNotification> pendingAlerts;

  final Failure? failure;

  int get unreadCount => unread.length;

  AppNotification? get currentAlert =>
      pendingAlerts.isEmpty ? null : pendingAlerts.first;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? unread,
    List<AppNotification>? pendingAlerts,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      unread: unread ?? this.unread,
      pendingAlerts: pendingAlerts ?? this.pendingAlerts,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, unread, pendingAlerts, failure];
}
