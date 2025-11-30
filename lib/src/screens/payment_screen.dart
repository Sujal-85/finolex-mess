import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/animations/famt_loader.dart';
import '../widgets/animations/success_confetti.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _bankSearchController = TextEditingController();

  // Animation controllers
  late AnimationController _headerController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late AnimationController _cardController;
  late Animation<double> _cardFadeAnimation;
  late Animation<Offset> _cardSlideAnimation;

  // State variables
  int _selectedPaymentMethod = 0; // 0: UPI, 1: Card, 2: Net Banking
  double _amount = 100.0;
  bool _saveCard = false;
  bool _isProcessing = false;
  bool _showSuccess = false;
  String _selectedBank = '';
  String _selectedQuickUpi = '';

  // Mock data
  final List<String> _savedUpiIds = ['john@upi', 'john@paytm', 'john@gpay'];
  final List<Map<String, dynamic>> _banks = [
    {
      'name': 'State Bank of India',
      'code': 'SBI',
      'icon': Icons.account_balance,
    },
    {'name': 'HDFC Bank', 'code': 'HDFC', 'icon': Icons.account_balance},
    {'name': 'ICICI Bank', 'code': 'ICICI', 'icon': Icons.account_balance},
    {'name': 'Axis Bank', 'code': 'AXIS', 'icon': Icons.account_balance},
    {
      'name': 'Kotak Mahindra Bank',
      'code': 'KOTAK',
      'icon': Icons.account_balance,
    },
  ];

  // Services
  late PaymentService _paymentService;
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _paymentService.init(
      _handlePaymentSuccess,
      _handlePaymentError,
      _handleExternalWallet,
    );
    _fetchUser();

    _amountController.text = _amount.toStringAsFixed(2);

    // Initialize animations
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardFadeAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );

    _cardSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cardController.forward();
    });
  }

  Future<void> _fetchUser() async {
    final user = await _authService.getUser();
    setState(() {
      _user = user;
    });
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _amountController.dispose();
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    _bankSearchController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _paymentService
        .verifyPayment(
          orderId: response.orderId!,
          paymentId: response.paymentId!,
          signature: response.signature!,
          studentId: _user?['id'] ?? _user?['_id'] ?? '',
          amount: _amount,
        )
        .then((_) {
          setState(() {
            _isProcessing = false;
            _showSuccess = true;
          });

          // Hide success animation after delay
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) {
              setState(() {
                _showSuccess = false;
              });
              context.pop(); // Go back after success
            }
          });
        })
        .catchError((e) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment Verification Failed: $e')),
          );
        });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  void _updateAmount(double newAmount) {
    setState(() {
      _amount = newAmount < 10 ? 10 : newAmount;
      _amountController.text = _amount.toStringAsFixed(2);
    });
  }

  void _selectPaymentMethod(int index) {
    setState(() {
      _selectedPaymentMethod = index;
    });
  }

  void _payNow() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _paymentService.openCheckout(
        amount: _amount,
        studentId: _user?['id'] ?? _user?['_id'] ?? '',
        email: _user?['email'] ?? '',
        contact: _user?['phone'] ?? '',
        description: 'Canteen Wallet Top-up',
        vpa: _upiIdController.text.isNotEmpty ? _upiIdController.text : null,
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error initiating payment: $e')));
    }
  }

  void _scanQr() {
    // In a real app, this would open the camera to scan QR
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR scanner would open here'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Make Payment',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '₹1,250.75',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Payment amount section
                _buildPaymentAmountSection(),

                const SizedBox(height: 24),

                // Payment method tabs
                _buildPaymentMethodTabs(),

                const SizedBox(height: 24),

                // Payment method content
                _buildPaymentMethodContent(),

                const SizedBox(height: 24),

                // CTA buttons
                _buildCtaButtons(),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(child: FamtLoader()),
            ),

          // Success overlay
          if (_showSuccess)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: SuccessConfetti(
                  onCompleted: () {
                    setState(() {
                      _showSuccess = false;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentAmountSection() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Amount',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 20),

              // Amount display
              Center(
                child: Text(
                  '₹${_amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Amount adjustment
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Minus button
                  GestureDetector(
                    onTap: () => _updateAmount(_amount - 10),
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

                  // Amount input
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
                          final amount = double.tryParse(value) ?? 10.0;
                          setState(() {
                            _amount = amount < 10 ? 10 : amount;
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Plus button
                  GestureDetector(
                    onTap: () => _updateAmount(_amount + 10),
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

              // Subtext
              Center(
                child: Text(
                  'Minimum ₹10 | No convenience fee',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Dotted divider
              const Divider(
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTabs() {
    final tabs = ['UPI', 'Card', 'Net Banking'];

    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = _selectedPaymentMethod == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _selectPaymentMethod(index),
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 4 : 0,
                      right: index == tabs.length - 1 ? 4 : 0,
                    ),
                    decoration: isSelected
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: AppColors.primary.withOpacity(0.1),
                          )
                        : null,
                    child: Center(
                      child: Text(
                        tabs[index],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodContent() {
    switch (_selectedPaymentMethod) {
      case 0:
        return _buildUpiPaymentSection();
      case 1:
        return _buildCardPaymentSection();
      case 2:
        return _buildNetBankingSection();
      default:
        return _buildUpiPaymentSection();
    }
  }

  Widget _buildUpiPaymentSection() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPI ID',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),

              // UPI ID input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: NeumorphicStyle.cardDecoration(
                  context,
                  borderRadius: 20,
                ),
                child: TextField(
                  controller: _upiIdController,
                  keyboardType: TextInputType.text,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter your UPI ID',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Verify UPI button
              Center(
                child: GestureDetector(
                  onTap: () {
                    // In a real app, this would verify the UPI ID
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: NeumorphicStyle.buttonDecoration(
                      context,
                      borderRadius: 20,
                      color: AppColors.primary,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Verify UPI',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Quick options
              Text(
                'Quick Options',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),

              // Quick UPI options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickUpiOption(
                    'GPay',
                    Icons.account_balance_wallet,
                    'gpay',
                  ),
                  _buildQuickUpiOption(
                    'PhonePe',
                    Icons.account_balance_wallet,
                    'phonepe',
                  ),
                  _buildQuickUpiOption(
                    'Paytm',
                    Icons.account_balance_wallet,
                    'paytm',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Saved UPI IDs
              if (_savedUpiIds.isNotEmpty) ...[
                Text(
                  'Saved UPI IDs',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: _savedUpiIds.map((upiId) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _upiIdController.text = upiId;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: NeumorphicStyle.cardDecoration(
                          context,
                          borderRadius: 20,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              upiId,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Scan QR button
              Center(
                child: GestureDetector(
                  onTap: _scanQr,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: NeumorphicStyle.cardDecoration(
                      context,
                      borderRadius: 20,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scan QR Instead',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
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

  Widget _buildQuickUpiOption(String name, IconData icon, String id) {
    final isSelected = _selectedQuickUpi == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedQuickUpi = isSelected ? '' : id;
        });
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: NeumorphicStyle.cardDecoration(
          context,
          borderRadius: 20,
          shadowIntensity: isSelected ? 0.2 : 0.1,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondaryLight,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPaymentSection() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card preview
              Container(
                height: 180,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Card logos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 30,
                        ),
                        Text(
                          'VISA',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // Card number
                    Text(
                      _cardNumberController.text.isEmpty
                          ? '**** **** **** ****'
                          : _formatCardNumber(_cardNumberController.text),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),

                    // Card details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Card Holder',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              _cardNameController.text.isEmpty
                                  ? 'YOUR NAME'
                                  : _cardNameController.text.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expires',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              _expiryController.text.isEmpty
                                  ? 'MM/YY'
                                  : _expiryController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Card Number
              Text(
                'Card Number',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: NeumorphicStyle.cardDecoration(
                  context,
                  borderRadius: 20,
                ),
                child: TextField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '1234 5678 9012 3456',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.credit_card_outlined,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    setState(() {}); // Trigger rebuild for card preview
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Expiry and CVV
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expiry Date',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: NeumorphicStyle.cardDecoration(
                            context,
                            borderRadius: 20,
                          ),
                          child: TextField(
                            controller: _expiryController,
                            keyboardType: TextInputType.datetime,
                            maxLength: 5,
                            style: GoogleFonts.poppins(fontSize: 16),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'MM/YY',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppColors.textSecondaryLight.withOpacity(
                                  0.7,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: AppColors.primary.withOpacity(0.7),
                              ),
                              counterText: '',
                            ),
                            onChanged: (value) {
                              setState(
                                () {},
                              ); // Trigger rebuild for card preview
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CVV',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: NeumorphicStyle.cardDecoration(
                            context,
                            borderRadius: 20,
                          ),
                          child: TextField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            obscureText: true,
                            style: GoogleFonts.poppins(fontSize: 16),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '123',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppColors.textSecondaryLight.withOpacity(
                                  0.7,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.primary.withOpacity(0.7),
                              ),
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cardholder Name
              Text(
                'Cardholder Name',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: NeumorphicStyle.cardDecoration(
                  context,
                  borderRadius: 20,
                ),
                child: TextField(
                  controller: _cardNameController,
                  keyboardType: TextInputType.text,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter cardholder name',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {}); // Trigger rebuild for card preview
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Save Card toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Save Card',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Switch(
                    value: _saveCard,
                    onChanged: (value) {
                      setState(() {
                        _saveCard = value;
                      });
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCardNumber(String number) {
    // Remove all non-digit characters
    final digitsOnly = number.replaceAll(RegExp(r'\D'), '');

    // Format as XXXX XXXX XXXX XXXX
    final formatted = <String>[];
    for (int i = 0; i < digitsOnly.length; i += 4) {
      final end = (i + 4 < digitsOnly.length) ? i + 4 : digitsOnly.length;
      formatted.add(digitsOnly.substring(i, end));
    }

    return formatted.join(' ');
  }

  Widget _buildNetBankingSection() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: NeumorphicStyle.cardDecoration(
                  context,
                  borderRadius: 20,
                ),
                child: TextField(
                  controller: _bankSearchController,
                  keyboardType: TextInputType.text,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search for your bank',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search_outlined,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Popular banks
              Text(
                'Popular Banks',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),

              // Bank list
              Column(
                children: _banks.map((bank) {
                  final isSelected = _selectedBank == bank['code'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBank = isSelected ? '' : bank['code'];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: NeumorphicStyle.cardDecoration(
                        context,
                        borderRadius: 20,
                        shadowIntensity: isSelected ? 0.2 : 0.1,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            bank['icon'],
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              bank['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Faster Payment badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Faster Payment Available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCtaButtons() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Pay Now button
              GestureDetector(
                onTap: _payNow,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent,
                        AppColors.accent.withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Pay Now',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // View Payment History button
              GestureDetector(
                onTap: () => context.push('/history'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: NeumorphicStyle.cardDecoration(
                    context,
                    borderRadius: 25,
                  ),
                  child: Center(
                    child: Text(
                      'View Payment History',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary(context),
                      ),
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
}
