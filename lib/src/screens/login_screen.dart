import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../services/local_notification_service.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _welcomeController;

  bool _isLoading = false;
  bool _showWelcome = false;
  String? _errorMessage;
  bool _obscurePassword = true;

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
    _welcomeController = AnimationController(vsync: this);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _welcomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    HapticFeedback.mediumImpact();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter Email and Password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.login(email, password);
      if (success) {
        setState(() {
          _showWelcome = true;
          _isLoading = false;
        });
        // Wait for animation to play
        await Future.delayed(
          const Duration(seconds: 3),
        ); // Adjust based on animation length
        // Show Welcome Notification
        await LocalNotificationService().showNotification(
          id: 1,
          title: 'Welcome to Prasanna Caterers! 👋',
          body: 'We are glad to have you back. Check out today\'s menu!',
        );

        if (mounted) context.go('/home');
      } else {
        setState(() => _errorMessage = 'Invalid credentials');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (context.canPop())
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 40),

                    // Login Animation
                    Center(
                      child: Lottie.asset(
                        'assets/lottie/welcome.json', // Placeholder for broken login_animation.lottie
                        height: 200,
                        repeat: true,
                        animate: true,
                        onLoaded: (composition) {
                          // Optional: Configure animation properties
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.error,
                            size: 50,
                            color: Colors.red,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

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
                      'Sign in with your Email',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: AppColors.textSecondaryLight.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    _buildNeumorphicTextField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 24),

                    // Password Field
                    _buildNeumorphicTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondaryLight,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
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

                    // Login Button
                    GestureDetector(
                      onTap: _isLoading ? null : _login,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: NeumorphicStyle.buttonDecoration(
                          context,
                          color: _isLoading
                              ? AppColors.primary.withOpacity(0.7)
                              : AppColors.primary,
                          isPressed: _isLoading,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'Login',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Register Link
                    Center(
                      child: GestureDetector(
                        onTap: () => context.push(
                          '/register',
                        ), // Assuming /register route exists
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: GoogleFonts.roboto(
                              color: AppColors.textSecondaryLight,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Register',
                                style: GoogleFonts.roboto(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
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
          ),
          if (_showWelcome)
            Container(
              color: AppColors.background(context),
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/onboarding_done.json',
                  controller: _welcomeController,
                  onLoaded: (composition) {
                    _welcomeController
                      ..duration = composition.duration * 0.8
                      ..forward();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: NeumorphicStyle.cardDecoration(
        context,
        borderRadius: 20,
        shadowIntensity: 0.15,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.roboto(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.roboto(
            color: AppColors.textSecondaryLight.withOpacity(0.5),
          ),
          prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
