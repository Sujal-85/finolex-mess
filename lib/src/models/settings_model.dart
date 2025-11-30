class SettingsModel {
  bool isDarkMode;
  bool isAutoMode;
  String language;
  bool pushNotifications;
  bool messAlerts;
  bool paymentUpdates;
  bool announcements;
  bool urgentAlerts;

  SettingsModel({
    this.isDarkMode = false,
    this.isAutoMode = true,
    this.language = 'English',
    this.pushNotifications = true,
    this.messAlerts = true,
    this.paymentUpdates = true,
    this.announcements = true,
    this.urgentAlerts = true,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      isAutoMode: json['isAutoMode'] as bool? ?? true,
      language: json['language'] as String? ?? 'English',
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      messAlerts: json['messAlerts'] as bool? ?? true,
      paymentUpdates: json['paymentUpdates'] as bool? ?? true,
      announcements: json['announcements'] as bool? ?? true,
      urgentAlerts: json['urgentAlerts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'isAutoMode': isAutoMode,
      'language': language,
      'pushNotifications': pushNotifications,
      'messAlerts': messAlerts,
      'paymentUpdates': paymentUpdates,
      'announcements': announcements,
      'urgentAlerts': urgentAlerts,
    };
  }
}
