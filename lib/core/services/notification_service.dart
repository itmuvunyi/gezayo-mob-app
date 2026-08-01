import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String targetRole; // 'customer', 'rider', or 'all'

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.targetRole = 'all',
  });
}

class NotificationState {
  final List<AppNotification> notifications;
  final bool hasUnread;

  const NotificationState({
    this.notifications = const [],
    this.hasUnread = true,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? hasUnread,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      hasUnread: hasUnread ?? this.hasUnread,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier()
      : super(NotificationState(
          notifications: [
            AppNotification(
              id: 'notif-1',
              title: 'Welcome to GezaYo!',
              body:
                  'Your account is ready. Request or deliver packages seamlessly across Rwanda.',
              timestamp: DateTime.parse('2026-07-31T12:00:00Z'),
              isRead: false,
            ),
            AppNotification(
              id: 'notif-2',
              title: 'New Delivery Available',
              body: 'A new package request was posted near your location.',
              timestamp: DateTime.parse('2026-07-31T14:30:00Z'),
              isRead: false,
            ),
          ],
          hasUnread: true,
        ));

  void notifyNewDelivery({required String packageType, required String pickupAddress}) {
    final notif = AppNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: '🚨 New Delivery Request ($packageType)',
      body: 'Pickup at $pickupAddress. Tap to accept this job!',
      timestamp: DateTime.now(),
      isRead: false,
      targetRole: 'rider',
    );
    state = state.copyWith(
      notifications: [notif, ...state.notifications],
      hasUnread: true,
    );
    debugPrint('PUSH NOTIFICATION: ${notif.title} - ${notif.body}');
  }

  void notifyStatusUpdate({required String status, required String deliveryId}) {
    final notif = AppNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: '📦 Delivery Update',
      body: 'Order #$deliveryId status changed to ${status.toUpperCase()}.',
      timestamp: DateTime.now(),
      isRead: false,
      targetRole: 'customer',
    );
    state = state.copyWith(
      notifications: [notif, ...state.notifications],
      hasUnread: true,
    );
    debugPrint('PUSH NOTIFICATION: ${notif.title} - ${notif.body}');
  }

  void markAllAsRead() {
    state = state.copyWith(hasUnread: false);
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

