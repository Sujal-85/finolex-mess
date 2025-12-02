import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final AuthService _authService = AuthService();

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
      final api = ApiService();
      final response = await api.get('/announcements');
      final announcements = response.data as List;
      final latestAnnouncement = announcements.isNotEmpty
          ? announcements.first['title']
          : 'No new announcements';

      final user = await _authService.refreshUser();
      final studentName = user?['name'] ?? 'Student';
      final profileImage = user?['profileImage'];
      final balance = (user?['balance'] ?? 0).toDouble();

      final hostelDetails = user?['hostelDetails'] ?? {};
      final hostelBlock = hostelDetails['hostelName'] ?? 'Not Assigned';
      final roomNumber = hostelDetails['roomNo'] ?? 'N/A';

      // Fetch birthdays
      final birthdayResponse = await api.get('/students/birthdays/today');
      final birthdays = List<Map<String, dynamic>>.from(birthdayResponse.data);

      emit(
        DashboardLoaded(
          balance: balance,
          nextMeal: 'Lunch: Veg Thali, Rice, Dal',
          unreadNotifications: 3,
          latestAnnouncement: latestAnnouncement,
          studentName: studentName,
          profileImage: profileImage,
          hostelBlock: hostelBlock,
          roomNumber: roomNumber,
          birthdays: birthdays,
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
    try {
      await Future.delayed(const Duration(seconds: 1));

      final user = await _authService.refreshUser();
      final studentName = user?['name'] ?? 'Student';
      final profileImage = user?['profileImage'];
      final balance = (user?['balance'] ?? 0).toDouble();

      final hostelDetails = user?['hostelDetails'] ?? {};
      final hostelBlock = hostelDetails['hostelName'] ?? 'Not Assigned';
      final roomNumber = hostelDetails['roomNo'] ?? 'N/A';

      final api = ApiService();
      final birthdayResponse = await api.get('/students/birthdays/today');
      final birthdays = List<Map<String, dynamic>>.from(birthdayResponse.data);

      emit(
        DashboardLoaded(
          balance: balance,
          nextMeal: 'Lunch: Veg Thali, Rice, Dal',
          unreadNotifications: 3,
          latestAnnouncement: 'Mess closed on Sunday evening',
          studentName: studentName,
          profileImage: profileImage,
          hostelBlock: hostelBlock,
          roomNumber: roomNumber,
          birthdays: birthdays,
        ),
      );
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}
