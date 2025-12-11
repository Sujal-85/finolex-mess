import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../blocs/dashboard_event.dart';
import '../../blocs/dashboard_state.dart';
import '../../theme/colors.dart';
import '../../theme/neumorphism.dart';
import '../../services/local_notification_service.dart';
import '../../services/firebase_api.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard/menu_card.dart';

import '../../widgets/dashboard/announcement_card.dart';
import '../../widgets/dashboard/payment_due_card.dart';
import '../../widgets/dashboard/birthday_card.dart';
import '../../widgets/dashboard/food_quote_card.dart';
import '../../widgets/receipt_card.dart';
import '../../models/transaction.dart';
import '../../services/receipt_service.dart';
import '../../services/auth_service.dart';
// For ReceiptModal

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoadRequested());
    // Request permissions after build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await LocalNotificationService().requestPermissions();
      await FirebaseApi().requestPermission();
    });
  }

  Future<void> _downloadReceipt(Transaction transaction) async {
    try {
      final user = await AuthService().getUser();
      if (user == null) return;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Generating Receipt...')));
      }

      await ReceiptService().generateAndDownloadReceipt(transaction, user);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt Downloaded!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error downloading receipt: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: BlocListener<DashboardBloc, DashboardState>(
          listener: (context, state) {
            if (state is DashboardLoaded) {
              final notificationService = LocalNotificationService();

              // Schedule Daily Meal Reminders
              notificationService.scheduleDailyNotification(
                id: 10,
                title: 'Good Morning! ☀️',
                body: 'Breakfast is ready! Today: ${state.breakfastItem}',
                hour: 8,
                minute: 0,
              );
              notificationService.scheduleDailyNotification(
                id: 11,
                title: 'Lunch Time! 🍛',
                body: 'Lunch is served! Today: ${state.lunchItem}',
                hour: 12,
                minute: 30,
              );
              notificationService.scheduleDailyNotification(
                id: 12,
                title: 'Dinner is Served! 🌙',
                body: 'Dinner is ready! Today: ${state.dinnerItem}',
                hour: 19,
                minute: 30,
              );

              // Schedule Menu Update Notification
              notificationService.scheduleDailyNotification(
                id: 20,
                title: 'Menu Updated 📅',
                body: 'Check out today\'s menu including ${state.lunchItem}!',
                hour: 7,
                minute: 0,
              );

              // Schedule Payment Due Notification if balance is low
              if (state.balance < 3500) {
                notificationService.scheduleDailyNotification(
                  id: 100,
                  title: 'Payment Due ⚠️',
                  body:
                      'Your mess fees are due. Please pay to avoid penalties.',
                  hour: 10,
                  minute: 0,
                );
              } else {
                notificationService.cancelNotification(100);
              }
            }
          },
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is DashboardError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/lottie/Not found error.json',
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<DashboardBloc>().add(
                                DashboardLoadRequested(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              'Retry Connection',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Next Meal Card
              if (state is DashboardLoaded) {
                final double pendingAmount = state.pendingAmount;

                // Use Backend Fine & Due Date
                final double fine = state.fineAmount;
                final DateTime now = DateTime.now();

                // Show due date from backend or default to 10th
                final dueDateDisplay = state.paymentDueDate != null
                    ? '${state.paymentDueDate!.day}th ${DateFormat('MMM').format(state.paymentDueDate!)}'
                    : '10th ${DateFormat('MMM').format(now)}';

                double totalMessFee = state.messFee + fine;
                double currentBalance = (state.balance ?? 0).toDouble();
                double outstanding =
                    totalMessFee - currentBalance - pendingAmount;
                if (outstanding < 0) outstanding = 0;

                return Column(
                  children: [
                    // Fixed Header
                    DashboardHeader(
                      studentName: state.studentName,
                      hostelBlock: state.hostelBlock,
                      roomNumber: state.roomNumber,
                      notificationCount: state.unreadNotifications,
                      profileImage: state.profileImage,
                      onNotificationTap: () async {
                        await context.push('/notifications');
                        if (context.mounted) {
                          context.read<DashboardBloc>().add(
                            DashboardNotificationCheck(),
                          );
                        }
                      },
                      onProfileTap: () => context.push('/profile'),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          context.read<DashboardBloc>().add(
                            DashboardRefreshRequested(),
                          );
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // Birthday Card or Quote Card
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: state.birthdays.isNotEmpty
                                    ? BirthdayCard(
                                        studentName:
                                            state.birthdays.first['name'],
                                        profileImage: state
                                            .birthdays
                                            .first['profileImage'],
                                      )
                                    : const FoodQuoteCard(),
                              ),
                              const SizedBox(height: 20),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  children: [
                                    // Payment Due
                                    Column(
                                      children: [
                                        PaymentDueCard(
                                          amount: outstanding,
                                          pendingAmount: pendingAmount,
                                          dueDate: dueDateDisplay,
                                          fineAmount: fine.toInt(),
                                          onPayNow: () async {
                                            await context.push('/payment');
                                            if (context.mounted) {
                                              context.read<DashboardBloc>().add(
                                                DashboardRefreshRequested(),
                                              );
                                            }
                                          },
                                        ),
                                        if (outstanding <= 0) ...[
                                          Builder(
                                            builder: (context) {
                                              // Find latest full payment receipt
                                              final fullPayments = state
                                                  .recentTransactions
                                                  .where((t) {
                                                    final amount =
                                                        (t['amount'] ?? 0)
                                                            .toDouble();
                                                    final status =
                                                        t['status'] ??
                                                        'Pending';
                                                    return amount >= 3400 &&
                                                        (status == 'Success' ||
                                                            status ==
                                                                'Completed' ||
                                                            status ==
                                                                'Approved');
                                                  })
                                                  .toList();

                                              if (fullPayments.isEmpty) {
                                                return const SizedBox.shrink();
                                              }

                                              // Sort by date desc just in case
                                              fullPayments.sort((a, b) {
                                                final dateA = DateTime.parse(
                                                  a['date'],
                                                );
                                                final dateB = DateTime.parse(
                                                  b['date'],
                                                );
                                                return dateB.compareTo(dateA);
                                              });

                                              final latest = fullPayments.first;
                                              final transaction = Transaction(
                                                id:
                                                    latest['razorpayOrderId'] ??
                                                    'Unknown',
                                                amount: (latest['amount'] ?? 0)
                                                    .toDouble(),
                                                date: DateTime.parse(
                                                  latest['date'],
                                                ),
                                                paymentMethod:
                                                    latest['upiId'] != null
                                                    ? 'UPI'
                                                    : 'Online',
                                                status:
                                                    latest['status'] ??
                                                    'Success',
                                                upiId: latest['upiId'],
                                              );

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 16,
                                                ),
                                                child: ReceiptCard(
                                                  transaction: transaction,
                                                  onDownload: () =>
                                                      _downloadReceipt(
                                                        transaction,
                                                      ),
                                                  onShare: () =>
                                                      _downloadReceipt(
                                                        transaction,
                                                      ),
                                                  onView: () {
                                                    // Temporary: direct download or minimal preview
                                                    // Ideally use ReceiptModal logic if available or just download
                                                    _downloadReceipt(
                                                      transaction,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // Next Meal Card
                                    _buildNextMealCard(state.nextMeal),

                                    const SizedBox(height: 24),

                                    // Menu Card
                                    MenuCard(
                                      onViewFullMenu: () =>
                                          context.push('/menu'),
                                      breakfastItem: state.breakfastItem,
                                      lunchItem: state.lunchItem,
                                      dinnerItem: state.dinnerItem,
                                    ),

                                    const SizedBox(height: 24),

                                    // Quick Actions Header
                                    Text(
                                      'Quick Actions',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Action Grid
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        return GridView.count(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisCount:
                                              3, // Changed to 3 for better visibility
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 1.0,
                                          children: [
                                            _buildCompactAction(
                                              'History',
                                              Icons.restaurant_menu,
                                              Colors.blue,
                                              () => context.push('/history'),
                                            ),
                                            _buildCompactAction(
                                              'Complaints',
                                              Icons.report_problem_outlined,
                                              Colors.orange,
                                              () => context.push('/complaints'),
                                            ),
                                            _buildCompactAction(
                                              'Support',
                                              Icons.headset_mic_outlined,
                                              Colors.green,
                                              () => context.push('/emergency'),
                                            ),
                                            _buildCompactAction(
                                              'Feedback',
                                              Icons.star_outline,
                                              Colors.amber,
                                              () => context.push('/feedback'),
                                            ),
                                            _buildCompactAction(
                                              'Rules',
                                              Icons.gavel_outlined,
                                              Colors.purple,
                                              () => context.push(
                                                '/about',
                                              ), // Placeholder
                                            ),
                                            _buildCompactAction(
                                              'Settings',
                                              Icons.settings_outlined,
                                              Colors.grey,
                                              () => context.push('/settings'),
                                            ),
                                          ],
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 24),

                                    // Recent Activity
                                    _buildRecentActivitySection(
                                      state.recentTransactions,
                                    ),

                                    const SizedBox(height: 24),

                                    // Announcements
                                    AnnouncementCard(
                                      announcement: state.latestAnnouncement,
                                      onTap: () => context.push('/news'),
                                    ),

                                    const SizedBox(height: 40),

                                    // Footer
                                    Center(
                                      child: Column(
                                        children: [
                                          Opacity(
                                            opacity: 0.7,
                                            child: Image.asset(
                                              'assets/images/logo-circle.png',
                                              height: 50,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'By Prasanna Caterers',
                                            style: GoogleFonts.playfairDisplay(
                                              fontSize: 16,
                                              fontStyle: FontStyle.italic,
                                              color:
                                                  AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.large(
        onPressed: () async {
          // Quick Pay
          await context.push('/payment');
          if (context.mounted) {
            context.read<DashboardBloc>().add(DashboardRefreshRequested());
          }
        },
        backgroundColor: AppColors.primary,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
                Text(
                  'Pay',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, String> _getNextMealInfo() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final currentTime = hour + (minute / 60.0);

    // Breakfast: 8:00 AM - 9:00 AM (Ends at 9:00)
    // Lunch: 12:30 PM - 2:30 PM (Starts 12.5, Ends 14.5)
    // Dinner: 7:30 PM - 9:30 PM (Starts 19.5, Ends 21.5)

    String meal;
    String timeRange;
    String day = _getDayName(now.weekday);

    if (currentTime < 9.0) {
      meal = 'Breakfast';
      timeRange = '8:00 AM - 9:00 AM';
    } else if (currentTime < 14.5) {
      meal = 'Lunch';
      timeRange = '12:30 PM - 2:30 PM';
    } else if (currentTime < 21.5) {
      meal = 'Dinner';
      timeRange = '7:30 PM - 9:30 PM';
    } else {
      // Next day breakfast
      meal = 'Breakfast';
      timeRange = '8:00 AM - 9:00 AM';
      day = _getDayName(now.add(const Duration(days: 1)).weekday);
    }

    return {'meal': meal, 'time': timeRange, 'day': day};
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  Widget _buildNextMealCard(String? backendNextMeal) {
    final mealInfo = _getNextMealInfo();
    final mealType = mealInfo['meal']!;
    final timeRange = mealInfo['time']!;
    final day = mealInfo['day']!;

    // Use backend data if it matches the current meal type, otherwise use generic or local logic
    // For now, we'll just display the meal type and time as requested.
    // If we had a real menu map, we could show the specific items.
    // Since backendNextMeal is just a String like "Veg Thali...", we might want to keep it if it's relevant,
    // but the user asked to change "Next Meal" logic.
    // Let's assume we show the Meal Type (e.g. Lunch) and the items if available, or just the type.
    // The user prompt showed "Lunch: Veg Thali, Rice, Dal".
    // I will try to preserve the backend string if it seems to match, or just show the calculated header.

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Next Meal ($day)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mealType,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              backendNextMeal ??
                  '$mealType Menu', // Fallback to backend data or generic
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timeRange,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(List<dynamic> transactions) {
    if (transactions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: NeumorphicStyle.cardDecoration(
              context,
              borderRadius: 20,
            ),
            child: Center(
              child: Text(
                'No recent activity',
                style: GoogleFonts.poppins(color: AppColors.textSecondaryLight),
              ),
            ),
          ),
        ],
      );
    }

    // Show only top 3 transactions
    final recent = transactions.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 20),
          child: Column(
            children: [
              for (int i = 0; i < recent.length; i++) ...[
                if (i > 0) const Divider(height: 24),
                _buildTransactionItem(recent[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(dynamic transaction) {
    final amount = (transaction['amount'] ?? 0).toDouble();
    final type = transaction['type'] ?? 'debit';
    final isCredit = type == 'credit';
    final dateStr = transaction['date'] ?? DateTime.now().toIso8601String();
    final date = DateTime.parse(dateStr);
    final formattedDate = DateFormat('MMM d, h:mm a').format(date);
    final description = transaction['description'] ?? 'Transaction';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        Text(
          '${isCredit ? '+' : '-'} ₹${amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isCredit ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  double _parseAmount(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      if (val.isEmpty) return 0.0;
      return double.tryParse(val) ?? 0.0;
    }
    return 0.0;
  }
}
