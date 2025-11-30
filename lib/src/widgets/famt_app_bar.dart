import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';

class FamtAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final int notificationCount;
  final bool showProfile;
  final bool showBackButton; // New parameter
  final VoidCallback? onBackTap; // New parameter

  const FamtAppBar({
    super.key,
    required this.title,
    this.onNotificationTap,
    this.onProfileTap,
    this.notificationCount = 0,
    this.showProfile = true,
    this.showBackButton =
        false, // Default to false to maintain backward compatibility
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 10,
      ),
      color: AppColors.background(context),
      child: Row(
        children: [
          // Back button (if enabled)
          if (showBackButton)
            GestureDetector(
              onTap: onBackTap ?? () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: NeumorphicStyle.buttonDecoration(
                  context,
                  borderRadius: 12,
                  color: AppColors.surface(context),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
          if (showBackButton) const SizedBox(width: 16),

          // Profile Photo
          if (showProfile &&
              !showBackButton) // Only show profile when no back button
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: NeumorphicStyle.buttonDecoration(
                  context,
                  borderRadius: 20,
                  color: AppColors.surface(context),
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
            ),
          if (showProfile && !showBackButton) const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),

          // Notification Bell
          GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: NeumorphicStyle.buttonDecoration(
                    context,
                    borderRadius: 12,
                    color: AppColors.surface(context),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        notificationCount > 9
                            ? '9+'
                            : notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
