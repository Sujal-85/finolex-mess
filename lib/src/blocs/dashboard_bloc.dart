import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      emit(
        const DashboardLoaded(
          balance: 1500.00,
          nextMeal: 'Lunch: Veg Thali, Rice, Dal',
          unreadNotifications: 3,
          latestAnnouncement: 'Mess closed on Sunday evening',
        ),
      );
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Keep current state but maybe show loading indicator if needed, or just reload
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(
        const DashboardLoaded(
          balance: 1500.00,
          nextMeal: 'Lunch: Veg Thali, Rice, Dal',
          unreadNotifications: 3,
          latestAnnouncement: 'Mess closed on Sunday evening',
        ),
      );
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}
