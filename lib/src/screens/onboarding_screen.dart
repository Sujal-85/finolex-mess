import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late ConfettiController _confettiController;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      lottieAsset: 'assets/lottie/onboarding_menu.json',
      title: 'Weekly Mess Menu',
      description:
          'Never miss what\'s for breakfast, lunch, or dinner. Full week view at your fingertips!',
      gradient: [const Color(0xFF1E88E5), const Color(0xFF42A5F5)],
    ),
    OnboardingPageData(
      lottieAsset:
          'assets/lottie/onboarding_payment.json', // Placeholder for payment
      title: 'Digital Payments',
      description:
          'Pay instantly with UPI, save your IDs, scan QR codes — all inside the app!',
      gradient: [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
    ),
    OnboardingPageData(
      lottieAsset: 'assets/lottie/onboarding_feedback.json',
      title: 'Voice Your Feedback',
      description:
          'Rate meals, file complaints, track status — your voice matters!',
      gradient: [const Color(0xFF6A1B9A), const Color(0xFF9C27B0)],
    ),
    OnboardingPageData(
      lottieAsset: 'assets/lottie/onboarding_done.json',
      title: 'Welcome to FAMT Mess!',
      description:
          'Powered by Prasanna Caterers\nYour hostel life, simplified.',
      gradient: [const Color(0xFF1E88E5), const Color(0xFFFF9800)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                pageData: _pages[index],
                index: index,
                currentPage: _currentPage,
              );
            },
          ),

          // Top Skip Button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondaryLight.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Controls
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          height: 10,
                          width: _currentPage == i ? 32 : 10,
                          decoration: BoxDecoration(
                            gradient: _currentPage == i
                                ? LinearGradient(colors: _pages[i].gradient)
                                : null,
                            color: _currentPage == i
                                ? null
                                : AppColors.textSecondaryLight.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _currentPage == i
                                ? [
                                    BoxShadow(
                                      color: _pages[i].gradient.first
                                          .withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Next / Get Started Button
                    GestureDetector(
                      onTap: () {
                        if (_currentPage == _pages.length - 1) {
                          _confettiController.play();
                          Future.delayed(const Duration(milliseconds: 800), () {
                            context.go('/login');
                          });
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 18,
                        ),
                        decoration: NeumorphicStyle.buttonDecoration(
                          context,
                          color: AppColors.primary,
                          shadowIntensity: 0.3,
                          borderRadius: 30,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (_currentPage != _pages.length - 1) ...[
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.15,
              colors: const [
                Colors.blue,
                Colors.orange,
                Colors.purple,
                Colors.green,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data Class
class OnboardingPageData {
  final String lottieAsset;
  final String title;
  final String description;
  final List<Color> gradient;
  OnboardingPageData({
    required this.lottieAsset,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

// Single Page Widget with Parallax & Animations
class OnboardingPage extends StatelessWidget {
  final OnboardingPageData pageData;
  final int index;
  final int currentPage;

  const OnboardingPage({
    super.key,
    required this.pageData,
    required this.index,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final double parallax = (currentPage - index)
        .abs()
        .clamp(0.0, 1.0)
        .toDouble();
    final bool isActive = currentPage == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Spacer(),

          // Lottie Illustration with Scale & Fade
          Transform.scale(
            scale: 1.0 + (parallax * 0.1),
            child: Opacity(
              opacity: 1.0 - (parallax * 0.6),
              child: Lottie.asset(
                pageData.lottieAsset,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fitWidth,
                repeat: true,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title with Hero-like entrance
          AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 600),
            child: Text(
              pageData.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isActive ? 30 : 26,
                fontWeight: FontWeight.bold,
                height: 1.2,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: pageData.gradient,
                  ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Description
          AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 700),
            child: Text(
              pageData.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 16,
                height: 1.6,
                color: AppColors.textSecondaryLight.withOpacity(0.85),
              ),
            ),
          ),

          const Spacer(),

          // Reserve space for bottom controls
          const SizedBox(height: 150),
        ],
      ),
    );
  }
}
