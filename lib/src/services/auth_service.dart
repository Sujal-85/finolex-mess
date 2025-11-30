import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  final ApiService _apiService = ApiService();

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        '/students/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final user = response.data['student'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, jsonEncode(user));
        return true;
      }
      return false;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? e.message ?? 'Login failed',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/students', data: data);
      if (response.statusCode == 201) {
        return {'success': true, 'studentId': response.data['studentId']};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Registration failed',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? e.message ?? 'Registration failed',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> refreshUser() async {
    try {
      final user = await getUser();
      if (user != null && user['rollNo'] != null) {
        final response = await _apiService.get('/students/${user['rollNo']}');
        if (response.statusCode == 200) {
          // The backend returns the full student object.
          // We need to ensure we map it correctly to what the app expects.
          // The login response structure was: { token, student: { id, name, ... } }
          // The GET /:rollNo response is just the student object.
          // We should probably normalize this, but for now let's just update the stored user.

          // Note: The backend GET /:rollNo returns the raw mongoose document.
          // We might need to map '_id' to 'id' if the app expects 'id'.
          final updatedUser = response.data;
          if (updatedUser['_id'] != null) {
            updatedUser['id'] = updatedUser['_id'];
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(updatedUser));
          return updatedUser;
        }
      }
    } catch (e) {
      // If refresh fails, return the cached user
      print('Error refreshing user: $e');
    }
    return await getUser();
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
