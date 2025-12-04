import 'package:flutter/material.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _api = ApiService();

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
