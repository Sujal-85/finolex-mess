import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin, CodeAutoFill {
  final TextEditingController _collegeIdController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  bool _showOtp = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    listenForCode(); // SMS AutoFill
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 4) {
      _otpController.text = code!;
      _verifyOtp();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    cancel();
    _collegeIdController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _requestOtp() {
    HapticFeedback.mediumImpact();
    final collegeId = _collegeIdController.text.trim();
    if (collegeId.isEmpty || !collegeId.contains('@')) {
      setState(() => _errorMessage = 'Enter a valid college email/ID');
      return;
    }
    setState(() => _errorMessage = null);
    context.read<AuthBloc>().add(OtpRequested(collegeId: collegeId));
  }

  void _verifyOtp() {
    HapticFeedback.heavyImpact();
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      setState(() => _errorMessage = 'OTP must be 4 digits');
      return;
    }
    context.read<AuthBloc>().add(
      LoginRequested(collegeId: _collegeIdController.text.trim(), otp: otp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpSent) {
            setState(() {
              _showOtp = true;
              _errorMessage = null;
            });
            _slideController.forward(from: 0);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary.withOpacity(0.9),
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'OTP Sent! Check your phone (Dev: 1234)',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          } else if (state is AuthAuthenticated) {
            // Check if user needs registration
            if (state.needsRegistration) {
              context.go('/register');
            } else {
              context.go('/home');
            }
          } else if (state is AuthFailure) {
            setState(() => _errorMessage = state.message);
            HapticFeedback.vibrate();
          }
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Logo + Animation
                  // Center(
                  //   child: Lottie.asset(
                  //     'assets/lottie/party propper.json', // Placeholder for broken logo
                  //     height: 140,
                  //     fit: BoxFit.contain,
                  //     repeat: false,
                  //   ),
                  // ),
                  // const SizedBox(height: 32),

                  // Welcome Text
                  Text(
                    'Welcome Back!',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your college credentials',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // College ID Field
                  _buildNeumorphicTextField(
                    controller: _collegeIdController,
                    hint: 'College Email / ID',
                    icon: Icons.school_rounded,
                    enabled: !_showOtp,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // OTP Field (Animated Slide In)
                  if (_showOtp)
                    SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: _buildNeumorphicTextField(
                          controller: _otpController,
                          hint: 'Enter 4-digit OTP',
                          icon: Icons.lock_outline_rounded,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          autofocus: true,
                        ),
                      ),
                    ),

                  // Error Message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.roboto(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 48),

                  // Main Action Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;

                      return GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                _showOtp ? _verifyOtp() : _requestOtp();
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: NeumorphicStyle.buttonDecoration(
                            context,
                            color: isLoading
                                ? AppColors.primary.withOpacity(0.7)
                                : AppColors.primary,
                            isPressed: isLoading,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  _showOtp ? 'Verify & Continue' : 'Send OTP',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Footer Hint
                  Center(
                    child: Text(
                      'Powered by Prasanna Caterers',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int? maxLength,
    bool autofocus = false,
  }) {
    return Container(
      decoration: NeumorphicStyle.cardDecoration(
        context,
        borderRadius: 20,
        shadowIntensity: enabled ? 0.15 : 0.05,
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        autofocus: autofocus,
        maxLength: maxLength,
        textAlign: TextAlign.start,
        style: GoogleFonts.roboto(fontSize: 16),
        inputFormatters: maxLength != null
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.roboto(
            color: AppColors.textSecondaryLight.withOpacity(0.5),
          ),
          prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        onSubmitted: (_) => _showOtp ? _verifyOtp() : _requestOtp(),
      ),
    );
  }
}
