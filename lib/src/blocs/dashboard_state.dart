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

  const DashboardLoaded({
    required this.balance,
    required this.nextMeal,
    required this.unreadNotifications,
    required this.latestAnnouncement,
    required this.studentName,
    this.profileImage,
    required this.hostelBlock,
    required this.roomNumber,
    this.birthdays = const [],
    this.recentTransactions = const [],
  });

  @override
  List<Object?> get props => [
    balance,
    nextMeal,
    unreadNotifications,
    latestAnnouncement,
    studentName,
    profileImage,
    hostelBlock,
    roomNumber,
    birthdays,
    recentTransactions,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object> get props => [message];
}
