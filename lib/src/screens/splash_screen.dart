import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Fade in content
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    // Slide up text
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();

    // Navigate after animation + buffer
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      final user = await _authService.getUser();

      // Check for Admin/Manager Bypass
      if (user != null && user['id'] == 'admin_bypass') {
        // Retrieve persisted password
        final prefs =
            await SharedPreferences.getInstance(); // Import shared_preferences if needed
        final password = prefs.getString('bypass_password');
        final email = user['email'];

        if (password != null && email != null) {
          if (mounted) {
            String targetUrl = 'https://prasanna-caterers.vercel.app/login';
            if (email == 'admin@famt.com') {
              // Changed to /admin/orders
              targetUrl = 'https://prasanna-caterers.vercel.app/admin/orders';
            }

            context.go(
              '/web-login',
              extra: {
                'email': email,
                'password': password,
                'targetUrl': targetUrl,
              },
            );
          }
          return;
        } else {
          // If manager/admin but password is lost (key not found), force re-login
          if (mounted) {
            // Optional: Clear session? AuthService().logout() might be needed but sync is tricky here.
            // Just sending to login will let them overwrite the session on next successful login.
            context.go('/login');
          }
          return;
        }
      }

      if (mounted) context.go('/home');
    } else {
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF5F7FA), // Very subtle grey-blue
                ],
              ),
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                // Use Lottie if available and looks good, otherwise fallback to premium image animation
                // Assuming famt_logo_animated.json exists and is good quality.
                // If it fails or looks bad, we can revert to the image scale.
                SizedBox(
                  height: 250,
                  width: 250,
                  child: Lottie.asset(
                    'assets/lottie/famt_logo_animated.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to static image if lottie fails
                      return Image.asset(
                        'assets/images/logo-removebg.png',
                        width: 180,
                        height: 180,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // App Name with specialized gradient text style
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Prasanna Caterers',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0A1D56),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Finolex Academy',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B), // Slate 500
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Loading Animation
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Lottie.asset(
                      'assets/lottie/loading animation.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Serving Quality...',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8), // Slate 400
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
