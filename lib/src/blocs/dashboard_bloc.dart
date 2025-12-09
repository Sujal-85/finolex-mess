import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../services/local_notification_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final AuthService _authService = AuthService();

  Timer? _timer;
  final LocalNotificationService _notificationService =
      LocalNotificationService();

  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
    on<DashboardNotificationCheck>(_onNotificationCheck);

    // Start polling every 2 minutes
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      add(DashboardNotificationCheck());
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final api = ApiService();
      final response = await api.get('/announcements');
      final announcements = response.data as List;
      final latestAnnouncement = announcements.isNotEmpty
          ? announcements.first['title']
          : 'No new announcements';

      final user = await _authService.refreshUser();
      final studentName = user?['name'] ?? 'Student';
      final profileImage = user?['profileImage'];
      final balance = (user?['balance'] ?? 0).toDouble();

      final hostelDetails = user?['hostelDetails'] ?? {};
      final hostelBlock = hostelDetails['hostelName'] ?? 'Not Assigned';
      final roomNumber = hostelDetails['roomNo'] ?? 'N/A';

      // Fetch birthdays
      final birthdayResponse = await api.get('/students/birthdays/today');
      final birthdays = List<Map<String, dynamic>>.from(birthdayResponse.data);

      // Fetch transactions
      final paymentService = PaymentService();
      List<dynamic> recentTransactions = [];
      if (user?['id'] != null) {
        try {
          recentTransactions = await paymentService.fetchTransactionHistory(
            user!['id'],
          );
        } catch (e) {
          print('Error fetching transactions: $e');
        }
      }

      // Fetch menu for today
      final now = DateTime.now();
      final day = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][now.weekday - 1];
      final menuResponse = await api.get(
        '/menu',
        queryParameters: {'day': day},
      );
      final menuItems = List<Map<String, dynamic>>.from(menuResponse.data);

      // Helper to find item by mealType
      String findItem(String mealType) {
        final item = menuItems.firstWhere(
          (item) =>
              item['mealType'].toString().toLowerCase() ==
              mealType.toLowerCase(),
          orElse: () => {
            'name': '${mealType[0].toUpperCase()}${mealType.substring(1)} Menu',
          },
        );
        return item['name'];
      }

      final breakfastItem = findItem('breakfast');
      final lunchItem = findItem('lunch');
      final dinnerItem = findItem('dinner');

      // Determine next meal based on time
      final hour = now.hour;
      String nextMealName = breakfastItem;
      if (hour >= 9 && hour < 14) {
        nextMealName = lunchItem;
      } else if (hour >= 14 && hour < 21) {
        nextMealName = dinnerItem;
      } else if (hour >= 21) {
        nextMealName = dinnerItem;
      }

      // Fetch notifications count
      int unreadCount = 0;
      if (user?['id'] != null) {
        try {
          final notifResponse = await api.get(
            '/notifications?userId=${user!['id']}',
          );
          final notifications = notifResponse.data as List;
          unreadCount = notifications.where((n) => !n['isRead']).length;
        } catch (e) {
          print('Error fetching notifications: $e');
        }
      }

      double pendingAmount = 0.0;
      double completedUnsyncedAmount = 0.0;

      if (recentTransactions.isNotEmpty) {
        // Calculate Pending (Only strictly Pending)
        pendingAmount = recentTransactions
            .where((t) => t['status'] == 'Pending')
            .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());

        // Calculate Completed (Add to balance if not already synced which we assume here)
        completedUnsyncedAmount = recentTransactions
            .where((t) => t['status'] == 'Completed')
            .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
      }

      // Adjust balance to include 'Completed' transactions which are legacy/unsynced
      final adjustedBalance = balance + completedUnsyncedAmount;

      // Check if total dues are cleared
      // Assuming 3500 is the hardcoded total fee for now
      if (adjustedBalance + pendingAmount >= 3500) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        final currentMonthKey =
            'payment_done_notified_${now.month}_${now.year}';

        // Only show if not already shown this month
        if (!prefs.containsKey(currentMonthKey)) {
          _notificationService.showNotification(
            id: 999, // Unique ID for Payment Complete
            title: 'Mess Payment Done ✅',
            body: 'Great! You have completed your mess payment.',
          );
          await prefs.setBool(currentMonthKey, true);
        }
      }

      emit(
        DashboardLoaded(
          balance: adjustedBalance,
          nextMeal: nextMealName,
          breakfastItem: breakfastItem,
          lunchItem: lunchItem,
          dinnerItem: dinnerItem,
          unreadNotifications: unreadCount,
          latestAnnouncement: latestAnnouncement,
          studentName: studentName,
          profileImage: profileImage,
          hostelBlock: hostelBlock,
          roomNumber: roomNumber,
          birthdays: birthdays,
          recentTransactions: recentTransactions,
          pendingAmount: pendingAmount,
        ),
      );
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      // Reuse load logic for refresh
      add(DashboardLoadRequested());
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onNotificationCheck(
    DashboardNotificationCheck event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;
    final currentState = state as DashboardLoaded;

    try {
      final user = await _authService.getUser();
      if (user?['id'] == null) return;

      final api = ApiService();
      final response = await api.get('/notifications?userId=${user!['id']}');
      final notifications = List<Map<String, dynamic>>.from(response.data);
      final unreadCount = notifications.where((n) => !n['isRead']).length;

      // Check for new notifications to trigger local alert
      if (unreadCount > currentState.unreadNotifications) {
        final newNotif = notifications.firstWhere(
          (n) => !n['isRead'],
          orElse: () => {},
        );
        if (newNotif.isNotEmpty) {
          _notificationService.showNotification(
            id: DateTime.now().millisecond,
            title: newNotif['title'] ?? 'New Notification',
            body: newNotif['description'] ?? 'You have a new update.',
          );

          // If payment related, refresh critical data immediately
          if (newNotif['type'] == 'payment') {
            final updatedUser = await _authService.refreshUser();
            final newBalance = (updatedUser?['balance'] ?? 0).toDouble();

            final paymentService = PaymentService();
            final newTransactions = await paymentService
                .fetchTransactionHistory(user['id']);

            emit(
              currentState.copyWith(
                unreadNotifications: unreadCount,
                balance: newBalance,
                recentTransactions: newTransactions,
              ),
            );
            return;
          }
        }
      }

      emit(currentState.copyWith(unreadNotifications: unreadCount));
    } catch (e) {
      print('Error polling notifications: $e');
    }
  }
}
