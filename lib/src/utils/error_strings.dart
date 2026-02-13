import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorMessages {
  /// Maps any exception to a user-friendly string.
  static String humanize(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    } else if (error is String) {
      return error;
    }

    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network_error') ||
        errorStr.contains('socketexception')) {
      return 'No internet connection. Please check your network.';
    }

    if (errorStr.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }

    return 'Something went wrong. Please try again later.';
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet.';
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'].toString();
        }
        return 'Server error (Code: ${error.response?.statusCode}).';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Wait, we can\'t reach the server. Are you online?';
      default:
        return 'A network error occurred. Please try again.';
    }
  }

  static String _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'The phone number entered is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'operation-not-allowed':
        return 'Login is currently disabled.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your data connection.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
}
