import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';

class PlanDetailsDialog extends StatefulWidget {
  final String messType;
  final double messFee;

  const PlanDetailsDialog({
    super.key,
    required this.messType,
    this.messFee = 3500.0,
  });

  @override
  State<PlanDetailsDialog> createState() => _PlanDetailsDialogState();
}

class _PlanDetailsDialogState extends State<PlanDetailsDialog> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getValidityPeriod() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    // Format: "1st Dec - 31st Dec"
    String daySuffix(int day) {
      if (day >= 11 && day <= 13) return 'th';
      switch (day % 10) {
        case 1:
          return 'st';
        case 2:
          return 'nd';
        case 3:
          return 'rd';
        default:
          return 'th';
      }
    }

    String formatDate(DateTime date) {
      return '${date.day}${daySuffix(date.day)} ${DateFormat('MMM').format(date)}';
    }

    return '${formatDate(firstDay)} - ${formatDate(lastDay)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Mess Plan Details',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary(context),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Plan Type', widget.messType),
          const Divider(),
          _buildDetailRow(
            'Total Cost',
            '₹${widget.messFee.toStringAsFixed(0)} / month',
          ),
          const Divider(),
          _buildDetailRow('Validity', _getValidityPeriod()),
          const Divider(),
          _buildDetailRow('Status', 'Active'),
          const SizedBox(height: 16),
          Text(
            'Includes Breakfast, Lunch, and Dinner.',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(color: AppColors.textSecondaryLight),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
