import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
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

      // Extract activePlans
      final List<Map<String, dynamic>> activePlans =
          user?['activePlans'] != null
          ? List<Map<String, dynamic>>.from(user!['activePlans'])
          : [];

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

      if (recentTransactions.isNotEmpty) {
        // Calculate Pending (Only strictly Pending)
        pendingAmount = recentTransactions
            .where((t) => t['status'] == 'Pending')
            .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
      }

      double messFee = 3500.0;
      DateTime? planStartDate;
      DateTime? planEndDate;
      try {
        final planResponse = await api.get('/plans');
        if (planResponse.statusCode == 200 && planResponse.data != null) {
          messFee = (planResponse.data['price'] ?? 3500).toDouble();
          if (planResponse.data['startDate'] != null) {
            planStartDate = DateTime.parse(
              planResponse.data['startDate'],
            ).toLocal();
          }
          if (planResponse.data['endDate'] != null) {
            planEndDate = DateTime.parse(
              planResponse.data['endDate'],
            ).toLocal();
          }
          print(
            '[DashboardBloc] Plan Loaded: ID=${planResponse.data['_id']}, Fee=$messFee, Start=$planStartDate, End=$planEndDate',
          );
        } else {
          print(
            '[DashboardBloc] Plan Response error or empty: ${planResponse.statusCode}, Data: ${planResponse.data}',
          );
        }
      } catch (e) {
        print('[DashboardBloc] Error fetching plan: $e');
      }

      // Adjust balance to include 'Completed' transactions which are legacy/unsynced
      // In the new "Balance = Debt" model, we generally expect balance to be correct from backend.
      // But if we have local 'Completed' transactions not yet reflected, we might subtract them from Debt?
      // For safety, let's rely on Backend Balance as authoritative for Debt for now,
      // as adding "Completed" amounts (which are usually Paid) to Debt would be wrong.
      final adjustedBalance = balance;

      // Check if total dues are cleared
      // New Model: Balance is Outstanding Debt. If <= 0, no dues.

      // Dynamic Fine Calculation: ₹5 per day past the 8th day
      double fineAmount = 0.0;
      if (planStartDate != null) {
        final eighthDay = planStartDate.add(const Duration(days: 7));
        final now = DateTime.now();

        if (now.isAfter(eighthDay)) {
          // Calculate difference in days (start of day to start of day for consistency)
          final today = DateTime(now.year, now.month, now.day);
          final due = DateTime(eighthDay.year, eighthDay.month, eighthDay.day);
          final diffDays = today.difference(due).inDays;

          if (diffDays > 0) {
            fineAmount = diffDays * 5.0;
          }
        }
      } else {
        // Fallback to backend value if no plan dates found
        fineAmount = (user?['fineAmount'] ?? 0).toDouble();
      }

      // If Debt is cleared (Balance <= 0), no fine should be shown/applied
      if (adjustedBalance <= 0) {
        fineAmount = 0.0;
      }
      DateTime? paymentDueDate;
      if (planStartDate != null) {
        paymentDueDate = planStartDate.add(const Duration(days: 7));
      } else if (user?['paymentDueDate'] != null) {
        paymentDueDate = DateTime.parse(user!['paymentDueDate']).toLocal();
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
          fineAmount: fineAmount,
          paymentDueDate: paymentDueDate,
          messFee: messFee,
          planStartDate: planStartDate,
          planEndDate: planEndDate,
          activePlans: activePlans,
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
      final allNotifications = List<Map<String, dynamic>>.from(response.data);

      // Handle Device Only Notifications (System Reminders)
      final deviceOnlyNotifications = allNotifications
          .where((n) => n['type'] == 'device_only' && !n['isRead'])
          .toList();

      if (deviceOnlyNotifications.isNotEmpty) {
        for (var notif in deviceOnlyNotifications) {
          _notificationService.showNotification(
            id: DateTime.now().millisecond,
            title: notif['title'] ?? 'Reminder',
            body: notif['description'] ?? 'Check your payment status.',
          );
          // Mark as read immediately to prevent re-triggering
          try {
            await api.patch('/notifications/${notif['_id']}/read');
          } catch (e) {
            print('Error marking device notification read: $e');
          }
        }
      }

      // Filter visible notifications for App UI
      final visibleNotifications = allNotifications
          .where((n) => n['type'] != 'device_only')
          .toList();
      final unreadCount = visibleNotifications
          .where((n) => !n['isRead'])
          .length;

      // Check for new visible notifications to trigger local alert for them too
      if (unreadCount > currentState.unreadNotifications) {
        final newNotif = visibleNotifications.firstWhere(
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
