import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationService extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  NotificationType _selectedFilter = NotificationType.general;

  List<NotificationModel> get notifications => _notifications;
  NotificationType get selectedFilter => _selectedFilter;

  NotificationService() {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await ApiService().get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _notifications = data
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching notifications: $e');
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

  void markAsRead(String id) {
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
    }
  }

  void markAllAsRead() {
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
