import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_upi_india/flutter_upi_india.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/animations/famt_loader.dart';
import '../widgets/animations/success_confetti.dart';
import '../services/auth_service.dart';

import 'package:flutter/services.dart';
import '../services/payment_service.dart';

import '../services/api_service.dart';
import '../widgets/profile_style_header.dart';
import '../services/local_notification_service.dart';
import '../theme/app_constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
  XFile? _receiptImage;
  Timer? _timer;
  int _timeLeft = 300; // 5 minutes
  int _paymentMethodIndex = 0; // 0: QR Code, 1: UPI ID
  bool _receiptConfirmed = false;

  // Services
  final AuthService _authService = AuthService();
  final PaymentService _paymentService = PaymentService();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _user;

  double _maxPayable = 3500.0;
  List<ApplicationMeta>? _apps;

  @override
  void initState() {
    super.initState();
    _fetchUser();
    // Default initial, will update after user fetch
    // Default initial, will update after user fetch
    _amountController.text = _amount.toStringAsFixed(0);
  }

  Future<void> _fetchUser() async {
    // FORCE REFRESH: Use refreshUser() instead of getUser() to get latest backend data (and trigger read-repair)
    final user = await _authService.refreshUser();
    if (user != null) {
      double balance = (user['balance'] ?? 0).toDouble();

      double pendingAmount = 0.0;
      try {
        final transactions = await _paymentService.fetchTransactionHistory(
          user['id'] ?? user['_id'],
        );
        // Add locally completed (unsynced) balance
        final completedUnsynced = transactions
            .where((t) => t['status'] == 'Completed')
            .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());

        balance += completedUnsynced;

        // Calculate pending amount to deduct from due
        pendingAmount = transactions
            .where((t) => t['status'] == 'Pending')
            .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
      } catch (e) {
        debugPrint('Error fetching transactions for balance check: $e');
      }

      double messFee = 3500.0;
      DateTime? planStartDate;
      try {
        final api = ApiService();
        final planResponse = await api.get('/plans');
        if (planResponse.statusCode == 200 && planResponse.data != null) {
          messFee = (planResponse.data['price'] ?? 3500).toDouble();
          if (planResponse.data['startDate'] != null) {
            planStartDate = DateTime.parse(
              planResponse.data['startDate'],
            ).toLocal();
          }
        }
      } catch (e) {
        debugPrint('Error fetching plan: $e');
      }

      double fine = 0.0;
      if (planStartDate != null) {
        final eighthDay = planStartDate.add(const Duration(days: 7));
        final now = DateTime.now();
        if (now.isAfter(eighthDay)) {
          final today = DateTime(now.year, now.month, now.day);
          final due = DateTime(eighthDay.year, eighthDay.month, eighthDay.day);
          final diffDays = today.difference(due).inDays;
          if (diffDays > 0) {
            fine = diffDays * 5.0;
          }
        }
      } else {
        fine = (user['fineAmount'] ?? 0).toDouble();
      }

      // Logic: (Fee + Fine) - Balance - Pending
      // Also apply logic: Ignore fine if base is covered
      double totalFee = messFee + fine;
      if (balance >= messFee) {
        totalFee = messFee; // Ignore fine if base is covered
      }

      final double remaining = totalFee - balance - pendingAmount;

      setState(() {
        _user = user;
        _maxPayable = remaining > 0 ? remaining : 0;
        _amount = remaining > 0
            ? remaining
            : 0; // Revert _amount to initialAmount
        _amountController.text = _amount.toStringAsFixed(0);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _userUpiController.dispose();

    _timer?.cancel();
    super.dispose();
  }

  // ... (existing timer methods) ...

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _updateAmount(double newAmount) {
    // Clamp between 0 and _maxPayable
    double validAmount = newAmount;
    if (validAmount < 0) validAmount = 0;
    if (validAmount > _maxPayable) validAmount = _maxPayable;

    setState(() {
      _amount = validAmount;
      _amountController.text = _amount.toStringAsFixed(0);
    });
  }

  Future<void> _pickReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _receiptImage = image;
      });
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

      // 1. Upload Receipt if present
      if (_receiptImage != null) {
        receiptUrl = await _paymentService.uploadReceipt(_receiptImage!);
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

      await _paymentService.createManualTransaction(transactionData);

      setState(() {
        _isProcessing = false;
        _showSuccess = true;
        _currentStep = 2; // Success
      });

      // Show Payment Success Notification
      try {
        await LocalNotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Payment Done',
          body: 'Payment is done thank you',
        );
      } catch (e) {
        debugPrint('Failed to show payment notification: $e');
      }

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          context.pop();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting payment: $e')));
      }
    }
  }

  Future<void> _shareQrCode() async {
    try {
      final byteData = await rootBundle.load('assets/images/upi_qr.jpg');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/upi_qr.jpg');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Scan to Pay via UPI');
    } catch (e) {
      debugPrint('Error sharing QR: $e');
    }
  }

  Future<void> _startUpiPayment(ApplicationMeta? appMeta) async {
    // If no specific app is passed but we have apps loaded, try to use GPay or PhonePe first
    // Or just fail if appMeta is required by the package (depending on version)
    // For now, we assume the UI handles app selection or passing null launches a picker (if supported)
    // or we just default to the first available app if null.

    setState(() {
      _isProcessing = true;
    });

    try {
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      final amount = _amount; // UpiIndia takes double

      debugPrint('Starting UPI Transaction via Package...');

      final meta =
          appMeta ?? (_apps != null && _apps!.isNotEmpty ? _apps!.first : null);
      if (meta == null) {
        throw 'No UPI applications found to initiate transaction.';
      }

      // Accessing .upiApplication via dynamic based on user feedback
      final UpiApplication app = (meta as dynamic).upiApplication;

      final UpiTransactionResponse response = await UpiPay.initiateTransaction(
        app: app,
        receiverUpiAddress: AppConstants.canteenVpa,
        receiverName: AppConstants.canteenPayeeName,
        transactionRef: transactionId,
        transactionNote: 'Payment for Canteen',
        amount: amount.toStringAsFixed(2),
      );

      debugPrint('UPI Package Result: ${response.status}');

      String status = 'FAILED';
      switch (response.status) {
        case UpiTransactionStatus.success:
          status = 'SUCCESS';
          break;
        case UpiTransactionStatus.submitted:
          status = 'SUBMITTED';
          break;
        case UpiTransactionStatus.failure:
        default:
          status = 'FAILED';
          break;
      }

      if (status == 'SUCCESS') {
        _submitPayment(isQr: false);
      } else if (status == 'SUBMITTED') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Pending. Please wait.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Failed or Cancelled')),
          );
        }
      }
    } catch (e) {
      debugPrint('UPI Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _launchUpiApp(ApplicationMeta appMeta) async {
    await _showPaymentInstructions(appMeta);
  }

  Future<void> _showPaymentInstructions(ApplicationMeta appMeta) async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51), // 0.2 * 255 ≈ 51
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26), // 0.1 * 255 ≈ 26
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Payment Instructions',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: NeumorphicStyle.cardDecoration(
                  context,
                  borderRadius: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructionStep(
                      '1',
                      'Review the payee name and UPI ID to confirm they are correct.',
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '2',
                      'Check the total amount displayed before proceeding.',
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '3',
                      'If everything looks accurate, approve the transaction using your UPI PIN.',
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '4',
                      'After the payment is successful, return to this app to continue.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26), // 0.1 * 255 ≈ 26
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withAlpha(77),
                  ), // 0.3 * 255 ≈ 77
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'If your UPI app shows an error or daily limit warning, please try a different bank account or UPI app.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textPrimary(context),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startUpiPayment(appMeta);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue to Pay',
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
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textPrimary(context),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
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
              color: Colors.black.withAlpha(179),
              child: const Center(child: FamtLoader()),
            ),

          if (_showSuccess)
            Container(
              color: Colors.black.withAlpha(179),
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
                    onTap: _amount <= 0
                        ? null
                        : () => _updateAmount(_amount - 100),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: NeumorphicStyle.buttonDecoration(
                        context,
                        borderRadius: 20,
                        color: _amount <= 0 ? Colors.grey : AppColors.primary,
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
                          final amount = double.tryParse(value) ?? 0.0;
                          setState(() {
                            _amount = amount;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: _amount >= _maxPayable
                        ? null
                        : () => _updateAmount(_amount + 100),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: NeumorphicStyle.buttonDecoration(
                        context,
                        borderRadius: 20,
                        color: _amount >= _maxPayable
                            ? Colors.grey
                            : AppColors.primary,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Max payable: ₹${_maxPayable.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _amount > _maxPayable
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
                        color: AppColors.primary.withAlpha(26),
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
                        color: AppColors.primary.withAlpha(26),
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
                height: 300,
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
                  onTap: _shareQrCode,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
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
                  color: AppColors.primary.withAlpha(128),
                  style: BorderStyle.solid,
                ),
              ),
              child: _receiptImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FutureBuilder<Uint8List>(
                        future: _receiptImage!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
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
          const SizedBox(height: 12),
          // Warning & Confirmation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withAlpha(77)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ensure uploaded receipt matches ₹${_amount.toStringAsFixed(0)}. Incorrect receipts will be rejected.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textPrimary(context),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _receiptConfirmed,
            onChanged: (val) {
              setState(() {
                _receiptConfirmed = val ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'I confirm the receipt is correct',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary(context),
              ),
            ),
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_amount > 0 && _receiptImage != null && _receiptConfirmed)
                  ? () => _submitPayment(isQr: true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey.withAlpha(50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                _amount <= 0 ? 'No Payment Due' : 'Submit Payment',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      (_amount > 0 &&
                          _receiptImage != null &&
                          _receiptConfirmed)
                      ? Colors.white
                      : AppColors.textSecondaryLight,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.construction_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Coming Soon',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We are currently upgrading our UPI payment gateway to ensure smoother transactions. Please use QR Scan for now.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _paymentMethodIndex = 0; // Switch to QR Scan
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Switch to QR Scan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
              color: Colors.orange.withAlpha(26),
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
