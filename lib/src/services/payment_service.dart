import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class PaymentService {
  late Razorpay _razorpay;
  final ApiService _api = ApiService();

  void init(
    Function(PaymentSuccessResponse) handlePaymentSuccess,
    Function(PaymentFailureResponse) handlePaymentError,
    Function(ExternalWalletResponse) handleExternalWallet,
  ) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<void> openCheckout({
    required double amount,
    required String studentId,
    required String email,
    required String contact,
    required String description,
    String? vpa,
  }) async {
    try {
      // 1. Create Order on Backend
      final response = await _api.post(
        '/payments/create-order',
        data: {'amount': amount, 'currency': 'INR'},
      );

      final orderId = response.data['id'];
      final keyId =
          'YOUR_RAZORPAY_KEY_ID'; // Replace with actual key or fetch from backend config

      var options = {
        'key': keyId,
        'amount': (amount * 100).toString(),
        'name': 'Finolex Canteen',
        'description': description,
        'order_id': orderId,
        'prefill': {
          'contact': contact,
          'email': email,
          if (vpa != null && vpa.isNotEmpty) 'vpa': vpa,
        },
        'theme': {'color': '#1E88E5'},
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening checkout: $e');
      rethrow;
    }
  }

  Future<void> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String studentId,
    required double amount,
  }) async {
    try {
      await _api.post(
        '/payments/verify',
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'studentId': studentId,
          'amount': amount,
        },
      );
    } catch (e) {
      debugPrint('Error verifying payment: $e');
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
