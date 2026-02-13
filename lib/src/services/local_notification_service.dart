import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  // ================= INIT =================
  Future<void> init({bool requestPermission = true}) async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidInit = fln.AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosInit = fln.DarwinInitializationSettings();

    const initSettings = fln.InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    await _createNotificationChannels();
    if (requestPermission) {
      await requestPermissions();
    }
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await Permission.notification.request();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
  }) async {
    final androidDetails = fln.AndroidNotificationDetails(
      channelId ?? 'finolex_canteen_channel',
      'General Notifications',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );
    final notificationDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: const fln.DarwinNotificationDetails(),
    );
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  // ================= CHANNELS =================
  Future<void> _createNotificationChannels() async {
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) return;

    await android.createNotificationChannel(
      const fln.AndroidNotificationChannel(
        'finolex_canteen_channel',
        'General Notifications',
        importance: fln.Importance.max,
      ),
    );

    await android.createNotificationChannel(
      const fln.AndroidNotificationChannel(
        'breakfast_channel',
        'Breakfast Notifications',
        importance: fln.Importance.high,
      ),
    );

    await android.createNotificationChannel(
      const fln.AndroidNotificationChannel(
        'lunch_channel',
        'Lunch Notifications',
        importance: fln.Importance.high,
      ),
    );

    await android.createNotificationChannel(
      const fln.AndroidNotificationChannel(
        'dinner_channel',
        'Dinner Notifications',
        importance: fln.Importance.high,
      ),
    );
  }

  // ================= SCHEDULE ALL =================
  Future<void> scheduleAllMealReminders({
    String? breakfastMenu,
    String? lunchMenu,
    String? dinnerMenu,
  }) async {
    // 🥣 Breakfast – 8:00 AM
    await scheduleDailyNotification(
      id: 101,
      title: 'Good Morning ☀️',
      body: breakfastMenu != null
          ? 'Breakfast is ready! Today: $breakfastMenu'
          : 'Breakfast is ready!',
      hour: 8,
      minute: 0,
      channelId: 'breakfast_channel',
    );

    // 🍛 Lunch – 12:50 PM (TESTING - Changed to 00:30 by user request implemented here if needed, keeping user's 0:50 for now or passed values? User had 0:50 in their snippet, previously 0:30.)
    // Verify user's snippet had 0:50.
    await scheduleDailyNotification(
      id: 102,
      title: 'Lunch Time 🍛',
      body: lunchMenu != null
          ? 'Lunch is served! Today: $lunchMenu'
          : 'Lunch is served! Don’t miss it.',
      hour: 22,
      minute: 55,
      channelId: 'lunch_channel',
    );

    // 🌙 Dinner – 7:30 PM
    await scheduleDailyNotification(
      id: 103,
      title: 'Dinner Time 🌙',
      body: dinnerMenu != null
          ? 'Dinner is ready! Today: $dinnerMenu'
          : 'Dinner is ready!',
      hour: 19,
      minute: 30,
      channelId: 'dinner_channel',
    );

    // 🕛 Midnight – 00:01 AM (New Day)
    await scheduleDailyNotification(
      id: 100,
      title: 'New Day Started ☀️',
      body: 'Attendance for today is now open. Check the menu!',
      hour: 0,
      minute: 1,
      channelId: 'finolex_canteen_channel',
    );

    debugPrint('✅ All meal notifications scheduled');
  }

  // ================= SCHEDULE DAILY =================
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
  }) async {
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    debugPrint('⏰ Scheduling [$id] at $scheduledDate');

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          channelId,
          'Meal Reminder',
          importance: fln.Importance.high,
          priority: fln.Priority.high,
        ),
        iOS: const fln.DarwinNotificationDetails(),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          fln.UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: fln.DateTimeComponents.time,
    );
  }

  // ================= TIME CALC =================
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

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

  // ================= CANCEL =================
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
