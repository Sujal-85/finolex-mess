import 'package:dio/dio.dart';
import 'package:finolex_student/src/services/api_service.dart';
import 'package:finolex_student/src/models/attendance_model.dart';

class AttendanceService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> markAttendance(String mealType) async {
    try {
      final response = await _apiService.post(
        '/attendance/mark',
        data: {'mealType': mealType},
      );
      return response.data;
    } catch (e) {
      print('[AttendanceService] Error marking attendance for $mealType: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('AUTH_EXPIRED');
        }
        throw Exception(
          e.response?.data['message'] ?? 'Failed to mark attendance',
        );
      }
      throw Exception('Failed to connect to server');
    }
  }

  Future<Attendance?> getTodayStatus() async {
    try {
      final response = await _apiService.get('/attendance/status');
      if (response.data['status'] == 'not_marked' &&
          response.data['attendance'] == null) {
        // Return structured object even if not marked, or null if you prefer
        // Based on backend, it might return { attendance: null } or structured object
        if (response.data['attendance'] == null) {
          return Attendance(
            date: DateTime.now().toIso8601String(),
            breakfast: MealStatus(status: 'not_marked'),
            lunch: MealStatus(status: 'not_marked'),
            dinner: MealStatus(status: 'not_marked'),
            createdAt: DateTime.now(),
          );
        }
      }
      return Attendance.fromJson(response.data['attendance']);
    } catch (e) {
      print('[AttendanceService] Error fetching status: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('AUTH_EXPIRED');
      }
      return null;
    }
  }

  Future<List<Attendance>> getHistory() async {
    try {
      final response = await _apiService.get('/attendance/history');
      if (response.data is List) {
        return (response.data as List)
            .map((item) => Attendance.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('[AttendanceService] Error fetching history: $e');
      return [];
    }
  }
}
