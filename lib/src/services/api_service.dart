import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  final String baseUrl = 'https://api-457xe7azkq-uc.a.run.app';
  // final String baseUrl = 'http://10.37.84.157:4000/api'; // Android Emulator loopback
  // final String baseUrl = 'http://10.37.84.157:4000/api'; // Physical Device
  // Use for Physical Device (LAN IP)

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    print('[ApiService] Initialized with BaseURL: $baseUrl');

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  Dio get dio => _dio;

  // Generic GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Generic POST
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Generic PATCH
  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Generic PUT
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Generic DELETE
  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> updateFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('auth_user');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        final userId = user['id'] ?? user['_id'];
        if (userId != null) {
          return await _dio.put(
            '/students/$userId/fcm-token',
            data: {'fcmToken': token},
          );
        }
      }
      throw Exception('User ID not found');
    } catch (e) {
      rethrow;
    }
  }
}
