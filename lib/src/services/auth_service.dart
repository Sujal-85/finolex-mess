import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/error_strings.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  final ApiService _apiService = ApiService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Cache password in memory for current session
  String? _cachedPassword;
  String? get cachedPassword => _cachedPassword;

  Future<bool> login(String email, String password) async {
    try {
      // Bypass for Manager/Admin to access Web Portal
      if ((email == 'manager@gmail.com' && password == 'manager@123') ||
          (email == 'admin@famt.com' && password == 'admin@123')) {
        final mockUser = {
          'id': 'admin_bypass',
          'name': email.contains('manager') ? 'Manager' : 'Admin',
          'email': email,
          'role': 'admin',
          'balance': 0, // Mock balance
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, 'mock_admin_token');
        await prefs.setString(_userKey, jsonEncode(mockUser));

        // Store password persistently ONLY for bypass accounts to survive app restarts
        await prefs.setString('bypass_password', password);

        // Cache password for session to enable Web Portal auto-login
        _cachedPassword = password;

        return true;
      }

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

        // Cache password for session
        _cachedPassword = password;

        return true;
      }
      return false;
    } catch (e) {
      throw ErrorMessages.humanize(e);
    }
  }

  Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/students', data: data);
      if (response.statusCode == 201) {
        return {'success': true, 'studentId': response.data['studentId']};
      } else {
        String message = 'Registration failed';
        if (response.data is Map) {
          message = response.data['message']?.toString() ?? message;
        }
        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {'success': false, 'message': ErrorMessages.humanize(e)};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove('bypass_password'); // Clear bypass password
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

          print(
            '[AuthService] Refreshed User: Balance=${updatedUser['balance']}, ActivePlans=${updatedUser['activePlans']?.length}',
          );

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

  // Verification Methods - Backend OTP
  Future<Map<String, dynamic>> sendEmailOtp(String email, String name) async {
    try {
      final response = await _apiService.post(
        '/verify/send-email-otp',
        data: {'email': email, 'name': name},
      );
      if (response.statusCode == 200) {
        // If in Dev mode, the backed might return the OTP in the message or generic success
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent to $email',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to send OTP',
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message':
              e.response?.data['message'] ?? e.message ?? 'Failed to send OTP',
        };
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyEmailOtp(String email, String otp) async {
    try {
      final response = await _apiService.post(
        '/verify/verify-email-otp',
        data: {'email': email, 'otp': otp},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Email verified successfully'};
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Invalid OTP',
      };
    } catch (e) {
      if (e is DioException) {
        return {
          'success': false,
          'message':
              e.response?.data['message'] ?? e.message ?? 'Verification failed',
        };
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendMobileOtp(String phone) async {
    // This requires a callback setup, usually handled in UI (verifyPhoneNumber).
    // We will return success here and let UI handle the trigger via a different method if needed,
    // OR we expose a method that returns the verificationId.
    // Since this method signature returns Map, we can't easily adhere to the previous API.
    // I will add a NEW method for UI to call directly for Phone Auth.
    return {'success': true, 'message': 'Please use verifyPhoneNumber in UI'};
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) codeSent,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<Map<String, dynamic>> verifyMobileOtp(
    String verificationId,
    String otp,
  ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _firebaseAuth.signInWithCredential(credential);
      return {'success': true, 'message': 'Phone verified successfully'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Invalid OTP'};
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
      String errorMessage = 'Update failed';
      if (e.response?.data is Map) {
        errorMessage =
            e.response?.data['message']?.toString() ??
            e.message ??
            'Update failed';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      return {'success': false, 'message': errorMessage};
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
      String errorMessage = 'Update failed';
      if (e.response?.data is Map) {
        errorMessage =
            e.response?.data['message']?.toString() ??
            e.message ??
            'Update failed';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String id) async {
    try {
      final response = await _apiService.delete('/students/$id');
      if (response.statusCode == 200) {
        await logout(); // Clear local data
        return {'success': true, 'message': 'Account deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete account'};
    } catch (e) {
      return {'success': false, 'message': ErrorMessages.humanize(e)};
    }
  }
}
