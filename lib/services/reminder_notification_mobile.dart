import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_notification_types.dart';

class ReminderNotificationService {
  const ReminderNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'garagelog_reminders_v1';
  static const _channelName = 'GarageLog Maintenance Reminders';
  static const _channelDesc =
      'Offline alerts for STNK tax due dates and scheduled vehicle maintenance.';

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  static Future<bool> initAndRequestPermission() async {
    if (!_isMobile) return false;
    try {
      if (!_initialized) {
        tz_data.initializeTimeZones();
        const androidInit =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const darwinInit = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = InitializationSettings(
          android: androidInit,
          iOS: darwinInit,
        );
        await _plugin.initialize(initSettings);
        _initialized = true;
      }

      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? true;
      }

      if (Platform.isIOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static Future<void> syncReminders({
    required bool enabled,
    required List<ScheduledReminderItem> reminders,
  }) async {
    if (!_isMobile) return;
    try {
      await initAndRequestPermission();
      await _plugin.cancelAll();
      if (!enabled) return;

      final now = DateTime.now();
      for (final item in reminders) {
        if (!item.scheduledAt.isAfter(now)) continue;
        final tzDate = tz.TZDateTime.from(item.scheduledAt.toUtc(), tz.UTC);
        await _plugin.zonedSchedule(
          item.id,
          item.title,
          item.body,
          tzDate,
          _details(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // Safe fallback so offline scheduling never crashes UI flow.
    }
  }

  static Future<NotificationDispatchResult> sendTestNotification({
    required String title,
    required String body,
  }) async {
    if (!_isMobile) {
      return NotificationDispatchResult(
        nativeDelivered: false,
        title: title,
        body: body,
      );
    }

    try {
      await initAndRequestPermission();
      await _plugin.show(
        999001,
        title,
        body,
        _details(),
      );
      return NotificationDispatchResult(
        nativeDelivered: true,
        title: title,
        body: body,
      );
    } catch (_) {
      return NotificationDispatchResult(
        nativeDelivered: false,
        title: title,
        body: body,
      );
    }
  }
}
