import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );
  }

  Future<void> scheduleJourneyAlert({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? customSoundPath,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'journey_alerts',
      'Journey Alerts',
      channelDescription: 'Notifications for bus departure and arrival',
      importance: Importance.max,
      priority: Priority.high,
      sound: customSoundPath != null 
          ? UriAndroidNotificationSound(customSoundPath) 
          : const RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
