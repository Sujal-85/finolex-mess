import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../widgets/profile_style_header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          ProfileStyleHeader(
            title: 'Privacy Policy',
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
                    'Data Collection',
                    'We collect information you provide directly to us, such as when you create an account, update your profile, or communicate with us. This includes your name, email, phone number, and hostel details.',
                  ),
                  _buildSection(
                    'Use of Information',
                    'We use the information we collect to provide, maintain, and improve our services, such as processing payments, managing mess attendance, and sending important notifications.',
                  ),
                  _buildSection(
                    'Data Security',
                    'We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction.',
                  ),
                  _buildSection(
                    'Changes to Policy',
                    'We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page.',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Last updated: December 2025',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight,
                      fontStyle: FontStyle.italic,
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
              color: AppColors
                  .textSecondaryLight, // Using textSecondaryLight which is likely grey
            ),
          ),
        ],
      ),
    );
  }
}
