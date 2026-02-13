import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

class LocalNotificationStorage {
  static const String _key = 'local_notifications_history';
  final Uuid _uuid = const Uuid();

  Future<void> saveNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentList = prefs.getStringList(_key) ?? [];

      final notification = NotificationModel(
        id: _uuid.v4(),
        title: title,
        description: body,
        timestamp: DateTime.now(),
        type: type,
        isUnread: true,
        isNew: true,
      );

      // Add to beginning
      currentList.insert(0, jsonEncode(notification.toJson()));

      // Keep only last 50
      if (currentList.length > 50) {
        currentList.removeRange(50, currentList.length);
      }

      await prefs.setStringList(_key, currentList);
    } catch (e) {
      print('Error saving local notification: $e');
    }
  }

  Future<List<NotificationModel>> getLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentList = prefs.getStringList(_key) ?? [];

      return currentList.map((jsonStr) {
        return NotificationModel.fromJson(jsonDecode(jsonStr));
      }).toList();
    } catch (e) {
      print('Error getting local notifications: $e');
      return [];
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> deleteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentList = prefs.getStringList(_key) ?? [];

      currentList.removeWhere((jsonStr) {
        final json = jsonDecode(jsonStr);
        return json['id'] == id || json['_id'] == id;
      });

      await prefs.setStringList(_key, currentList);
    } catch (e) {
      print('Error deleting local notification: $e');
    }
  }
}
