import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import '../models/settings_model.dart';

class SettingsService extends ChangeNotifier {
  final SettingsModel _settings = SettingsModel();

  SettingsModel get settings => _settings;

  ThemeMode get themeMode {
    if (_settings.isAutoMode) return ThemeMode.system;
    return _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  SettingsService() {
    loadSettings();
  }

  // Appearance settings
  Future<void> toggleDarkMode(bool value) async {
    _settings.isDarkMode = value;
    _settings.isAutoMode = false;
    notifyListeners();
    await _savePreference('isDarkMode', value);
    await _savePreference('isAutoMode', false);
  }

  Future<void> setAutoMode(bool value) async {
    _settings.isAutoMode = value;
    notifyListeners();
    await _savePreference('isAutoMode', value);
  }

  // Language settings
  Future<void> setLanguage(String language) async {
    _settings.language = language;
    notifyListeners();
    await _savePreference('language', language);
  }

  // Notification settings
  Future<void> togglePushNotifications(bool value) async {
    _settings.pushNotifications = value;
    notifyListeners();
    await _savePreference('pushNotifications', value);
  }

  Future<void> toggleMessAlerts(bool value) async {
    _settings.messAlerts = value;
    notifyListeners();
    await _savePreference('messAlerts', value);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('auth_user');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        final userId = user['id'] ?? user['_id'];
        if (userId != null) {
          final api = ApiService();
          await api.put(
            '/students/$userId',
            data: {
              'settings': {'messAlerts': value},
            },
          );
        }
      }
    } catch (e) {
      print('Error syncing messAlerts: $e');
    }
  }

  Future<void> togglePaymentUpdates(bool value) async {
    _settings.paymentUpdates = value;
    notifyListeners();
    await _savePreference('paymentUpdates', value);
  }

  Future<void> toggleAnnouncements(bool value) async {
    _settings.announcements = value;
    notifyListeners();
    await _savePreference('announcements', value);
  }

  Future<void> toggleUrgentAlerts(bool value) async {
    _settings.urgentAlerts = value;
    notifyListeners();
    await _savePreference('urgentAlerts', value);
  }

  // Load settings from storage
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _settings.isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _settings.isAutoMode =
        prefs.getBool('isAutoMode') ?? true; // Default to Auto
    _settings.language = prefs.getString('language') ?? 'English';
    _settings.pushNotifications = prefs.getBool('pushNotifications') ?? true;
    _settings.messAlerts = prefs.getBool('messAlerts') ?? true;
    _settings.paymentUpdates = prefs.getBool('paymentUpdates') ?? true;
    _settings.announcements = prefs.getBool('announcements') ?? true;
    _settings.urgentAlerts = prefs.getBool('urgentAlerts') ?? true;
    notifyListeners();
  }

  // Helper to save single preference
  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  // Save all settings (legacy method, kept for compatibility if needed)
  Future<void> saveSettings() async {
    // Individual setters now handle saving
  }
}
