import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);

    // Request Android permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'carguardian_channel',
      'CarGuardian Alerts',
      channelDescription: 'Vehicle maintenance and insurance alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details, payload: payload);
  }

  // Schedule insurance expiry reminder
  Future<void> scheduleInsuranceReminder({
    required String vehicleId,
    required String vehicleName,
    required DateTime expiryDate,
  }) async {
    final reminderDate = expiryDate.subtract(const Duration(days: 30));
    if (reminderDate.isBefore(DateTime.now())) return;

    await _scheduleNotification(
      id: vehicleId.hashCode,
      title: '🚗 Insurance Expiry Reminder',
      body: '$vehicleName insurance expires on ${_formatDate(expiryDate)}',
      scheduledDate: reminderDate,
      payload: 'insurance:$vehicleId',
    );
  }

  // Schedule service reminder
  Future<void> scheduleServiceReminder({
    required String vehicleId,
    required String vehicleName,
    required DateTime nextServiceDate,
  }) async {
    final reminderDate = nextServiceDate.subtract(const Duration(days: 7));
    if (reminderDate.isBefore(DateTime.now())) return;

    await _scheduleNotification(
      id: vehicleId.hashCode + 1000,
      title: '🔧 Service Due Reminder',
      body: '$vehicleName service is due on ${_formatDate(nextServiceDate)}',
      scheduledDate: reminderDate,
      payload: 'service:$vehicleId',
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'carguardian_scheduled',
      'CarGuardian Scheduled',
      channelDescription: 'Scheduled vehicle reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
