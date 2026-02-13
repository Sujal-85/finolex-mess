import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart'; // Added for navigation
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../theme/colors.dart';
import '../widgets/neumorphic_card.dart';
import '../widgets/profile_style_header.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  final AttendanceService _service = AttendanceService();
  // ... existing state variables ...
  Attendance? _todayAttendance;
  List<Attendance> _history = [];
  bool _isLoading = true;
  String? _error;
  bool _showAllHistory = false;

  // Meal Times
  static const TimeOfDay _breakfastTime = TimeOfDay(hour: 8, minute: 15);
  static const TimeOfDay _lunchTime = TimeOfDay(hour: 13, minute: 30);
  static const TimeOfDay _dinnerTime = TimeOfDay(hour: 19, minute: 30);

  bool _isMealWindowActive(TimeOfDay mealTime) {
    final now = DateTime.now();
    final mealDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      mealTime.hour,
      mealTime.minute,
    );

    final startTime = mealDateTime.subtract(const Duration(minutes: 5));
    final endTime = mealDateTime.add(const Duration(minutes: 10));

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  String _getFormattedTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final today = await _service.getTodayStatus();
      final history = await _service.getHistory();

      if (mounted) {
        setState(() {
          _todayAttendance = today;
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('AUTH_EXPIRED')) {
          context.go('/login');
          return;
        }
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAttendance(String mealType) async {
    try {
      await _service.markAttendance(mealType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${mealType[0].toUpperCase()}${mealType.substring(1)} attendance requested!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData(); // Reload to show updated status
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('AUTH_EXPIRED')) {
          context.go('/login');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
      body: Column(
        children: [
          ProfileStyleHeader(
            title: 'Daily Attendance',
            showBackButton: true,
            onBackTap: () => context.pop(),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Today\'s Meals'),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      Center(
                        child: Text(
                          'Error: $_error',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      )
                    else
                      _buildTodayMeals(),

                    const SizedBox(height: 32),
                    _buildSectionTitle('History'),
                    const SizedBox(height: 16),
                    if (!_isLoading) _buildHistoryList(),

                    const SizedBox(height: 32),
                    _buildDisclaimer(),
                    const SizedBox(
                      height: 80,
                    ), // Extra space for FAB and disclaimer
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showManualEntryDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit_calendar, color: Colors.white),
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mark Attendance (Manual)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select a meal to mark present manually:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildManualButton('Breakfast', 'breakfast', _breakfastTime),
            const SizedBox(height: 10),
            _buildManualButton('Lunch', 'lunch', _lunchTime),
            const SizedBox(height: 10),
            _buildManualButton('Dinner', 'dinner', _dinnerTime),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualButton(String label, String type, TimeOfDay mealTime) {
    final isActive = _isMealWindowActive(mealTime);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
            color: isActive ? AppColors.primary : Colors.grey.withOpacity(0.3),
          ),
          backgroundColor: isActive ? null : Colors.grey.withOpacity(0.05),
        ),
        onPressed: isActive
            ? () {
                Navigator.pop(context);
                _markAttendance(type);
              }
            : null,
        child: Text(
          isActive ? label : '$label (Window Closed)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary(context),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
              const SizedBox(width: 8),
              Text(
                'Attendance Rules',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Attendance buttons are active only from 5 mins before to 10 mins after the meal time.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            '• A daily increment of ₹5 applies after 10 days of non-payment.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Meal Times:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          _buildTimeRow('Breakfast', _breakfastTime),
          _buildTimeRow('Lunch', _lunchTime),
          _buildTimeRow('Dinner', _dinnerTime),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, TimeOfDay time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12)),
          Text(
            _getFormattedTime(time),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMeals() {
    final today = _todayAttendance;
    // Fallback if null (though service handles it somewhat)
    final breakfast = today?.breakfast ?? MealStatus(status: 'not_marked');
    final lunch = today?.lunch ?? MealStatus(status: 'not_marked');
    final dinner = today?.dinner ?? MealStatus(status: 'not_marked');

    return Column(
      children: [
        _buildMealCard('Breakfast', breakfast, 'breakfast', _breakfastTime),
        const SizedBox(height: 16),
        _buildMealCard('Lunch', lunch, 'lunch', _lunchTime),
        const SizedBox(height: 16),
        _buildMealCard('Dinner', dinner, 'dinner', _dinnerTime),
      ],
    );
  }

  Widget _buildMealCard(
    String title,
    MealStatus status,
    String type,
    TimeOfDay mealTime,
  ) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    bool canMark = false;

    switch (status.status) {
      case 'present':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Present';
        break;
      case 'absent':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusText = 'Absent';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'Pending';
        break;
      default:
        statusColor = AppColors.textSecondaryLight;
        statusIcon = Icons.radio_button_unchecked;
        statusText = 'Not Marked';
        canMark = true;
    }

    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              canMark ? Icons.restaurant : statusIcon,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  statusText,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (canMark) _buildActionButtons(type, mealTime),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String type, TimeOfDay mealTime) {
    final isActive = _isMealWindowActive(mealTime);

    if (!isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Text(
          'Window Closed',
          style: TextStyle(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _markAttendance(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('Mark', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No history available',
            style: TextStyle(color: AppColors.textSecondaryLight),
          ),
        ),
      );
    }

    // Determine how many items to show
    final itemCount = _showAllHistory
        ? _history.length
        : (_history.length > 4 ? 4 : _history.length);
    final hasMore = _history.length > 4;

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final attendance = _history[index];
            final dateStr = DateFormat(
              'MMM dd, yyyy',
            ).format(DateTime.parse(attendance.date).toLocal());

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: NeumorphicCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHistoryItem(
                          'Breakfast',
                          attendance.breakfast.status,
                        ),
                        _buildHistoryItem('Lunch', attendance.lunch.status),
                        _buildHistoryItem('Dinner', attendance.dinner.status),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (hasMore && !_showAllHistory)
          TextButton(
            onPressed: () {
              setState(() {
                _showAllHistory = true;
              });
            },
            child: Text(
              'View All History',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (_showAllHistory && hasMore)
          TextButton(
            onPressed: () {
              setState(() {
                _showAllHistory = false;
              });
            },
            child: Text(
              'Show Less',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryItem(String label, String status) {
    Color color;
    switch (status) {
      case 'present':
        color = AppColors.success;
        break;
      case 'absent':
        color = AppColors.error;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ],
    );
  }
}
