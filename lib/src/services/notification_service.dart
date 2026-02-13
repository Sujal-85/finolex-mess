import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/local_notification_service.dart';
import '../services/local_notification_storage.dart';

class NotificationService extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  NotificationType _selectedFilter = NotificationType.general;

  List<NotificationModel> get notifications => _notifications;
  NotificationType get selectedFilter => _selectedFilter;

  Timer? _pollingTimer;
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();

  NotificationService() {
    fetchNotifications();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll every 60 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      fetchNotifications(checkForNew: true);
    });
  }

  Future<void> fetchNotifications({bool checkForNew = false}) async {
    try {
      // Check for missed scheduled notifications (Simulated History)
      await _checkMissedMealNotifications();

      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('auth_user');
      String? userId;
      if (userStr != null) {
        final user = jsonDecode(userStr);
        userId = user['id'] ?? user['_id'];
      }

      final response = await ApiService().get(
        '/notifications',
        queryParameters: userId != null ? {'userId': userId} : null,
      );

      List<NotificationModel> apiNotifications = [];
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        apiNotifications = data
            .map((json) => NotificationModel.fromJson(json))
            .where((n) {
              final isProfileUpdate =
                  n.title.toLowerCase().contains('profile updated') ||
                  n.description.toLowerCase().contains('profile updated') ||
                  n.title.toLowerCase().contains('student updated') ||
                  n.description.toLowerCase().contains('student updated');
              return n.type != NotificationType.deviceOnly && !isProfileUpdate;
            })
            .toList();
      }

      // Merge with Local Notifications
      final localNotifications = await LocalNotificationStorage()
          .getLocalNotifications();

      // Combine and Sort
      final combined = [...apiNotifications, ...localNotifications]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first

      // Deduplicate by ID
      final uniqueNotifications = <String, NotificationModel>{};
      for (var n in combined) {
        uniqueNotifications[n.id] = n;
      }

      final finalAttributes = uniqueNotifications.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (checkForNew && _notifications.isNotEmpty) {
        await _checkForNewAndNotify(finalAttributes);
      }

      _notifications = finalAttributes;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      // Even if API fails, load local
      final localNotifications = await LocalNotificationStorage()
          .getLocalNotifications();
      _notifications = localNotifications
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    }
  }

  Future<void> _checkMissedMealNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('last_meal_check_time') ?? 0;
    final now = DateTime.now();

    // Only run if we haven't checked in the last hour to avoid duplicates on hot restart
    if (now.millisecondsSinceEpoch - lastCheck < 3600000) return;

    final today8am = DateTime(now.year, now.month, now.day, 8, 0);
    final today1250pm = DateTime(now.year, now.month, now.day, 12, 50);
    final today730pm = DateTime(now.year, now.month, now.day, 19, 30);

    await prefs.setInt('last_meal_check_time', now.millisecondsSinceEpoch);

    final storage = LocalNotificationStorage();

    // Helper to add if time passed
    Future<void> addIfPassed(DateTime time, String title, String body) async {
      if (now.isAfter(time)) {
        // Check if we already have this notification for today to prevent dups
        // This is a simple heuristic
        final list = await storage.getLocalNotifications();
        final alreadyExists = list.any((n) {
          final isSameTitle = n.title == title;
          final isToday =
              n.timestamp.year == now.year &&
              n.timestamp.month == now.month &&
              n.timestamp.day == now.day;
          return isSameTitle && isToday;
        });

        if (!alreadyExists) {
          await storage.saveNotification(
            title: title,
            body: body,
            type: NotificationType.mess,
          );
        }
      }
    }

    await addIfPassed(today8am, 'Good Morning ☀️', 'Breakfast is ready!');
    await addIfPassed(
      today1250pm,
      'Lunch Time 🍛',
      'Lunch is served! Don’t miss it.',
    );
    await addIfPassed(today730pm, 'Dinner Time 🌙', 'Dinner is ready!');
  }

  Future<void> _checkForNewAndNotify(
    List<NotificationModel> fetchedNotifications,
  ) async {
    if (_notifications.isEmpty) return;

    // 1. Check if Push Notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool('pushNotifications') ?? true;
    if (!pushEnabled) return;

    final existingIds = _notifications.map((n) => n.id).toSet();

    // Identify strictly new items
    final newItems = fetchedNotifications
        .where((n) => !existingIds.contains(n.id))
        .toList();

    // 2. Fetch User Balance for Smart Filtering
    // We do this only if there are new items to avoid unnecessary API calls
    double? userBalance;
    if (newItems.isNotEmpty) {
      try {
        final userStr = prefs.getString('auth_user');
        if (userStr != null) {
          final user = jsonDecode(userStr);
          final userId = user['id'] ?? user['_id'];
          // Fetch fresh user data to get accurate balance
          final response = await ApiService().get('/users/$userId');
          if (response.statusCode == 200) {
            userBalance = (response.data['balance'] ?? 0).toDouble();
            // Also update local cache while we are at it
            await prefs.setString('auth_user', jsonEncode(response.data));
          }
        }
      } catch (e) {
        debugPrint('Error fetching user balance for notification filter: $e');
      }
    }

    final double messFee = 3500.0; // Standard fee threshold

    for (var item in newItems) {
      // 3. Smart Filter: Suppress payment alerts if balance is sufficient
      if (userBalance != null &&
          (item.title.toLowerCase().contains('pending') ||
              item.title.toLowerCase().contains('fine') ||
              item.description.toLowerCase().contains('payment'))) {
        if (userBalance >= messFee) {
          debugPrint(
            'Suppressing payment notification: User has sufficient balance ($userBalance)',
          );
          continue; // Skip showing this notification
        }
      }

      // Prevent re-notifying for old items (e.g. history loaded on app launch)
      if (DateTime.now().difference(item.timestamp).inMinutes.abs() > 10) {
        continue;
      }

      if (item.isNew || item.type == NotificationType.urgent) {
        _localNotificationService.showNotification(
          id: item.hashCode,
          title: item.title,
          body: item.description,
        );
      } else {
        _localNotificationService.showNotification(
          id: item.hashCode,
          title: item.title,
          body: item.description,
        );
      }
    }
  }

  void selectFilter(NotificationType filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  List<NotificationModel> getFilteredNotifications() {
    if (_selectedFilter == NotificationType.general) {
      return _notifications;
    }
    return _notifications
        .where((notification) => notification.type == _selectedFilter)
        .toList();
  }

  Future<void> markAsRead(String id) async {
    // 1. Optimistic Update
    final index = _notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index != -1) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        description: _notifications[index].description,
        timestamp: _notifications[index].timestamp,
        type: _notifications[index].type,
        isUnread: false,
        isNew: _notifications[index].isNew,
      );
      notifyListeners();

      // 2. API Call
      try {
        await ApiService().patch('/notifications/$id/read');
      } catch (e) {
        debugPrint('Error marking notification as read: $e');
        // Optional: Revert optimistic update if needed, but not critical for read status
      }
    }
  }

  Future<void> markAllAsRead() async {
    // 1. Optimistic Update
    final unreadIds = _notifications
        .where((n) => n.isUnread)
        .map((n) => n.id)
        .toList();

    _notifications = _notifications.map((notification) {
      return NotificationModel(
        id: notification.id,
        title: notification.title,
        description: notification.description,
        timestamp: notification.timestamp,
        type: notification.type,
        isUnread: false,
        isNew: notification.isNew,
      );
    }).toList();
    notifyListeners();

    // 2. API Calls (Parallel)
    debugPrint('Marking ${unreadIds.length} notifications as read...');

    // Execute all requests in parallel to prevent polling race conditions
    await Future.wait(
      unreadIds.map((id) async {
        try {
          await ApiService().patch('/notifications/$id/read');
        } catch (e) {
          debugPrint('Error marking notification $id as read: $e');
        }
      }),
    );
    debugPrint('All notifications marked as read successfully.');
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((notification) => notification.id == id);
    notifyListeners();
    // Also remove from local storage if present
    await LocalNotificationStorage().deleteNotification(id);
  }

  int getUnreadCount() {
    return _notifications.where((notification) => notification.isUnread).length;
  }

  List<NotificationModel> getGroupedNotifications() {
    // Sort by timestamp (newest first)
    final sortedNotifications = List<NotificationModel>.from(_notifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return sortedNotifications;
  }
}
