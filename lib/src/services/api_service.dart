import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  final String baseUrl =
      'https://finolex-mess.onrender.com/api'; // Use 10.0.2.2 for Android emulator

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptors if needed (e.g., for auth tokens)
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
}
