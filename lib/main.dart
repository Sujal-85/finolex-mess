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

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent, // For Edge-to-Edge
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
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
      channelId: 'breakfast_channel',
    );

    await notificationService.scheduleDailyNotification(
      id: 2,
      title: 'Lunch Time!',
      body: 'Lunch is being served. Check out today\'s menu.',
      hour: 11,
      minute: 0,
      channelId: 'lunch_channel',
    );

    await notificationService.scheduleDailyNotification(
      id: 3,
      title: 'Dinner Time!',
      body: 'Dinner is ready. Don\'t miss it!',
      hour: 19,
      minute: 30,
      channelId: 'dinner_channel',
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
  // REMOVED: Local Pending Payment Calculation.
  // Now handled by Backend Scheduler which sends urgent notifications.
  return;
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
