import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  // Filter states
  bool _showFilters = false;
  DateTimeRange? _dateRange;
  String? _selectedPaymentType;
  String? _selectedStatus;

  // Services
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();

  // Transaction data
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _refreshAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final user = await _authService.getUser();
      if (user != null && user['_id'] != null) {
        final history = await _paymentService.fetchTransactionHistory(
          user['_id'],
        );
        setState(() {
          _transactions = history
              .map(
                (data) => Transaction(
                  id: data['razorpayOrderId'] ?? 'Unknown',
                  amount: (data['amount'] ?? 0).toDouble(),
                  date: DateTime.parse(data['date']),
                  paymentMethod: 'Online', // Default for Razorpay
                  status: data['status'] ?? 'Pending',
                ),
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _applyFilters() {
    // In a real app, this would filter the transactions
    setState(() {
      _showFilters = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _selectedPaymentType = null;
      _selectedStatus = null;
    });
  }

  void _downloadReceipt(Transaction transaction) {
    // In a real app, this would download the receipt
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt downloaded successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _openReceipt(Transaction transaction) {
    // Using root navigator to ensure proper context management
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ReceiptModal(transaction: transaction);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        title: Text(
          'Transaction History',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary(context),
          ),
          onPressed: () {
            // Navigate to the home screen when back button is pressed
            context.go('/home');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt_off : Icons.filter_alt,
              color: AppColors.textPrimary(context),
            ),
            onPressed: _toggleFilters,
          ),
          IconButton(
            icon: Icon(
              Icons.download_outlined,
              color: AppColors.textPrimary(context),
            ),
            onPressed: () {
              // Download all transactions
            },
          ),
        ],
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshController.forward().then((_) {
            _refreshController.reset();
          });
          // Refresh logic
          await _fetchTransactions();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Filters panel
              if (_showFilters) _buildFiltersPanel(),

              // Transaction list
              _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),

          // Date Range
          Text(
            'Date Range',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _dateRange = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: NeumorphicStyle.cardDecoration(
                context,
                borderRadius: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dateRange == null
                        ? 'Select Date Range'
                        : '${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Type Chips
          Text(
            'Payment Type',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('UPI', _selectedPaymentType == 'UPI'),
              _buildChip('Card', _selectedPaymentType == 'Card'),
              _buildChip('Net Banking', _selectedPaymentType == 'Net Banking'),
              _buildChip('Refunds', _selectedPaymentType == 'Refunds'),
            ],
          ),
          const SizedBox(height: 16),

          // Status Chips
          Text(
            'Status',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip('Success', _selectedStatus == 'Success'),
              _buildStatusChip('Pending', _selectedStatus == 'Pending'),
              _buildStatusChip('Failed', _selectedStatus == 'Failed'),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _clearFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: NeumorphicStyle.cardDecoration(
                      context,
                      borderRadius: 16,
                    ),
                    child: Center(
                      child: Text(
                        'Clear',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _applyFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: NeumorphicStyle.buttonDecoration(
                      context,
                      borderRadius: 16,
                      color: AppColors.primary,
                    ),
                    child: Center(
                      child: Text(
                        'Apply',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentType = isSelected ? null : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: NeumorphicStyle.cardDecoration(
          context,
          borderRadius: 20,
          shadowIntensity: isSelected ? 0.2 : 0.1,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isSelected) {
    Color color;
    switch (label) {
      case 'Success':
        color = AppColors.success;
        break;
      case 'Pending':
        color = AppColors.warning;
        break;
      case 'Failed':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondaryLight;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = isSelected ? null : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: NeumorphicStyle.cardDecoration(
          context,
          borderRadius: 20,
          shadowIntensity: isSelected ? 0.2 : 0.1,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? color : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactions.isEmpty) {
      return _buildEmptyState();
    }

    // Group transactions by date
    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in _transactions) {
      String dateGroup = _getDateGroup(transaction.date);
      if (groupedTransactions.containsKey(dateGroup)) {
        groupedTransactions[dateGroup]!.add(transaction);
      } else {
        groupedTransactions[dateGroup] = [transaction];
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedTransactions.keys.length,
      itemBuilder: (context, index) {
        String dateGroup = groupedTransactions.keys.elementAt(index);
        List<Transaction> transactions = groupedTransactions[dateGroup]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date group header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                dateGroup,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            // Transactions for this date group
            Column(
              children: transactions.map((transaction) {
                return _buildTransactionCard(transaction);
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return GestureDetector(
      onTap: () => _openReceipt(transaction),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 20),
        child: Column(
          children: [
            Row(
              children: [
                // Payment method icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getPaymentMethodIcon(transaction.paymentMethod),
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${transaction.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                transaction.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              transaction.status,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(transaction.status),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('hh:mm a').format(transaction.date),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondaryLight,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Additional details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.id,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  transaction.paymentMethod,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: AppColors.textSecondaryLight.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Transactions Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'UPI':
        return Icons.account_balance_wallet_outlined;
      case 'Card':
        return Icons.credit_card_outlined;
      case 'Net Banking':
        return Icons.account_balance_outlined;
      case 'Wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Success':
        return AppColors.success;
      case 'Pending':
        return AppColors.warning;
      case 'Failed':
        return AppColors.error;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final thisWeek = DateTime(now.year, now.month, now.day - 7);

    if (date.isAfter(today)) {
      return 'Today';
    } else if (date.isAfter(yesterday)) {
      return 'Yesterday';
    } else if (date.isAfter(thisWeek)) {
      return 'This Week';
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }
}

class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String status;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.status,
  });
}

class ReceiptModal extends StatelessWidget {
  final Transaction transaction;

  const ReceiptModal({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Receipt',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textSecondaryLight),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // College branding
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicStyle.cardDecoration(
              context,
              borderRadius: 20,
            ),
            child: Column(
              children: [
                Icon(Icons.school, size: 40, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  'FAMT Mess',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Amount and details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicStyle.cardDecoration(
              context,
              borderRadius: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${transaction.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(context, 'Transaction ID', transaction.id),
                _buildDetailRow(
                  context,
                  'Date & Time',
                  DateFormat('MMM dd, yyyy hh:mm a').format(transaction.date),
                ),
                _buildDetailRow(
                  context,
                  'Payment Method',
                  transaction.paymentMethod,
                ),
                _buildDetailRow(
                  context,
                  'Status',
                  transaction.status,
                  isStatus: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // QR Code placeholder
          Center(
            child: Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.qr_code, size: 80, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Close the modal bottom sheet first
                    Navigator.of(context).pop();
                    // Navigate to receipt preview screen
                    context.push(
                      '/receipt-preview',
                      extra: {
                        'transactionId': transaction.id,
                        'amount': transaction.amount,
                        'dateTime': transaction.date,
                        'paymentMethod': transaction.paymentMethod,
                        'referenceId': 'REF1234567890',
                        'studentName': 'John Doe',
                        'hostelBlock': 'A',
                        'roomNumber': '101',
                        'messType': 'Vegetarian',
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: NeumorphicStyle.cardDecoration(
                      context,
                      borderRadius: 20,
                    ),
                    child: Center(
                      child: Text(
                        'Share',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Close the modal bottom sheet first
                    Navigator.of(context).pop();
                    // Navigate to receipt preview screen
                    context.push(
                      '/receipt-preview',
                      extra: {
                        'transactionId': transaction.id,
                        'amount': transaction.amount,
                        'dateTime': transaction.date,
                        'paymentMethod': transaction.paymentMethod,
                        'referenceId': 'REF1234567890',
                        'studentName': 'John Doe',
                        'hostelBlock': 'A',
                        'roomNumber': '101',
                        'messType': 'Vegetarian',
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: NeumorphicStyle.buttonDecoration(
                      context,
                      borderRadius: 20,
                      color: AppColors.primary,
                    ),
                    child: Center(
                      child: Text(
                        'Download PDF',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isStatus = false,
  }) {
    Color? valueColor;
    if (isStatus) {
      switch (value) {
        case 'Success':
          valueColor = AppColors.success;
          break;
        case 'Pending':
          valueColor = AppColors.warning;
          break;
        case 'Failed':
          valueColor = AppColors.error;
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
