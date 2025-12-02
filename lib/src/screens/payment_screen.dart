import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/animations/famt_loader.dart';
import '../widgets/animations/success_confetti.dart';
import '../services/auth_service.dart';
import '../widgets/profile_style_header.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _userUpiController = TextEditingController();

  // State variables
  int _currentStep = 0; // 0: Amount & Method, 1: Timer (UPI only), 2: Success
  double _amount = 1000.0;
  bool _isProcessing = false;
  bool _showSuccess = false;
  File? _receiptImage;
  Timer? _timer;
  int _timeLeft = 300; // 5 minutes
  int _paymentMethodIndex = 0; // 0: QR Code, 1: UPI ID
  bool _isUpiVerified = false;

  // Services
  final AuthService _authService = AuthService();
  final Dio _dio = Dio();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _amountController.text = _amount.toStringAsFixed(0);
  }

  Future<void> _fetchUser() async {
    final user = await _authService.getUser();
    setState(() {
      _user = user;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _userUpiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment session timed out')),
        );
        setState(() {
          _currentStep = 0;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _updateAmount(double newAmount) {
    setState(() {
      _amount = newAmount < 1000 ? 1000 : newAmount;
      _amountController.text = _amount.toStringAsFixed(0);
    });
  }

  Future<void> _pickReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _receiptImage = File(image.path);
      });
    }
  }

  void _verifyUpiId() {
    if (_userUpiController.text.contains('@') &&
        _userUpiController.text.length > 3) {
      setState(() {
        _isUpiVerified = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('UPI ID Verified')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid UPI ID format')));
    }
  }

  Future<void> _submitPayment({bool isQr = false}) async {
    // For QR, receipt is mandatory. For UPI App, it's optional/not requested.
    if (isQr && _receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the transaction receipt')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      String? receiptUrl;
      const String baseUrl = 'http://localhost:3000/api';

      // 1. Upload Receipt if present
      if (_receiptImage != null) {
        String fileName = _receiptImage!.path.split('/').last;
        FormData formData = FormData.fromMap({
          "receipt": await MultipartFile.fromFile(
            _receiptImage!.path,
            filename: fileName,
          ),
        });
        final uploadResponse = await _dio.post(
          '$baseUrl/upload',
          data: formData,
        );
        receiptUrl = uploadResponse.data['fileUrl'];
      }

      // 2. Create Transaction
      final transactionData = {
        'studentId': _user?['id'] ?? _user?['_id'],
        'amount': _amount,
        'receiptUrl': receiptUrl,
        'upiId': _paymentMethodIndex == 1
            ? (_userUpiController.text.isNotEmpty
                  ? _userUpiController.text
                  : 'UPI_APP')
            : 'QR_SCAN',
      };

      await _dio.post('$baseUrl/payments/manual-upi', data: transactionData);

      setState(() {
        _isProcessing = false;
        _showSuccess = true;
        _currentStep = 2; // Success
      });

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          context.pop();
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting payment: $e')));
    }
  }

  Future<void> _launchUpiApp({String? appScheme}) async {
    const String vpa = 'sandeeptambe86@okicici';
    const String name = 'Sandeep Tambe';
    final String uri =
        'upi://pay?pa=$vpa&pn=$name&am=$_amount&cu=INR'; // Standard UPI intent

    Uri launchUri = Uri.parse(uri);
    if (appScheme != null) {
      // If specific app scheme is requested (e.g. phonepe://)
      // Note: Usually we launch the intent with the package or scheme.
      // For simplicity, we stick to the standard intent which Android handles by showing the chooser.
      // Or we can try to launch specific scheme if we knew the format.
      // But standard 'upi://' is best for "Detect automatically".
    }

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
      // After launching, we start the timer screen for UPI flow
      setState(() {
        _currentStep = 1; // Timer Screen
      });
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No UPI app found to handle this request'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          Column(
            children: [
              ProfileStyleHeader(
                title: 'Add Money',
                showBackButton: true,
                onBackTap: () {
                  if (_currentStep > 0 && _currentStep < 2) {
                    setState(() {
                      _currentStep = 0;
                      _timer?.cancel();
                    });
                  } else {
                    context.pop();
                  }
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        if (_currentStep == 0) ...[
                          _buildAmountSection(),
                          const SizedBox(height: 20),
                          _buildTabs(),
                          const SizedBox(height: 20),
                          if (_paymentMethodIndex == 0) _buildQrContent(),
                          if (_paymentMethodIndex == 1) _buildUpiContent(),
                        ],
                        if (_currentStep == 1) _buildTimerSection(),
                        if (_currentStep == 2) _buildSuccessSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(child: FamtLoader()),
            ),

          if (_showSuccess)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(child: SuccessConfetti(onCompleted: () {})),
            ),
        ],
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
                  GestureDetector(
                    onTap: () => _updateAmount(_amount - 100),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: NeumorphicStyle.buttonDecoration(
                        context,
                        borderRadius: 20,
                        color: AppColors.primary,
                      ),
                      child: const Icon(Icons.remove, color: Colors.white),
                    ),
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
                          final amount = double.tryParse(value) ?? 1000.0;
                          setState(() {
                            _amount = amount;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => _updateAmount(_amount + 100),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: NeumorphicStyle.buttonDecoration(
                        context,
                        borderRadius: 20,
                        color: AppColors.primary,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Minimum amount: ₹1000',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _amount < 1000
                      ? Colors.red
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 50,
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _paymentMethodIndex = 0),
              child: Container(
                decoration: _paymentMethodIndex == 0
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: AppColors.primary.withOpacity(0.1),
                      )
                    : null,
                child: Center(
                  child: Text(
                    'Scan QR',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: _paymentMethodIndex == 0
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: _paymentMethodIndex == 0
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _paymentMethodIndex = 1),
              child: Container(
                decoration: _paymentMethodIndex == 1
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: AppColors.primary.withOpacity(0.1),
                      )
                    : null,
                child: Center(
                  child: Text(
                    'UPI ID',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: _paymentMethodIndex == 1
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: _paymentMethodIndex == 1
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
      child: Column(
        children: [
          Text(
            'Scan QR to Pay',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/upi_qr.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _launchUpiApp,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.share,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Upload Payment Receipt',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickReceipt,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: _receiptImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(_receiptImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload screenshot',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitPayment(isQr: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Submit Payment',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
      child: Column(
        children: [
          Text(
            'Enter Your UPI ID',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: NeumorphicStyle.cardDecoration(
              context,
              borderRadius: 20,
            ),
            child: TextField(
              controller: _userUpiController,
              style: GoogleFonts.poppins(fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'e.g. user@upi',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textSecondaryLight.withOpacity(0.7),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: _verifyUpiId,
                  color: _isUpiVerified ? Colors.green : Colors.grey,
                ),
              ),
              onChanged: (val) {
                if (_isUpiVerified) setState(() => _isUpiVerified = false);
              },
            ),
          ),
          if (_isUpiVerified) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _launchUpiApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Pay Now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            'Or Pay with Installed Apps',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildUpiAppButton('GPay', 'gpay', Colors.blue),
              _buildUpiAppButton('PhonePe', 'phonepe', Colors.purple),
              _buildUpiAppButton('Paytm', 'paytm', Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpiAppButton(String name, String scheme, Color color) {
    return GestureDetector(
      onTap: () => _launchUpiApp(appScheme: scheme),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(Icons.account_balance_wallet, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Circular Timer
        SizedBox(
          height: 250,
          width: 250,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: _timeLeft / 300,
                strokeWidth: 12,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Time Remaining',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_timeLeft),
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Complete payment in your UPI app',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _submitPayment(isQr: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'I have Paid',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_filled,
              color: Colors.orange,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Submitted',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Waiting for manager approval.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
