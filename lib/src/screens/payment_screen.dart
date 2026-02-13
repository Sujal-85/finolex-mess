import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../widgets/animations/famt_loader.dart';
import '../widgets/profile_style_header.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Controllers
  final TextEditingController _amountController = TextEditingController();

  // State variables
  double _amount = 1000.0;
  bool _isProcessing = false;

  late Razorpay _razorpay;
  XFile? _selectedReceipt;
  final ImagePicker _picker = ImagePicker();

  // Services
  final AuthService _authService = AuthService();
  final PaymentService _paymentService = PaymentService();

  Map<String, dynamic>? _user;
  double _maxPayable = 3500.0;

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _amountController.text = _amount.toStringAsFixed(0);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _fetchUser() async {
    final user = await _authService.refreshUser();
    if (user != null) {
      double balance = (user['balance'] ?? 0).toDouble();
      double pendingAmount = 0.0;
      try {
        final transactions = await _paymentService.fetchTransactionHistory(
          user['id'] ?? user['_id'],
        );
        pendingAmount = transactions
            .where((t) => t['status'] == 'Pending')
            .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
      } catch (e) {
        debugPrint('Error fetching transactions for balance check: $e');
      }

      double fine = (user['fineAmount'] ?? 0).toDouble();
      double remaining = balance + fine - pendingAmount;

      if (mounted) {
        setState(() {
          _user = user;
          _maxPayable = remaining > 0 ? remaining : 0;
          _amount = remaining > 0 ? remaining : 0;
          _amountController.text = _amount.toStringAsFixed(0);
        });
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    try {
      await _paymentService.verifyRazorpayPayment({
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'studentId': _user?['id'] ?? _user?['_id'],
        'amount': _amount,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchUser(); // Refresh balance
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Verification Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet: ${response.walletName}')),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _startPayment() async {
    if (_amount <= 0 && _maxPayable > 0) {
      // Allow user to pay even if balance is fine, but not 0 amount.
      // logic: must be positive amount
    }
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final order = await _paymentService.createRazorpayOrder(_amount);

      var options = {
        'key': 'rzp_test_SBN8qqqrYVLeS7',
        'amount': order['amount'],
        'name': 'Finolex Canteen',
        'description': 'Add Money to Wallet',
        'order_id': order['id'],
        'prefill': {
          'contact': _user?['phone'] ?? '',
          'email': _user?['email'] ?? '',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Payment Start Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate payment: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  void _updateAmount(double newAmount) {
    double validAmount = newAmount;
    if (validAmount < 0) validAmount = 0;
    if (validAmount > _maxPayable) validAmount = _maxPayable;

    setState(() {
      _amount = validAmount;
      _amountController.text = _amount.toStringAsFixed(0);
    });
  }

  Future<void> _shareQrCode() async {
    try {
      final byteData = await rootBundle.load('assets/images/upi_qr.png');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/upi_qr.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Pay via UPI for Finolex Canteen');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing QR: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: Stack(
          children: [
            Column(
              children: [
                ProfileStyleHeader(
                  title: 'Add Money',
                  showBackButton: true,
                  onBackTap: () => context.pop(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: _buildAmountSection(),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: NeumorphicStyle.cardDecoration(
                          context,
                          borderRadius: 25,
                        ),
                        child: TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondaryLight,
                          indicatorColor: AppColors.primary,
                          labelStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'Online Payment'),
                            Tab(text: 'Manual UPI'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: TabBarView(
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: _buildPaymentGatewaySection(),
                            ),
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: _buildManualUpiSection(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_isProcessing)
              Container(
                color: Colors.black.withAlpha(128),
                child: const Center(child: FamtLoader()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Amount',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Column(
            children: [
              Text(
                '₹${_amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAmountButton(
                    Icons.remove,
                    () => _updateAmount(_amount - 100),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: NeumorphicStyle.cardDecoration(
                      context,
                      borderRadius: 20,
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(
                            () => _amount = double.tryParse(value) ?? 0.0,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  _buildAmountButton(
                    Icons.add,
                    () => _updateAmount(_amount + 100),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Balance Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Max Payable: ₹${_maxPayable.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: NeumorphicStyle.buttonDecoration(
          context,
          borderRadius: 20,
          color: AppColors.primary,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildPaymentGatewaySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
      child: Column(
        children: [
          Image.asset(
            'assets/images/razorpay_logo.png',
            height: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Gateway',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Secure payments via cards, netbanking & more',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null, // Disabled for now
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, // Disabled color
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Coming Soon',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualUpiSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner, size: 60, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Manual UPI Payment',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan QR code and upload receipt',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          // QR Code Display
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                width: 200,
                color: Colors.white,
                child: Image.asset(
                  'assets/images/upi_qr.png',
                  fit: BoxFit.contain,
                  errorBuilder: (c, o, s) =>
                      const Icon(Icons.qr_code, size: 100, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: IconButton(
                  onPressed: _shareQrCode,
                  icon: const Icon(Icons.share, color: AppColors.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _shareQrCode,
            icon: const Icon(Icons.share),
            label: const Text('Share QR Code'),
          ),

          const SizedBox(height: 20),
          if (_selectedReceipt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Receipt Selected: ${_selectedReceipt!.name}',
                style: const TextStyle(color: Colors.green),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() => _selectedReceipt = image);
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Receipt'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedReceipt == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please upload a screenshot of the payment',
                      ),
                    ),
                  );
                  return;
                }
                setState(() => _isProcessing = true);
                try {
                  final url = await _paymentService.uploadReceipt(
                    _selectedReceipt!,
                  );
                  await _paymentService.createManualTransaction({
                    'studentId': _user?['id'] ?? _user?['_id'],
                    'amount': _amount,
                    'receiptUrl': url,
                    'upiId': 'MANUAL_UPLOAD',
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment Submitted for Review'),
                    ),
                  );
                  setState(() => _selectedReceipt = null);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  setState(() => _isProcessing = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Submit Payment',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
