import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';

class ReceiptCard extends StatefulWidget {
  final Transaction transaction;
  final Future<void> Function()? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onView;

  const ReceiptCard({
    super.key,
    required this.transaction,
    this.onDownload,
    this.onShare,
    this.onView,
  });

  @override
  State<ReceiptCard> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends State<ReceiptCard> {
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    if (widget.onDownload == null) return;

    setState(() => _isDownloading = true);
    try {
      await widget.onDownload!();
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 20),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAYMENT RECEIPT',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${widget.transaction.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(widget.transaction.date),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PAID',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Manager Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manager',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mr. Sandeep Tambe',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(
                    'assets/images/manager_signature.png',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'Signed',
                      style: GoogleFonts.greatVibes(
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 1,
                    width: 80,
                    color: AppColors.textSecondaryLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Authorized Signature',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (widget.onDownload != null ||
              widget.onShare != null ||
              widget.onView != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.onDownload != null)
                  _buildActionButton(
                    icon: Icons.download_rounded,
                    label: 'Download',
                    onTap: _handleDownload,
                    isLoading: _isDownloading,
                  ),
                if (widget.onShare != null)
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: widget.onShare!,
                  ),
                if (widget.onView != null)
                  _buildActionButton(
                    icon: Icons.visibility_rounded,
                    label: 'Preview',
                    onTap: widget.onView!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else
              Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
