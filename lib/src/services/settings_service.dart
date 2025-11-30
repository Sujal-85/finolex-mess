import 'package:flutter/material.dart';
import '../models/settings_model.dart';

class SettingsService extends ChangeNotifier {
  final SettingsModel _settings = SettingsModel();

  SettingsModel get settings => _settings;

  // Appearance settings
  void toggleDarkMode(bool value) {
    _settings.isDarkMode = value;
    _settings.isAutoMode = false;
    notifyListeners();
  }

  void setAutoMode(bool value) {
    _settings.isAutoMode = value;
    notifyListeners();
  }

  // Language settings
  void setLanguage(String language) {
    _settings.language = language;
    notifyListeners();
  }

  // Notification settings
  void togglePushNotifications(bool value) {
    _settings.pushNotifications = value;
    notifyListeners();
  }

  void toggleMessAlerts(bool value) {
    _settings.messAlerts = value;
    notifyListeners();
  }

  void togglePaymentUpdates(bool value) {
    _settings.paymentUpdates = value;
    notifyListeners();
  }

  void toggleAnnouncements(bool value) {
    _settings.announcements = value;
    notifyListeners();
  }

  void toggleUrgentAlerts(bool value) {
    _settings.urgentAlerts = value;
    notifyListeners();
  }

  // Load settings from storage (simulated)
  Future<void> loadSettings() async {
    // In a real app, this would load from shared preferences or a database
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  // Save settings to storage (simulated)
  Future<void> saveSettings() async {
    // In a real app, this would save to shared preferences or a database
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
