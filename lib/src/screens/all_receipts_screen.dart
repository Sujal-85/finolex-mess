import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/receipt_service.dart';
import '../models/receipt_model.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/animations/empty_state.dart';
import '../widgets/profile_style_header.dart';

class AllReceiptsScreen extends StatefulWidget {
  const AllReceiptsScreen({super.key});

  @override
  State<AllReceiptsScreen> createState() => _AllReceiptsScreenState();
}

class _AllReceiptsScreenState extends State<AllReceiptsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late AnimationController _listController;
  late Animation<double> _listFadeAnimation;
  late Animation<Offset> _listSlideAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _filterChips = [
    'All',
    'This Month',
    'Last Month',
    'UPI',
    'Card',
    'Refund',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize header animations
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFadeAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );

    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Initialize list animations
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _listFadeAnimation = CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOut,
    );

    _listSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _listController, curve: Curves.easeOutCubic),
        );

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerController.forward();
      _listController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptService>(
      builder: (context, receiptService, child) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(receiptService),

                // Search and Filter Bar
                _buildSearchAndFilterBar(receiptService),

                // Receipt List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      // Simulate refresh
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: receiptService.receipts.isEmpty
                        ? const EmptyStateWidget(
                            message: 'No receipts available yet',
                            subMessage:
                                'Your payment receipts will appear here',
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: receiptService.receipts.length,
                            itemBuilder: (context, index) {
                              final receipt = receiptService.receipts[index];
                              return _buildReceiptCard(
                                receipt,
                                receiptService,
                                index,
                              );
                            },
                          ),
                  ),
                ),

                // Bulk Actions Bar
                if (receiptService.hasSelectedReceipts)
                  _buildBulkActionsBar(receiptService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ReceiptService receiptService) {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: ProfileStyleHeader(
          title: 'My Receipts',
          subtitle: 'Download past transactions anytime',
          actions: [
            GestureDetector(
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating PDF...'),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 1),
                  ),
                );
                await receiptService.downloadSelectedReceipts();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.download_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ReceiptService receiptService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: NeumorphicStyle.cardDecoration(
              context,
              borderRadius: 20,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                receiptService.setSearchQuery(value);
              },
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textPrimary(context),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search by Transaction ID, Amount, Date...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                ),
                prefixIcon: Icon(
                  Icons.search_outlined,
                  color: AppColors.textSecondaryLight,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filterChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final chip = _filterChips[index];
                final isSelected = receiptService.selectedFilter == chip;

                return GestureDetector(
                  onTap: () {
                    receiptService.setSelectedFilter(chip);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: AppColors.textSecondaryLight.withOpacity(
                                0.3,
                              ),
                            ),
                    ),
                    child: Center(
                      child: Text(
                        chip,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(
    Receipt receipt,
    ReceiptService receiptService,
    int index,
  ) {
    final isSelected = receiptService.selectedReceiptIds.contains(receipt.id);

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _listController,
              curve: Interval(0.1 * index, 1.0, curve: Curves.easeOutCubic),
            ),
          ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listController,
            curve: Interval(0.1 * index, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: GestureDetector(
          onTap: () {
            if (receiptService.hasSelectedReceipts) {
              receiptService.toggleReceiptSelection(receipt.id);
            } else {
              // Navigate to receipt preview
              context.push('/receipt-preview', extra: receipt.toJson());
            }
          },
          onLongPress: () {
            receiptService.toggleReceiptSelection(receipt.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface(context),
              borderRadius: BorderRadius.circular(22),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : NeumorphicStyle.cardDecoration(context).boxShadow,
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Column(
              children: [
                // Main content
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Leading icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              receipt.getPaymentIcon == Icons.flash_on_outlined
                              ? AppColors.primary.withOpacity(0.1)
                              : receipt.getPaymentIcon ==
                                    Icons.credit_card_outlined
                              ? AppColors.accent.withOpacity(0.1)
                              : AppColors.textSecondaryLight.withOpacity(0.1),
                        ),
                        child: Icon(
                          receipt.getPaymentIcon,
                          color:
                              receipt.getPaymentIcon == Icons.flash_on_outlined
                              ? AppColors.primary
                              : receipt.getPaymentIcon ==
                                    Icons.credit_card_outlined
                              ? AppColors.accent
                              : AppColors.textSecondaryLight,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Text block
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Amount
                            Text(
                              '₹${receipt.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Date & Time
                            Text(
                              DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(receipt.dateTime),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Transaction ID
                            Text(
                              'Txn ID: ${receipt.transactionId}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Badge and actions
                      Column(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: receipt
                                  .getStatusColor(context)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              receipt.status,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: receipt.getStatusColor(context),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Action icons (only visible when not in selection mode)
                          if (!receiptService.hasSelectedReceipts)
                            Row(
                              children: [
                                // Download PDF
                                GestureDetector(
                                  onTap: () {
                                    receiptService.downloadReceipt(receipt.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Downloading receipt ${receipt.transactionId} as PDF...',
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    Icons.download_outlined,
                                    size: 20,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Share
                                GestureDetector(
                                  onTap: () {
                                    receiptService.shareReceipt(receipt.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Sharing receipt ${receipt.transactionId}...',
                                        ),
                                        backgroundColor: AppColors.accent,
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    Icons.share_outlined,
                                    size: 20,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.textSecondaryLight.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulkActionsBar(ReceiptService receiptService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Selected count
          Text(
            '${receiptService.selectedCount} selected',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
          ),

          const Spacer(),

          // Download Selected button
          GestureDetector(
            onTap: () {
              receiptService.downloadSelectedReceipts();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Downloading ${receiptService.selectedCount} receipts as ZIP...',
                  ),
                  backgroundColor: AppColors.primary,
                ),
              );
              receiptService.clearSelection();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.download_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Download',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Share Selected button
          GestureDetector(
            onTap: () {
              receiptService.shareSelectedReceipts();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sharing ${receiptService.selectedCount} receipts...',
                  ),
                  backgroundColor: AppColors.accent,
                ),
              );
              receiptService.clearSelection();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textSecondaryLight),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.share_outlined,
                    color: AppColors.textPrimary(context),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Share',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
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
}
