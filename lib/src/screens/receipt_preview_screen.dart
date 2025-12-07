import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> receiptData;

  const ReceiptPreviewScreen({super.key, this.receiptData = const {}});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary(context),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Receipt Preview',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Paper-style receipt card
            _buildReceiptCard(context),

            const SizedBox(height: 30),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section
          _buildHeaderSection(context),

          // Perforation line
          _buildPerforationLine(),

          // Payment summary
          _buildPaymentSummary(context),

          // Perforation line
          _buildPerforationLine(),

          // Stamp and QR section
          _buildStampAndQrSection(context),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [
          // College logo and branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.school_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FAMT Mess App',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    'by Prasanna Caterers',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Title and transaction ID
          Text(
            'Payment Receipt',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'TXN #${receiptData['transactionId'] ?? 'FAMT7821'}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.textSecondaryLight.withOpacity(0.3),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerforationLine() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondaryLight.withOpacity(0.2),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            context,
            Icons.currency_rupee_outlined,
            'Amount Paid',
            '₹${receiptData['amount'] ?? '150.00'}',
            isBold: true,
            isLarge: true,
          ),

          const SizedBox(height: 18),

          _buildDetailRow(
            context,
            Icons.calendar_today_outlined,
            'Date & Time',
            DateFormat(
              'dd MMM yyyy, hh:mm a',
            ).format(receiptData['dateTime'] ?? DateTime.now()),
          ),

          const SizedBox(height: 18),

          _buildDetailRow(
            context,
            Icons.payment_outlined,
            'Payment Method',
            receiptData['paymentMethod'] ?? 'UPI',
          ),

          const SizedBox(height: 18),

          _buildDetailRow(
            context,
            Icons.confirmation_number_outlined,
            'Reference ID',
            receiptData['referenceId'] ?? 'REF1234567890',
          ),

          const SizedBox(height: 18),

          _buildDetailRow(
            context,
            Icons.person_outlined,
            'Student Name',
            receiptData['studentName'] ?? 'John Doe',
          ),

          const SizedBox(height: 18),

          _buildDetailRow(
            context,
            Icons.apartment_outlined,
            'Hostel Block / Room',
            '${receiptData['hostelBlock'] ?? 'A'} / ${receiptData['roomNumber'] ?? '101'}',
          ),

          const SizedBox(height: 18),

          _buildDetailRow(
            context,
            Icons.restaurant_outlined,
            'Mess Type',
            receiptData['messType'] ?? 'Vegetarian',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isLarge ? 20 : 18,
          color: AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: isLarge ? 16 : 14,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: isLarge ? 24 : 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStampAndQrSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [
          // Digital stamp
          Transform.rotate(
            angle: -0.1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'PAID',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondaryLight.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code, size: 80, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          'Scan to Verify',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Scan to Verify Payment',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Download PDF button
        GestureDetector(
          onTap: () {
            if (receiptData['status']?.toString().toLowerCase() != 'success' &&
                receiptData['status']?.toString().toLowerCase() != 'paid') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Receipt can only be downloaded for approved transactions.',
                  ),
                  backgroundColor: AppColors.warning,
                ),
              );
              return;
            }
            // In a real app, this would download the PDF
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Receipt downloaded as PDF'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient:
                  (receiptData['status']?.toString().toLowerCase() ==
                          'success' ||
                      receiptData['status']?.toString().toLowerCase() == 'paid')
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppColors.textSecondaryLight.withOpacity(0.3),
                        AppColors.textSecondaryLight.withOpacity(0.3),
                      ],
                    ),
              boxShadow:
                  (receiptData['status']?.toString().toLowerCase() ==
                          'success' ||
                      receiptData['status']?.toString().toLowerCase() == 'paid')
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                'Download PDF',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Share Receipt button
        GestureDetector(
          onTap: () {
            if (receiptData['status']?.toString().toLowerCase() != 'success' &&
                receiptData['status']?.toString().toLowerCase() != 'paid') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Receipt can only be shared for approved transactions.',
                  ),
                  backgroundColor: AppColors.warning,
                ),
              );
              return;
            }
            // In a real app, this would share the receipt
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Receipt shared successfully'),
                backgroundColor: AppColors.accent,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: NeumorphicStyle.cardDecoration(
              context,
              borderRadius: 25,
            ),
            child: Center(
              child: Text(
                'Share Receipt',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color:
                      (receiptData['status']?.toString().toLowerCase() ==
                              'success' ||
                          receiptData['status']?.toString().toLowerCase() ==
                              'paid')
                      ? AppColors.textPrimary(context)
                      : AppColors.textSecondaryLight.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
