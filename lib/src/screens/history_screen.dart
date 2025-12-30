import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../services/receipt_service.dart';
import '../models/transaction.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/profile_style_header.dart';
import 'receipt_preview_screen.dart';
import '../services/local_notification_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  late AnimationController _lottieController;

  // Filter states
  bool _showFilters = false;
  DateTimeRange? _dateRange;
  String? _selectedPaymentType;
  String? _selectedStatus;

  // Services
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();

  // Transaction data
  List<Transaction> _allTransactions = []; // Store all fetched data
  List<Transaction> _filteredTransactions = []; // Store filtered data
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
    _lottieController = AnimationController(vsync: this);
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
          _allTransactions = history
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
              .toList();
          _filteredTransactions = List.from(_allTransactions);
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
    _lottieController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((t) {
        bool matchesDate = true;
        bool matchesType = true;
        bool matchesStatus = true;

        if (_dateRange != null) {
          // Check if date is within range (inclusive)
          final start = _dateRange!.start.subtract(const Duration(days: 1));
          final end = _dateRange!.end.add(const Duration(days: 1));
          matchesDate = t.date.isAfter(start) && t.date.isBefore(end);
        }

        if (_selectedPaymentType != null) {
          // Simple string match for now, assuming types map roughly
          // Adjust logic if types need mapping (e.g. 'Net Banking' vs 'Online')
          matchesType = t.paymentMethod == _selectedPaymentType;
          if (_selectedPaymentType == 'UPI' && t.paymentMethod == 'Online') {
            matchesType = true; // Temporary fallback
          }
        }

        if (_selectedStatus != null) {
          matchesStatus = t.status == _selectedStatus;
        }

        return matchesDate && matchesType && matchesStatus;
      }).toList();

      _showFilters = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _selectedPaymentType = null;
      _selectedStatus = null;
      _filteredTransactions = List.from(_allTransactions);
    });
  }

  Future<void> _downloadReceipt(Transaction transaction) async {
    try {
      final user = await _authService.getUser();
      if (user != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saving Receipt...')));
        }
        await ReceiptService().saveReceiptFile(transaction, user);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Receipt saved to Downloads/Finolex Receipts'),
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
      }
    } catch (e) {
      debugPrint('Error downloading: $e');
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

  void _openReceipt(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ReceiptPreviewScreen(transaction: transaction);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          ProfileStyleHeader(
            title: 'History',
            showBackButton: true,
            onBackTap: () {
              if (GoRouter.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/home'); // Fallback if no history
              }
            },
            actions: [
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () {
                  context.push('/all-receipts');
                },
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _refreshController.forward().then((_) {
                  _refreshController.reset();
                });
                // Refresh logic
                await _fetchTransactions();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Filters panel
                  if (_showFilters)
                    SliverToBoxAdapter(child: _buildFiltersPanel()),

                  // Transaction list or Empty/Loading state
                  _buildTransactionSlivers(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSlivers() {
    if (_isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_filteredTransactions.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    // Group transactions by date
    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in _filteredTransactions) {
      String dateGroup = _getDateGroup(transaction.date);
      if (groupedTransactions.containsKey(dateGroup)) {
        groupedTransactions[dateGroup]!.add(transaction);
      } else {
        groupedTransactions[dateGroup] = [transaction];
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
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
      }, childCount: groupedTransactions.keys.length),
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
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/No Data Animation.json',
              controller: _lottieController,
              height: 180,
              onLoaded: (composition) {
                _lottieController
                  ..duration = composition.duration * (1)
                  ..repeat();
              },
            ),
            const SizedBox(height: 24),
            Text(
              'No Transactions Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
              textAlign: TextAlign.center,
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
}

class ReceiptModal extends StatefulWidget {
  final Transaction transaction;

  const ReceiptModal({super.key, required this.transaction});

  @override
  State<ReceiptModal> createState() => _ReceiptModalState();
}

class _ReceiptModalState extends State<ReceiptModal> {
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    try {
      final receiptService = ReceiptService();
      final authService = AuthService();
      final user = await authService.getUser();
      if (user != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saving Receipt...')));
        }

        final file = await receiptService.saveReceiptFile(
          widget.transaction,
          user,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Receipt saved to ${file.path}'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error downloading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

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
                  '₹${widget.transaction.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  'Transaction ID',
                  widget.transaction.id,
                ),
                _buildDetailRow(
                  context,
                  'Date & Time',
                  DateFormat(
                    'MMM dd, yyyy hh:mm a',
                  ).format(widget.transaction.date),
                ),
                _buildDetailRow(
                  context,
                  'Payment Method',
                  widget.transaction.paymentMethod,
                ),
                _buildDetailRow(
                  context,
                  'Status',
                  widget.transaction.status,
                  isStatus: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Manager Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
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

          const SizedBox(height: 32),

          // Actions
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isDownloading ? null : _handleDownload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: NeumorphicStyle.cardDecoration(
                      context,
                      borderRadius: 20,
                    ),
                    child: Center(
                      child: _isDownloading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : Text(
                              'Download PDF',
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
        case 'Completed':
        case 'Approved':
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
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary(context),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
