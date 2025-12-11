import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  factory LocalNotificationService() {
    return _instance;
  }

  LocalNotificationService._internal();

  Future<void> init() async {
    tz.initializeTimeZones();
    // Fix LateInitializationError by setting a default local location
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      debugPrint('Error setting local location: $e');
      // Fallback if Hyderabad/Kolkata not found (unlikely with latest data)
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.DarwinInitializationSettings initializationSettingsIOS =
        fln.DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (fln.NotificationResponse response) async {
            // Handle notification tap
          },
    );

    // Request permissions for Android 13+
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
        fln.AndroidNotificationDetails(
          'finolex_canteen_channel',
          'Finolex Canteen Notifications',
          channelDescription: 'Notifications for Finolex Canteen App',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          showWhen: true,
        );

    const fln.NotificationDetails platformChannelSpecifics =
        fln.NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: fln.DarwinNotificationDetails(),
        );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'finolex_canteen_daily_channel',
            'Daily Meal Reminders',
            channelDescription:
                'Daily reminders for breakfast, lunch, and dinner',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            fln.UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: fln.DateTimeComponents.time,
      );
    } catch (e) {
      // Catch SecurityException for missing exact alarm permission or other scheduling errors
      // This prevents the app from crashing on startup
      debugPrint('Error scheduling notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
