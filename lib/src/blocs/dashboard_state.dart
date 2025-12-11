import 'package:equatable/equatable.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final double balance;
  final String nextMeal;
  final int unreadNotifications;
  final String latestAnnouncement;
  final String studentName;
  final String? profileImage;
  final String hostelBlock;
  final String roomNumber;
  final List<Map<String, dynamic>> birthdays;
  final List<dynamic> recentTransactions;
  final double pendingAmount;

  // New Payment Fields
  final double fineAmount;
  final DateTime? paymentDueDate;
  final double messFee;

  final String breakfastItem;
  final String lunchItem;
  final String dinnerItem;

  const DashboardLoaded({
    required this.balance,
    required this.nextMeal,
    this.breakfastItem = 'Breakfast',
    this.lunchItem = 'Lunch',
    this.dinnerItem = 'Dinner',
    required this.unreadNotifications,
    required this.latestAnnouncement,
    required this.studentName,
    this.profileImage,
    required this.hostelBlock,
    required this.roomNumber,
    this.birthdays = const [],
    this.recentTransactions = const [],
    this.pendingAmount = 0.0,
    this.fineAmount = 0.0,
    this.paymentDueDate,
    this.messFee = 3500.0,
  });

  DashboardLoaded copyWith({
    double? balance,
    String? nextMeal,
    String? breakfastItem,
    String? lunchItem,
    String? dinnerItem,
    int? unreadNotifications,
    String? latestAnnouncement,
    String? studentName,
    String? profileImage,
    String? hostelBlock,
    String? roomNumber,
    List<Map<String, dynamic>>? birthdays,
    List<dynamic>? recentTransactions,
    double? pendingAmount,
    double? fineAmount,
    DateTime? paymentDueDate,
    double? messFee,
  }) {
    return DashboardLoaded(
      balance: balance ?? this.balance,
      nextMeal: nextMeal ?? this.nextMeal,
      breakfastItem: breakfastItem ?? this.breakfastItem,
      lunchItem: lunchItem ?? this.lunchItem,
      dinnerItem: dinnerItem ?? this.dinnerItem,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      latestAnnouncement: latestAnnouncement ?? this.latestAnnouncement,
      studentName: studentName ?? this.studentName,
      profileImage: profileImage ?? this.profileImage,
      hostelBlock: hostelBlock ?? this.hostelBlock,
      roomNumber: roomNumber ?? this.roomNumber,
      birthdays: birthdays ?? this.birthdays,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      fineAmount: fineAmount ?? this.fineAmount,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      messFee: messFee ?? this.messFee,
    );
  }

  @override
  List<Object?> get props => [
    balance,
    nextMeal,
    breakfastItem,
    lunchItem,
    dinnerItem,
    unreadNotifications,
    latestAnnouncement,
    studentName,
    profileImage,
    hostelBlock,
    roomNumber,
    birthdays,
    recentTransactions,
    pendingAmount,
    fineAmount,
    paymentDueDate,
    messFee,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object> get props => [message];
}
