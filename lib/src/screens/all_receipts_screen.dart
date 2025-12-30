import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../widgets/profile_style_header.dart';
import 'receipt_preview_screen.dart';
import '../services/receipt_service.dart';
import '../services/local_notification_service.dart';
import '../models/transaction.dart';
import '../widgets/receipt_card.dart';

class AllReceiptsScreen extends StatefulWidget {
  const AllReceiptsScreen({super.key});

  @override
  State<AllReceiptsScreen> createState() => _AllReceiptsScreenState();
}

class _AllReceiptsScreenState extends State<AllReceiptsScreen> {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  final ReceiptService _receiptService = ReceiptService();

  List<Transaction> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReceipts();
  }

  Future<void> _fetchReceipts() async {
    try {
      final user = await _authService.getUser();
      if (user != null && user['_id'] != null) {
        final history = await _paymentService.fetchTransactionHistory(
          user['_id'],
        );
        setState(() {
          double totalPaid = 0.0;
          DateTime? latestDate;

          final validTransactions = history.where((d) {
            final status = d['status'] as String?;
            return status == 'Completed' ||
                status == 'Success' ||
                status == 'Approved';
          }).toList();

          // Calculate total paid and find latest date
          for (var t in validTransactions) {
            final amount = (t['amount'] as num).toDouble();
            totalPaid += amount;
            final date = DateTime.parse(t['date']);
            if (latestDate == null || date.isAfter(latestDate)) {
              latestDate = date;
            }
          }

          // Create base list of receipts
          _receipts = history
              .map(
                (data) => Transaction(
                  id: data['razorpayOrderId'] ?? 'Unknown',
                  amount: (data['amount'] ?? 0).toDouble(),
                  date: DateTime.parse(data['date']),
                  paymentMethod: data['upiId'] != null ? 'UPI' : 'Online',
                  status: data['status'] ?? 'Pending',
                  upiId: data['upiId'],
                ),
              )
              .where(
                (t) =>
                    (t.status == 'Completed' ||
                        t.status == 'Success' ||
                        t.status == 'Approved') &&
                    t.amount >=
                        3400, // Keep showing individual full payments if they exist
              )
              .toList();

          // Add Consolidated Receipt if total is sufficient and we don't have a single full receipt covering it
          // OR user wants to see a specific "Total Mess Payment" card regardless.
          // The prompt says "once total mess payment is complete then same kind of receipt will be generated for total payment".
          if (totalPaid >= 3400) {
            // Check if we already have a full receipt in the list to avoid duplicates?
            // Actually, if I paid 1500 + 2000, I have 2 small receipts (not shown individually here as I filtered them out with >= 3400).
            // But I want a TOTAL receipt.
            // If I paid 3500 in one go, I have 1 receipt of 3500.
            // The logic below ensures we have at least one representing the total.

            final hasFullReceipt = _receipts.any((t) => t.amount >= 3400);

            if (!hasFullReceipt) {
              _receipts.add(
                Transaction(
                  id: 'TOTAL-PAID-${latestDate?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}', // Synthetic ID
                  amount: totalPaid,
                  date: latestDate ?? DateTime.now(),
                  paymentMethod: 'Consolidated',
                  status: 'Success',
                  upiId: 'N/A',
                ),
              );
            }
          }

          // Sort by date desc
          _receipts.sort((a, b) => b.date.compareTo(a.date));

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching receipts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadReceipt(Transaction transaction) async {
    try {
      final user = await _authService.getUser();
      if (user == null) return;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saving Receipt...')));
      }

      final file = await _receiptService.saveReceiptFile(transaction, user);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt saved Successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Show Local Notification
      await LocalNotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Receipt Downloaded',
        body: 'Receipt saved successfully.',
      );
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download receipt'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareReceipt(Transaction transaction) async {
    try {
      final user = await _authService.getUser();
      if (user == null) return;
      await _receiptService.shareReceipt(transaction, user);
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _viewReceipt(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReceiptPreviewScreen(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          const ProfileStyleHeader(title: 'All Receipts'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _receipts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _receipts.length,
                    itemBuilder: (context, index) {
                      final transaction = _receipts[index];
                      return ReceiptCard(
                        transaction: transaction,
                        onDownload: () => _downloadReceipt(transaction),
                        onShare: () => _shareReceipt(transaction),
                        onView: () => _viewReceipt(transaction),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/lottie/No Data Animation.json',
            height: 180,
            repeat: false,
          ),
          const SizedBox(height: 16),
          Text(
            'No Receipts Found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          Text(
            'Only completed payments appear here',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
