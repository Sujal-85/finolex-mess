import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {
  final bool silent;
  const DashboardLoadRequested({this.silent = false});
  @override
  List<Object> get props => [silent];
}

class DashboardRefreshRequested extends DashboardEvent {}

class DashboardNotificationCheck extends DashboardEvent {}
