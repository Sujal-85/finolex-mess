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

    // 1. Filter and Sort Unpaid Plans (Queue Logic)
    List<Map<String, dynamic>> unpaidPlans = activePlans.where((p) {
      final status = p['status']?.toString().toLowerCase();
      return status != 'paid' && status != 'Success';
    }).toList();

    // Sort by Date (Oldest First)
    unpaidPlans.sort((a, b) {
      DateTime? d1 = DateTime.tryParse(a['startDate']?.toString() ?? '');
      DateTime? d2 = DateTime.tryParse(b['startDate']?.toString() ?? '');
      if (d1 == null) return 1;
      if (d2 == null) return -1;
      return d1.compareTo(d2);
    });

    final topPlan = unpaidPlans.isNotEmpty ? unpaidPlans.first : null;

    // 2. Determine Display Values from Top Plan
    DateTime? displayStart = startDate;
    DateTime? displayEnd = endDate;
    String displayDueDate = dueDate;

    if (topPlan != null && topPlan['startDate'] != null) {
      final sDate = DateTime.tryParse(topPlan['startDate'].toString());
      final eDate = DateTime.tryParse(topPlan['endDate'].toString());

      if (sDate != null) {
        displayStart = sDate;
        // Due Date = Start Date + 10 Days
        final calculatedDue = sDate.add(const Duration(days: 10));
        displayDueDate =
            '${calculatedDue.day}th ${_getMonthName(calculatedDue.month)}';
      }
      if (eDate != null) {
        displayEnd = eDate;
      }
    }

    // Reuse helper if needed or just format locally
    // Since we don't have intl here easily without importing, simple month map or just existing format style.
    // The existing code passed 'dueDate' as a string. We constructed a new string.

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

          // Display Validity from Top Plan
          if (displayStart != null) ...[
            Text(
              'Validity: ${displayStart.day}/${displayStart.month} to ${displayEnd != null ? "${displayEnd.day}/${displayEnd.month}" : "---"}',
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

          // Removed "Includes Fine" specific breakout since fine is now part of balance directly
          // We can show generic message if balance > plan price? But simplicity is preferred.
          if (unpaidPlans.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            Text(
              'Unpaid Plans Queue:',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Show Top Plan Highlighted
            ...unpaidPlans.map((plan) {
              final pName = plan['name'] ?? 'Mess Plan';
              final pPrice = plan['price'] ?? 0;
              final pStartDate = plan['startDate'];
              // If this plan matches the topPlan we identified earlier
              final isTop = topPlan == plan;

              return Container(
                margin: const EdgeInsets.only(bottom: 4.0),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: isTop
                    ? BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.2),
                        ),
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pName,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: isTop
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isTop
                                  ? AppColors.error
                                  : AppColors.textPrimary(context),
                            ),
                          ),
                          if (pStartDate != null)
                            Text(
                              'Start: ${DateTime.tryParse(pStartDate.toString())?.day}/${DateTime.tryParse(pStartDate.toString())?.month}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '₹$pPrice',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isTop
                            ? AppColors.error
                            : AppColors.textPrimary(context),
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
              'Due by $displayDueDate',
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

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
