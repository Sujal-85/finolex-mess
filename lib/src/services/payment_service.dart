import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _api = ApiService();

  Future<String?> uploadReceipt(dynamic file) async {
    try {
      String fileName = file.path.split('/').last;
      // Ensure filename has extension
      if (!fileName.contains('.')) {
        fileName = '$fileName.jpg';
      }

      FormData formData;
      if (kIsWeb) {
        // For web: read file as bytes
        final bytes = await file.readAsBytes();

        // Determine MIME type from filename extension
        String mimeType = 'image/jpeg'; // default
        final ext = fileName.split('.').last.toLowerCase();
        if (ext == 'png') {
          mimeType = 'image/png';
        } else if (ext == 'pdf') {
          mimeType = 'application/pdf';
        } else if (ext == 'webp') {
          mimeType = 'image/webp';
        }

        formData = FormData.fromMap({
          "receipt": MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        });
      } else {
        // For mobile: use file path
        formData = FormData.fromMap({
          "receipt": await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        });
      }

      final response = await _api.post('/upload', data: formData);
      return response.data['fileUrl'];
    } catch (e) {
      debugPrint('Error uploading receipt: $e');
      rethrow;
    }
  }

  Future<void> createManualTransaction(Map<String, dynamic> data) async {
    try {
      await _api.post('/payments/manual-upi', data: data);
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> fetchTransactionHistory(String studentId) async {
    try {
      final response = await _api.get('/payments/history/$studentId');
      return response.data;
    } catch (e) {
      debugPrint('Error fetching history: $e');
      return [];
    }
  }
}
