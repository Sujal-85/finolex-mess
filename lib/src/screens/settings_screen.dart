import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _expandController;
  late AnimationController _moonController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _moonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _expandController.dispose();
    _moonController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _expandController.forward() : _expandController.reverse();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Animated Header
                  SliverAppBar(
                    expandedHeight: 180,
                    floating: false,
                    pinned: true,
                    centerTitle: true,
                    backgroundColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      expandedTitleScale: 1.3,
                      title: Text(
                        'Settings',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    AppColors.primary.withOpacity(0.4),
                                    Colors.transparent,
                                  ]
                                : [
                                    AppColors.primary.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20, top: 20),
                            child: Lottie.asset(
                              'assets/lottie/settings_gear.json',
                              width: 120,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => context.pop(),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Theme Preview Card
                          _buildThemePreviewCard(settings, isDark),

                          const SizedBox(height: 20),

                          // Appearance Section
                          _buildAppearanceSection(settings, isDark),

                          const SizedBox(height: 20),

                          // Language Section
                          _buildLanguageSection(settings),

                          const SizedBox(height: 20),

                          // Notifications Masterpiece
                          _buildNotificationsSection(settings),

                          const SizedBox(height: 20),

                          // Support & Legal
                          _buildSupportSection(),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  colors: const [Colors.blue, Colors.orange, Colors.purple],
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemePreviewCard(SettingsService settings, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 32),
      child: Row(
        children: [
          Lottie.asset(
            isDark ? 'assets/lottie/moon.json' : 'assets/lottie/sun.json',
            controller: _moonController,
            onLoaded: (comp) {
              _moonController.duration = comp.duration;
              isDark ? _moonController.reverse() : _moonController.forward();
            },
            width: 80,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDark ? 'Dark Mode Active' : 'Light Mode Active',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tap below to change appearance',
                  style: GoogleFonts.roboto(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(SettingsService settings, bool isDark) {
    return _buildSectionCard(
      title: "Appearance",
      icon: const Icon(
        Icons.palette_rounded,
        size: 36,
        color: AppColors.primary,
      ),
      children: [
        _buildSwitchTile(
          title: "Dark Mode",
          subtitle: "Enable dark theme",
          icon: Icons.dark_mode_rounded,
          value: settings.settings.isDarkMode,
          onChanged: (v) {
            settings.toggleDarkMode(v);
            v ? _moonController.reverse() : _moonController.forward();
            HapticFeedback.selectionClick();
          },
        ),
        _buildSwitchTile(
          title: "Auto Theme",
          subtitle: "Follow system",
          icon: Icons.brightness_auto_rounded,
          value: settings.settings.isAutoMode,
          onChanged: (v) => settings.setAutoMode(v),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(SettingsService settings) {
    return _buildSectionCard(
      title: "Language",
      icon: const Icon(
        Icons.translate_rounded,
        size: 36,
        color: AppColors.primary,
      ),
      children: [
        ListTile(
          leading: Lottie.asset('assets/lottie/india_flag.json', width: 50),
          title: Text(
            "English",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text("Default language"),
          trailing: const Icon(Icons.check_circle, color: AppColors.primary),
          onTap: () => _showLanguageDialog(settings),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(SettingsService settings) {
    return _buildSectionCard(
      title: "Notifications",
      icon: const Icon(
        Icons.notifications_rounded,
        size: 36,
        color: AppColors.primary,
      ),
      trailing: RotationTransition(
        turns: Tween(begin: 0.0, end: 0.5).animate(
          CurvedAnimation(parent: _expandController, curve: Curves.ease),
        ),
        child: const Icon(Icons.expand_more_rounded, size: 30),
      ),
      onTap: _toggleExpand,
      children: [
        _buildSwitchTile(
          title: "Push Notifications",
          subtitle: "Enable all app notifications",
          icon: Icons.notifications_active_rounded,
          value: settings.settings.pushNotifications,
          onChanged: (v) {
            settings.togglePushNotifications(v);
            if (v) {
              _confettiController.play();
              HapticFeedback.heavyImpact();
            }
          },
        ),
        SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: _expandController,
            curve: Curves.easeOutCubic,
          ),
          child: Column(
            children: [
              _buildSwitchTile(
                title: "Mess Menu Alerts",
                icon: Icons.restaurant_menu,
                value: settings.settings.messAlerts,
                onChanged: settings.toggleMessAlerts,
              ),
              _buildSwitchTile(
                title: "Payment Updates",
                icon: Icons.payments_rounded,
                value: settings.settings.paymentUpdates,
                onChanged: settings.togglePaymentUpdates,
              ),
              _buildSwitchTile(
                title: "Announcements",
                icon: Icons.campaign_rounded,
                value: settings.settings.announcements,
                onChanged: settings.toggleAnnouncements,
              ),
              _buildSwitchTile(
                title: "Urgent Alerts",
                icon: Icons.warning_rounded,
                value: settings.settings.urgentAlerts,
                onChanged: settings.toggleUrgentAlerts,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSectionCard(
      title: "Support & Legal",
      icon: const Icon(Icons.support_agent_rounded, size: 36),
      children: [
        _buildNavTile("Contact Support", Icons.headset_mic_rounded, () {}),
        _buildNavTile("Help Center", Icons.help_rounded, () {}),
        _buildNavTile("Privacy Policy", Icons.privacy_tip_rounded, () {}),
        _buildNavTile("Terms of Service", Icons.description_rounded, () {}),
        _buildNavTile("Rate App", Icons.star_rounded, () {}),
        _buildNavTile(
          "Version 1.0.0",
          Icons.info_rounded,
          () {},
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget icon,
    Widget? trailing,
    VoidCallback? onTap,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: NeumorphicStyle.cardDecoration(
        context,
        borderRadius: 28,
        shadowIntensity: 0.2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            initiallyExpanded: title == "Notifications" ? _isExpanded : false,
            onExpansionChanged: title == "Notifications"
                ? (_) => _toggleExpand()
                : null,
            leading: icon,
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: trailing ?? const SizedBox(width: 48),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 28),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: GoogleFonts.roboto(fontSize: 13))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withOpacity(0.3),
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildNavTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled
            ? AppColors.primary
            : AppColors.textSecondaryLight.withOpacity(0.5),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondaryLight,
      ),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }

  void _showLanguageDialog(SettingsService settings) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "Choose Language",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Lottie.asset('assets/lottie/india_flag.json', width: 40),
              title: const Text("English"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text("हिंदी", style: TextStyle(fontSize: 24)),
              title: const Text("Hindi (Coming Soon)"),
              enabled: false,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }
}
