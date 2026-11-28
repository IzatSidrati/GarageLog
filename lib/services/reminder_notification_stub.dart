import 'reminder_notification_types.dart';

class ReminderNotificationService {
  const ReminderNotificationService._();

  static Future<bool> initAndRequestPermission() async => false;

  static Future<void> syncReminders({
    required bool enabled,
    required List<ScheduledReminderItem> reminders,
  }) async {}

  static Future<NotificationDispatchResult> sendTestNotification({
    required String title,
    required String body,
  }) async {
    return NotificationDispatchResult(
      nativeDelivered: false,
      title: title,
      body: body,
    );
  }
}
