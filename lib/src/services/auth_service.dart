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
      if (user != null && user['id'] != null) {
        final response = await _apiService.get('/students/${user['id']}');
        if (response.statusCode == 200) {
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

  // Verification Methods
  Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    try {
      final response = await _apiService.post(
        '/verify/email/send',
        data: {'email': email},
      );
      return {'success': true, 'message': response.data['message']};
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? e.message ?? 'Failed to send OTP',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyEmailOtp(String email, String otp) async {
    try {
      final response = await _apiService.post(
        '/verify/email/verify',
        data: {'email': email, 'otp': otp},
      );
      return {'success': true, 'message': response.data['message']};
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? e.message ?? 'Verification failed',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendMobileOtp(String phone) async {
    try {
      final response = await _apiService.post(
        '/verify/mobile/send',
        data: {'phone': phone},
      );
      return {'success': true, 'message': response.data['message']};
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? e.message ?? 'Failed to send OTP',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyMobileOtp(String phone, String otp) async {
    try {
      final response = await _apiService.post(
        '/verify/mobile/verify',
        data: {'phone': phone, 'otp': otp},
      );
      return {'success': true, 'message': response.data['message']};
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? e.message ?? 'Verification failed',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put('/students/$id', data: data);
      if (response.statusCode == 200) {
        // Update local storage
        final user = response.data['student'];
        if (user['_id'] != null) user['id'] = user['_id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user));

        return {
          'success': true,
          'message': 'Profile updated successfully',
          'user': user,
        };
      }
      return {'success': false, 'message': 'Failed to update profile'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? e.message ?? 'Update failed',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String id,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _apiService.post(
        '/students/change-password',
        data: {
          'id': id,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password updated successfully'};
      }
      return {'success': false, 'message': 'Failed to update password'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? e.message ?? 'Update failed',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
