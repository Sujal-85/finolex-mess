import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';

class SoftAskDialog extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onDecline;

  const SoftAskDialog({
    super.key,
    required this.onAllow,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 30),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie Animation for Notifications
              Lottie.asset(
                'assets/lottie/bell_notification.json',
                height: 120,
                repeat: true,
              ),

              const SizedBox(height: 12),

              Text(
                'Don\'t Miss a Meal!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Enable notifications to receive daily meal reminders, menu updates, and important announcements.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary(context),
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: onAllow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: NeumorphicStyle.buttonDecoration(
                        context,
                        color: AppColors.primary,
                        borderRadius: 15,
                      ),
                      child: Center(
                        child: Text(
                          'Notify Me',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onDecline,
                    child: Center(
                      child: Text(
                        'Maybe Later',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
