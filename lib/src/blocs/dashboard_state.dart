import 'package:equatable/equatable.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final double balance;
  final String nextMeal;
  final int unreadNotifications;
  final String latestAnnouncement;

  const DashboardLoaded({
    required this.balance,
    required this.nextMeal,
    required this.unreadNotifications,
    required this.latestAnnouncement,
  });

  @override
  List<Object> get props => [
    balance,
    nextMeal,
    unreadNotifications,
    latestAnnouncement,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object> get props => [message];
}
