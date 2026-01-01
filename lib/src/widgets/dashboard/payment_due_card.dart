import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';

class PaymentDueCard extends StatelessWidget {
  final double amount;
  final String dueDate;
  final VoidCallback onPayNow;
  final double pendingAmount;
  final int fineAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Map<String, dynamic>> activePlans;

  const PaymentDueCard({
    super.key,
    required this.amount,
    required this.dueDate,
    required this.onPayNow,
    this.pendingAmount = 0.0,
    this.fineAmount = 0,
    this.startDate,
    this.endDate,
    this.activePlans = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (amount <= 0 && pendingAmount <= 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Paid!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your mess payment is done. Enjoy your meals!',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                amount > 0
                    ? Icons.warning_amber_rounded
                    : Icons.pending_actions,
                color: amount > 0 ? AppColors.error : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount > 0 ? 'Payment Due' : 'Payment Under Review',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: amount > 0 ? AppColors.error : Colors.orange,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Total Outstanding', style: GoogleFonts.roboto(fontSize: 12)),
          const SizedBox(height: 4),
          if (startDate != null) ...[
            Text(
              'Validity: ${startDate!.day}/${startDate!.month} to ${endDate != null ? "${endDate!.day}/${endDate!.month}" : "---"}',
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${amount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          if (fineAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  'Includes ₹$fineAmount Late Fine',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (activePlans.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            Text(
              'Active Plans:',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...activePlans.map((plan) {
              final pName = plan['name'] ?? 'Mess Plan';
              final pPrice = plan['price'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(pName, style: GoogleFonts.roboto(fontSize: 12)),
                    Text(
                      '₹$pPrice',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (pendingAmount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '₹${pendingAmount.toStringAsFixed(0)} verification pending',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          if (amount > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Due by $dueDate',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onPayNow,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pay Now',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
