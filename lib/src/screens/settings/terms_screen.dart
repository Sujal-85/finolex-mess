import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../widgets/profile_style_header.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          ProfileStyleHeader(
            title: 'Terms of Service',
            showBackButton: true,
            onBackTap: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Acceptance of Terms',
                    'By accessing or using the FAMT Mess App, you agree to be bound by these Terms of Service and all applicable laws and regulations.',
                  ),
                  _buildSection(
                    'User Accounts',
                    'You are responsible for maintaining the confidentiality of your account credentials and for any activities that occur under your account.',
                  ),
                  _buildSection(
                    'Payment Terms',
                    'All payments made through the app are processed securely. Refunds are subject to the canteen management policy.',
                  ),
                  _buildSection(
                    'Prohibited Conduct',
                    'You agree not to use the app for any unlawful purpose or to violate any laws in your jurisdiction.',
                  ),
                  _buildSection(
                    'Limitation of Liability',
                    'The developers and canteen management shall not be liable for any indirect, incidental, special, consequential or punitive damages.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
