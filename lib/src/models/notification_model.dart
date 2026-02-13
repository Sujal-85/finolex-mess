class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final NotificationType type;
  final bool isUnread;
  final bool isNew;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.isUnread = true,
    this.isNew = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? 'No Title',
      description:
          json['message'] as String? ??
          json['description'] as String? ??
          'No Description',
      timestamp: DateTime.parse(
        json['timestamp'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
      type: _parseNotificationType(json['type']),
      isUnread: json.containsKey('isUnread')
          ? (json['isUnread'] as bool? ?? true)
          : !(json['isRead'] as bool? ?? false),
      isNew: json['isNew'] as bool? ?? false,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    if (type == 'device_only') return NotificationType.deviceOnly;
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.general,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'isUnread': isUnread,
      'isNew': isNew,
    };
  }
}

enum NotificationType { mess, payment, news, urgent, general, deviceOnly }

extension NotificationTypeExtension on NotificationType {
  String get iconName {
    switch (this) {
      case NotificationType.mess:
        return 'food_icon';
      case NotificationType.payment:
        return 'payment_icon';
      case NotificationType.news:
        return 'news_icon';
      case NotificationType.urgent:
        return 'alert_icon';
      case NotificationType.deviceOnly:
        return 'system_icon';
      default:
        return 'general_icon';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.mess:
        return 'Mess';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.news:
        return 'News';
      case NotificationType.urgent:
        return 'Urgent';
      case NotificationType.deviceOnly:
        return 'System';
      default:
        return 'General';
    }
  }
}
