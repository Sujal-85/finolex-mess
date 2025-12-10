import 'package:flutter/material.dart';
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

import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // Ensure this file exists, otherwise just default if checking platform

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

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

Future<void> _initNotifications() async {
  try {
    final notificationService = LocalNotificationService();
    await notificationService.init();

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

    // Schedule Daily Meal Reminders
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
        await notificationService.init();

        // Fetch notifications
        final response = await ApiService().get('/notifications');
        if (response.statusCode == 200) {
          // We need to check if there are any *new* ones.
          // Since we can't easily access the previous state in background without
          // shared prefs (which is async), we'll do a simple check.
          // For now, let's just show a generic "Check for updates" or
          // try to find the latest unsread.

          // Refined Logic:
          // Parse list, find any 'isUnread' or 'isNew'.
          // If 'isNew' is true, show it.

          final List<dynamic> data = response.data;
          // Filter for urgent/new
          final newItems = data
              .where(
                (item) => item['type'] == 'urgent' || item['isNew'] == true,
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
      }
    } catch (e) {
      debugPrint('Background fetch error: $e');
    }
    return Future.value(true);
  });
}

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
