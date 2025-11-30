import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  NotificationType _selectedFilter = NotificationType.general;

  List<NotificationModel> get notifications => _notifications;
  NotificationType get selectedFilter => _selectedFilter;

  NotificationService() {
    _loadSampleNotifications();
  }

  void _loadSampleNotifications() {
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'Menu Update',
        description: 'Today\'s lunch menu has been updated with new items.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: NotificationType.mess,
        isUnread: true,
        isNew: true,
      ),
      NotificationModel(
        id: '2',
        title: 'Payment Successful',
        description:
            'Your monthly mess bill payment of ₹2500 has been processed.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.payment,
        isUnread: true,
        isNew: false,
      ),
      NotificationModel(
        id: '3',
        title: 'New Announcement',
        description:
            'FAMT College Fest schedule released. Check details inside.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.news,
        isUnread: false,
        isNew: false,
      ),
      NotificationModel(
        id: '4',
        title: 'Urgent Notice',
        description: 'Mess will remain closed tomorrow due to maintenance.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: NotificationType.urgent,
        isUnread: true,
        isNew: true,
      ),
      NotificationModel(
        id: '5',
        title: 'Weekly Special',
        description: 'Try our new South Indian special thali this weekend.',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        type: NotificationType.mess,
        isUnread: false,
        isNew: false,
      ),
      NotificationModel(
        id: '6',
        title: 'Refund Processed',
        description: 'Your refund of ₹500 has been credited to your account.',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        type: NotificationType.payment,
        isUnread: false,
        isNew: false,
      ),
      NotificationModel(
        id: '7',
        title: 'Holiday Notice',
        description: 'Mess will be closed on 15th August for Independence Day.',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        type: NotificationType.urgent,
        isUnread: false,
        isNew: false,
      ),
    ];
    notifyListeners();
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
