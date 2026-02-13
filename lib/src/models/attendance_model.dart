class MealStatus {
  final String status;
  final DateTime? markedAt;
  final DateTime? verifiedAt;

  MealStatus({required this.status, this.markedAt, this.verifiedAt});

  factory MealStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MealStatus(status: 'not_marked');
    return MealStatus(
      status: json['status'] ?? 'not_marked',
      markedAt: json['markedAt'] != null
          ? DateTime.parse(json['markedAt'])
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'markedAt': markedAt?.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }
}

class Attendance {
  final String? id;
  final String date;
  final MealStatus breakfast;
  final MealStatus lunch;
  final MealStatus dinner;
  final DateTime createdAt;

  Attendance({
    this.id,
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'],
      date: json['date'] ?? DateTime.now().toIso8601String(),
      breakfast: MealStatus.fromJson(json['meals']?['breakfast']),
      lunch: MealStatus.fromJson(json['meals']?['lunch']),
      dinner: MealStatus.fromJson(json['meals']?['dinner']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'date': date,
      'meals': {
        'breakfast': breakfast.toJson(),
        'lunch': lunch.toJson(),
        'dinner': dinner.toJson(),
      },
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
