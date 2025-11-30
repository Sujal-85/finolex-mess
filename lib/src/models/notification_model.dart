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
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      isUnread: json['isUnread'] as bool? ?? true,
      isNew: json['isNew'] as bool? ?? false,
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

enum NotificationType { mess, payment, news, urgent, general }

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
      default:
        return 'General';
    }
  }
}
