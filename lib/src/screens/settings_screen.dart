import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/profile_style_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final user = await _authService.getUser();
    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: Column(
            children: [
              const ProfileStyleHeader(title: 'Settings', showBackButton: true),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Profile Section
                    if (_user != null) _buildProfileSection(),
                    const SizedBox(height: 24),

                    // Appearance
                    _buildSectionHeader('Appearance'),
                    _buildSettingsTile(
                      title: 'Dark Mode',
                      subtitle: 'Toggle dark theme',
                      icon: Icons.dark_mode_rounded,
                      iconColor: Colors.purple,
                      trailing: Switch(
                        value: settings.settings.isDarkMode,
                        onChanged: (val) {
                          settings.toggleDarkMode(val);
                          HapticFeedback.selectionClick();
                        },
                        activeThumbColor: AppColors.primary,
                      ),
                    ),
                    _buildSettingsTile(
                      title: 'Auto Theme',
                      subtitle: 'Follow system settings',
                      icon: Icons.brightness_auto_rounded,
                      iconColor: Colors.blue,
                      trailing: Switch(
                        value: settings.settings.isAutoMode,
                        onChanged: (val) => settings.setAutoMode(val),
                        activeThumbColor: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Notifications
                    _buildSectionHeader('Notifications'),
                    _buildSettingsTile(
                      title: 'Push Notifications',
                      icon: Icons.notifications_active_rounded,
                      iconColor: Colors.redAccent,
                      trailing: Switch(
                        value: settings.settings.pushNotifications,
                        onChanged: (val) =>
                            settings.togglePushNotifications(val),
                        activeThumbColor: AppColors.primary,
                      ),
                    ),
                    if (settings.settings.pushNotifications) ...[
                      _buildSettingsTile(
                        title: 'Mess Menu Alerts',
                        icon: Icons.restaurant_menu_rounded,
                        iconColor: Colors.orange,
                        trailing: Switch(
                          value: settings.settings.messAlerts,
                          onChanged: settings.toggleMessAlerts,
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Account & Security
                    _buildSectionHeader('Account'),
                    _buildSettingsTile(
                      title: 'Edit Profile',
                      icon: Icons.person_outline_rounded,
                      iconColor: Colors.teal,
                      onTap: () => context.push('/edit-profile'),
                      showArrow: true,
                    ),
                    _buildSettingsTile(
                      title: 'Change Password',
                      icon: Icons.lock_outline_rounded,
                      iconColor: Colors.indigo,
                      onTap: () => context.push('/change-password'),
                      showArrow: true,
                    ),

                    const SizedBox(height: 24),

                    // Support
                    _buildSectionHeader('Support'),
                    _buildSettingsTile(
                      title: 'Help & Support',
                      icon: Icons.headset_mic_rounded,
                      iconColor: Colors.green,
                      onTap: () => context.push('/emergency'),
                      showArrow: true,
                    ),
                    _buildSettingsTile(
                      title: 'About App',
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.grey,
                      onTap: () => context.push('/about'),
                      showArrow: true,
                    ),

                    const SizedBox(height: 40),

                    // Logout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () async {
                          await _authService.logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded),
                            const SizedBox(width: 8),
                            Text(
                              'Log Out',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: _user?['profileImage'] != null
                ? NetworkImage(_user!['profileImage'])
                : null,
            child: _user?['profileImage'] == null
                ? Text(
                    (_user?['name'] ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?['name'] ?? 'User',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  _user?['email'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 16),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary(context),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              )
            : null,
        trailing:
            trailing ??
            (showArrow
                ? Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textSecondaryLight,
                  )
                : null),
      ),
    );
  }
}
