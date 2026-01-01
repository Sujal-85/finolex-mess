import 'package:flutter/material.dart';
import 'src/services/firebase_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'src/blocs/dashboard_bloc.dart';
import 'src/utils/app_router.dart';
import 'src/theme/colors.dart';
import 'src/services/notification_service.dart';
import 'src/services/settings_service.dart';
import 'src/services/receipt_service.dart';
import 'src/services/local_notification_service.dart';
import 'src/services/api_service.dart';
import 'package:workmanager/workmanager.dart';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
    webProvider: ReCaptchaV3Provider('6Lcj-R8qAAAAAB7P6V5V0V3V'),
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
      statusBarBrightness: Brightness.light, // For iOS (dark icons)
    ),
  );

  // Initialize notifications in background to prevent startup hang
  _initNotifications();

  runApp(const MyApp());
}

// Removed misplaced import

Future<void> _initNotifications() async {
  try {
    await FirebaseApi().initNotifications();
    final notificationService = LocalNotificationService();
    await notificationService.init(requestPermission: false);

    // Initialize WorkManager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for testing
    );

    // Register Periodic Task
    await Workmanager().registerPeriodicTask(
      "1",
      "fetchNotificationsTask",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );

    // Schedule Daily Meal Reminders (Moved back to explicit scheduling for reliability as requested)
    await notificationService.scheduleDailyNotification(
      id: 1,
      title: 'Good Morning!',
      body: 'Breakfast is ready. Start your day with a healthy meal!',
      hour: 8,
      minute: 0,
    );

    await notificationService.scheduleDailyNotification(
      id: 2,
      title: 'Lunch Time!',
      body: 'Lunch is being served. Check out today\'s menu.',
      hour: 12,
      minute: 30,
    );

    await notificationService.scheduleDailyNotification(
      id: 3,
      title: 'Dinner Time!',
      body: 'Dinner is ready. Don\'t miss it!',
      hour: 19,
      minute: 30,
    );
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'fetchNotificationsTask') {
        // Initialize dependencies for background isolate
        final notificationService = LocalNotificationService();
        await notificationService.init(requestPermission: false);

        final prefs = await SharedPreferences.getInstance();
        final userStr = prefs.getString('auth_user');

        if (userStr != null) {
          final user = jsonDecode(userStr);
          final studentId = user['id'] ?? user['_id'];

          if (studentId != null) {
            // 1. Fetch Notifications (Existing Logic)
            try {
              final response = await ApiService().get('/notifications');
              if (response.statusCode == 200) {
                final List<dynamic> data = response.data;
                final newItems = data
                    .where(
                      (item) =>
                          item['type'] == 'urgent' || item['isNew'] == true,
                    )
                    .toList();

                if (newItems.isNotEmpty) {
                  final latest = newItems.first;
                  await notificationService.showNotification(
                    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    title: latest['title'] ?? 'New Notification',
                    body:
                        latest['description'] ??
                        'You have a new message from the canteen.',
                  );
                }
              }
            } catch (e) {
              debugPrint('Error fetching notifications in background: $e');
            }

            // 2. Pending Payment Reminder Logic
            await _checkAndSendPendingReminder(
              studentId,
              prefs,
              notificationService,
            );

            // 3. Meal Reminder Logic (Disabled: Using exact scheduling instead)
            // await _checkAndSendMealReminder(prefs, notificationService);
          }
        }
      }
    } catch (e) {
      debugPrint('Background task error: $e');
    }
    return Future.value(true);
  });
}

Future<void> _checkAndSendPendingReminder(
  String studentId,
  SharedPreferences prefs,
  LocalNotificationService notificationService,
) async {
  try {
    // Check constraints: Max 2 times per day
    final String todayDate = DateTime.now().toIso8601String().split('T')[0];
    final String lastDate = prefs.getString('last_pending_reminder_date') ?? '';
    int dailyCount = prefs.getInt('daily_pending_reminder_count') ?? 0;

    if (lastDate != todayDate) {
      // Reset for new day
      dailyCount = 0;
      await prefs.setString('last_pending_reminder_date', todayDate);
      await prefs.setInt('daily_pending_reminder_count', 0);
    }

    if (dailyCount >= 2) {
      return;
    }

    // Check Balance/Pending Status
    final response = await ApiService().get('/students/$studentId');
    if (response.statusCode == 200) {
      final student = response.data;

      // 1. Strict Payment Status Check
      final String paymentStatus = (student['paymentStatus'] ?? '')
          .toString()
          .toLowerCase();
      if (paymentStatus == 'paid') {
        return; // Stop immediately if status is explicitly paid
      }

      final double balance = (student['balance'] ?? 0).toDouble();
      final double monthlyFee = (student['monthlyFee'] ?? 3500).toDouble();
      final double fineAmount = (student['fineAmount'] ?? 0).toDouble();
      double totalFee = monthlyFee + fineAmount;

      if (balance >= monthlyFee) {
        totalFee = monthlyFee;
      }

      final double remainingDues = totalFee > balance ? totalFee - balance : 0;

      // 2. Tolerance Check (ignore < ₹1) & Status Re-verification
      if (remainingDues > 1.0 && paymentStatus != 'paid') {
        final List<String> messages = [
          'Reminder: You have pending due of ₹$remainingDues. Please pay soon!',
          'Don\'t forget to clear your canteen dues of ₹$remainingDues.',
          'Pending Payment Alert: ₹$remainingDues remaining. Avoid late fees!',
        ];

        final random = Random();
        final String message = messages[random.nextInt(messages.length)];

        await notificationService.showNotification(
          id: 999,
          title: 'Pending Payment ⚠️',
          body: message,
        );

        await prefs.setInt('daily_pending_reminder_count', dailyCount + 1);
      }
    }
  } catch (e) {
    debugPrint('Error in pending reminder check: $e');
  }
}

// 3. Meal Reminder Logic (Disabled: Using exact scheduling instead)
// Future<void> _checkAndSendMealReminder(...) removed as it is now redundant.

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NotificationService()),
        ChangeNotifierProvider(create: (context) => SettingsService()),
        Provider(create: (context) => ReceiptService()),
      ],
      child: MultiBlocProvider(
        providers: [BlocProvider(create: (context) => DashboardBloc())],
        child: Consumer<SettingsService>(
          builder: (context, settingsService, child) {
            return MaterialApp.router(
              title: 'FAMT Mess App',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  brightness: Brightness.light,
                ),
                scaffoldBackgroundColor: AppColors.backgroundLight,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: AppColors.backgroundDark,
              ),
              themeMode: settingsService.themeMode,
              routerConfig: AppRouter.router,
            );
          },
        ),
      ),
    );
  }
}
