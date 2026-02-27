import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static late FlutterLocalNotificationsPlugin _plugin;

  static Future<void> initialize(FlutterLocalNotificationsPlugin plugin) async {
    _plugin = plugin;
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    // Request Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleInsuranceReminder({
    required int id,
    required String vehicleName,
    required DateTime expiryDate,
  }) async {
    final remind = expiryDate.subtract(const Duration(days: 7));
    if (remind.isAfter(DateTime.now())) {
      await _plugin.zonedSchedule(
        id,
        'Insurance Expiry Reminder',
        '$vehicleName insurance expires on ${_fmt(expiryDate)}. Please renew!',
        tz.TZDateTime.from(remind, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'insurance_channel',
            'Insurance Reminders',
            channelDescription: 'Reminders for insurance renewal',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFFF39C12),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> scheduleServiceReminder({
    required int id,
    required String vehicleName,
    required DateTime serviceDate,
  }) async {
    final remind = serviceDate.subtract(const Duration(days: 3));
    if (remind.isAfter(DateTime.now())) {
      await _plugin.zonedSchedule(
        id,
        'Service Due',
        '$vehicleName is due for service on ${_fmt(serviceDate)}.',
        tz.TZDateTime.from(remind, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'service_channel',
            'Service Reminders',
            channelDescription: 'Reminders for vehicle service',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general_channel',
          'General',
          channelDescription: 'General notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
