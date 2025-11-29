import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import 'neumorphic_card.dart';

class DashboardHeader extends StatelessWidget {
  final String studentName;
  final String hostelBlock;
  final String roomNumber;
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const DashboardHeader({
    super.key,
    required this.studentName,
    required this.hostelBlock,
    required this.roomNumber,
    required this.notificationCount,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: onProfileTap,
            child: NeumorphicCard(
              borderRadius: 50,
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: const AssetImage(
                  'assets/images/profile_placeholder.png',
                ), // Ensure this exists or handle error
                // child: const Icon(Icons.person, color: AppColors.primary),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Greeting & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning,',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  studentName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$hostelBlock / $roomNumber',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Notification Icon
          GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              children: [
                NeumorphicCard(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary(context),
                    size: 24,
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
