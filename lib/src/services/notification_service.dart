import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/local_notification_service.dart';

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
      final response = await ApiService().get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final newNotifications = data
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        if (checkForNew && _notifications.isNotEmpty) {
          _checkForNewAndNotify(newNotifications);
        }

        _notifications = newNotifications;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  void _checkForNewAndNotify(List<NotificationModel> fetchedNotifications) {
    if (_notifications.isEmpty) return;

    final existingIds = _notifications.map((n) => n.id).toSet();

    // Identify strictly new items (not just unread, but items we haven't seen before)
    final newItems = fetchedNotifications
        .where((n) => !existingIds.contains(n.id))
        .toList();

    for (var item in newItems) {
      if (item.isNew || item.type == NotificationType.urgent) {
        _localNotificationService.showNotification(
          id: item.hashCode,
          title: item.title,
          body: item.description,
        );
      } else {
        // Optional: Notify for all new items or just specific types
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

    // 2. API Calls (Sync)
    // ideal: add a bulk update endpoint. For now, loop.
    for (final id in unreadIds) {
      try {
        await ApiService().patch('/notifications/$id/read');
      } catch (e) {
        debugPrint('Error marking notification $id as read: $e');
      }
    }
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
    notifyListeners();
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
