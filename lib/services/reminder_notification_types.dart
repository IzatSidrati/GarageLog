class ScheduledReminderItem {
  const ScheduledReminderItem({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.vehicleName,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String vehicleName;
}

class NotificationDispatchResult {
  const NotificationDispatchResult({
    required this.nativeDelivered,
    required this.title,
    required this.body,
  });

  final bool nativeDelivered;
  final String title;
  final String body;
}
