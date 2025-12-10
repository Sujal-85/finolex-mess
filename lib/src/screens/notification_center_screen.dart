import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/animations/empty_state.dart';
import '../widgets/profile_style_header.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Auto-mark all as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationService>().markAllAsRead();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final groupedNotifications = _groupNotificationsByDate(
          notificationService.getFilteredNotifications(),
        );

        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(notificationService),

                // Category filters
                _buildCategoryFilters(notificationService),

                // Notification list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      // Simulate refresh
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: groupedNotifications.isEmpty
                        ? const EmptyStateWidget(
                            message: 'No notifications yet',
                            subMessage:
                                'We\'ll notify you when something important happens',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _calculateItemCount(
                              groupedNotifications,
                            ),
                            itemBuilder: (context, index) {
                              return _buildListItem(
                                context,
                                index,
                                groupedNotifications,
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(NotificationService notificationService) {
    return ProfileStyleHeader(
      title: 'Notifications',
      showBackButton: true,
      onBackTap: () => context.pop(),
      actions: [
        IconButton(
          onPressed: () {
            context.push('/settings');
          },
          icon: const Icon(
            Icons.settings_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(NotificationService notificationService) {
    final categories = [
      NotificationType.general,
      NotificationType.mess,
      NotificationType.payment,
      NotificationType.news,
      NotificationType.urgent,
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = notificationService.selectedFilter == category;

          return GestureDetector(
            onTap: () {
              notificationService.selectFilter(category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(
                        color: AppColors.textSecondaryLight.withOpacity(0.3),
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(4, 4),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  category.displayName,
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
    );
  }

  Map<String, List<NotificationModel>> _groupNotificationsByDate(
    List<NotificationModel> notifications,
  ) {
    final groups = <String, List<NotificationModel>>{};

    for (final notification in notifications) {
      final dateGroup = _getDateGroup(notification.timestamp);
      if (!groups.containsKey(dateGroup)) {
        groups[dateGroup] = [];
      }
      groups[dateGroup]!.add(notification);
    }

    return groups;
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays <= 7) {
      return 'This Week';
    } else {
      return 'Older';
    }
  }

  int _calculateItemCount(
    Map<String, List<NotificationModel>> groupedNotifications,
  ) {
    int count = 0;
    groupedNotifications.forEach((group, notifications) {
      count += 1; // For the group header
      count += notifications.length; // For the notifications
    });
    return count;
  }

  Widget _buildListItem(
    BuildContext context,
    int index,
    Map<String, List<NotificationModel>> groupedNotifications,
  ) {
    int currentIndex = 0;

    for (final entry in groupedNotifications.entries) {
      final group = entry.key;
      final notifications = entry.value;

      // Check if this index corresponds to a group header
      if (currentIndex == index) {
        return _buildGroupHeader(group);
      }
      currentIndex++;

      // Check if this index corresponds to a notification
      for (int i = 0; i < notifications.length; i++) {
        if (currentIndex == index) {
          return _buildNotificationCard(notifications[i]);
        }
        currentIndex++;
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildGroupHeader(String group) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        group,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.horizontal,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              // Delete notification
              notificationService.deleteNotification(notification.id);
            } else {
              // Mark as read
              notificationService.markAsRead(notification.id);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: NeumorphicStyle.cardDecoration(
              context,
              borderRadius: 20,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.type,
                  ).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 20,
                  ),
                ),
              ),
              title: Text(
                notification.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    notification.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatTime(notification.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      if (notification.isNew)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'New',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                // Mark as read on tap
                if (notification.isUnread) {
                  notificationService.markAsRead(notification.id);
                }
                // Navigate to notification details
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.mess:
        return Icons.restaurant_outlined;
      case NotificationType.payment:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.news:
        return Icons.article_outlined;
      case NotificationType.urgent:
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.mess:
        return AppColors.primary;
      case NotificationType.payment:
        return AppColors.accent;
      case NotificationType.news:
        return Colors.purple;
      case NotificationType.urgent:
        return Colors.red;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
