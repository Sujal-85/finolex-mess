import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Service for Version Checking
class UpdateService {
  // Hardcoded versions for comparison as permitted
  // In a production app, fetch 'latestVersion' from your backend API
  static const String currentVersion = "1.0.0";
  static const String latestVersion = "1.0.1";

  // Replace with your Play Store URL
  static const String playStoreUrl =
      "https://play.google.com/store/apps/details?id=com.finolex.mess";

  /// Checks if an update is available and shows the dialog if needed
  static Future<void> checkUpdate(
    BuildContext context, {
    VoidCallback? onUpdateCallback,
  }) async {
    // Basic version check logic
    if (currentVersion != latestVersion) {
      showWhatsAppAutoUpdateDialog(context, onUpdate: onUpdateCallback);
    } else {
      // Version is up to date
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('App is up to date')));
    }
  }
}

/// Fully functional WhatsApp-style update confirmation dialog
void showWhatsAppAutoUpdateDialog(
  BuildContext context, {
  VoidCallback? onUpdate,
}) {
  showDialog(
    context: context,
    barrierDismissible: false, // Non-dismissible per requirements
    builder: (BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return PopScope(
        canPop: false, // Prevents closing with back button
        child: Dialog(
          elevation: 24,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDark ? const Color(0xFF232d36) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (Bold)
                Text(
                  "Turn off auto-updates?",
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Body Text (Matches WhatsApp exactly)
                Text(
                  "Updates add new features as soon as they're available. Do you want to turn these off?",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Primary Button: Turn off (Blue)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final url = Uri.parse(UpdateService.playStoreUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                      if (onUpdate != null) onUpdate();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF007bff,
                      ), // WhatsApp-ish Blue action button
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      "Turn off",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary Button: Cancel (Light-grey)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFf0f2f5),
                      foregroundColor: isDark ? Colors.white70 : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
