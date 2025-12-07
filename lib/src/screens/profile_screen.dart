import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/animations/shimmer_effect.dart';
import '../widgets/dialogs/plan_details_dialog.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AuthService _authService = AuthService();
  bool _isLoading = true;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      // Refresh user data to get latest details including hostel info
      final user = await _authService.refreshUser();
      if (user != null) {
        setState(() {
          _userProfile = UserProfile(
            name: user['name'] ?? 'Student',
            collegeId: user['rollNo'] ?? 'N/A',
            hostelBlock: user['hostelDetails']?['hostelName'] ?? 'Not Assigned',
            roomNumber: user['hostelDetails']?['roomNo'] ?? 'N/A',
            email: user['email'] ?? '',
            phone: user['phone'] ?? '',
            gender: 'Male', // Placeholder - Not in schema
            messType: 'Vegetarian', // Placeholder - Not in schema
            membershipStatus: 'Active', // Placeholder - Not in schema
            currentBalance: (user['balance'] ?? 0).toDouble(),
            lastPayment: 0.00, // Placeholder - Not in schema
            lastPaymentDate: DateTime.now(), // Placeholder
            profileImage: user['profileImage'],
          );
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _editPhoto() {
    // In a real app, this would open image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit photo functionality coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _editProfile() {
    context.push('/edit-profile');
  }

  void _changePassword() {
    context.push('/change-password');
  }

  void _downloadID() {
    context.push('/id-card');
  }

  void _viewReceipts() {
    context.push('/all-receipts');
  }

  void _contactSupport() {
    context.push('/emergency');
  }

  void _rechargeWallet() {
    context.push('/payment');
  }

  void _logout() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.roboto(color: AppColors.textSecondaryLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondaryLight),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : Column(
              children: [
                // Header section - Fixed
                _buildHeaderSection(),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Information cards
                        _buildInformationCards(),

                        const SizedBox(height: 24),

                        // Quick actions row
                        _buildQuickActions(),

                        const SizedBox(height: 24),

                        // Settings section
                        _buildSettingsSection(),

                        const SizedBox(height: 24),

                        Center(
                          child: Text(
                            'By Prasanna Caterers',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Profile photo with edit button
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface(context),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          _userProfile?.profileImage != null &&
                              _userProfile!.profileImage!.isNotEmpty
                          ? Image.network(
                              _userProfile!.profileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.primary,
                                );
                              },
                            )
                          : Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _editPhoto,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // User name
              Text(
                _userProfile?.name ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // College ID and verified badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _userProfile?.collegeId ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.verified,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Hostel and room info
              Text(
                '${_userProfile?.hostelBlock ?? ''}, Room ${_userProfile?.roomNumber ?? ''}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformationCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Personal Details Card
          _buildInfoCard(
            title: 'Personal Details',
            icon: Icons.person_outline,
            children: [
              _buildInfoRow('Full Name', _userProfile?.name ?? ''),
              _buildInfoRow('Email', _userProfile?.email ?? ''),
              _buildInfoRow('Phone Number', _userProfile?.phone ?? ''),
              _buildInfoRow('Gender', _userProfile?.gender ?? ''),
            ],
          ),
          const SizedBox(height: 16),

          // Hostel Details Card
          _buildInfoCard(
            title: 'Hostel Details',
            icon: Icons.apartment_outlined,
            children: [
              _buildInfoRow('Hostel Block', _userProfile?.hostelBlock ?? ''),
              _buildInfoRow('Room Number', _userProfile?.roomNumber ?? ''),
              _buildInfoRow('Mess Type', _userProfile?.messType ?? ''),
              _buildInfoRow(
                'Membership Status',
                _userProfile?.membershipStatus ?? '',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mess Plan Payment Card
          _buildInfoCard(
            title: 'Mess Plan Payment',
            icon: Icons.payment_outlined,
            onTap: _showPlanDetailsDialog,
            children: [
              _buildBalanceRow(),
              _buildInfoRow(
                'Last Payment',
                '₹${_userProfile?.lastPayment.toStringAsFixed(2) ?? '0.00'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    VoidCallback? onTap,
  }) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    if (onTap != null) ...[
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlanDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          PlanDetailsDialog(messType: _userProfile?.messType ?? 'Standard'),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow() {
    final double targetAmount = 3500;
    final double currentAmount = _userProfile?.currentBalance ?? 0;
    final double progress = (currentAmount / targetAmount).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount Paid (Mess Plan)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '₹${currentAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' / ₹${targetAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _rechargeWallet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: NeumorphicStyle.buttonDecoration(
                    context,
                    borderRadius: 20,
                    color: AppColors.accent,
                  ),
                  child: Text(
                    'Pay Now',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      QuickAction(
        icon: Icons.edit_outlined,
        label: 'Edit Profile',
        onTap: _editProfile,
      ),
      QuickAction(
        icon: Icons.lock_outline,
        label: 'Change Password',
        onTap: _changePassword,
      ),
      QuickAction(
        icon: Icons.badge_outlined,
        label: 'Download ID',
        onTap: _downloadID,
      ),
      QuickAction(
        icon: Icons.receipt_outlined,
        label: 'View Receipts',
        onTap: _viewReceipts,
      ),
      QuickAction(
        icon: Icons.support_agent_outlined,
        label: 'Contact Support',
        onTap: _contactSupport,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: actions.map((action) {
              return SizedBox(
                width:
                    (MediaQuery.of(context).size.width - 32 - 32) /
                    3, // 3 items per row, accounting for padding and spacing
                child: _buildQuickActionButton(action),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 24, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final settings = [
      SettingItem(
        icon: Icons.feedback_outlined,
        label: 'Feedback Form',
        onTap: () {
          context.push('/feedback');
        },
      ),
      SettingItem(
        icon: Icons.contact_phone_outlined,
        label: 'Contact Canteen Manager',
        onTap: () {
          _showContactDialog(
            'Canteen Manager',
            'Mr. Sandeep Tambe',
            '9860630677',
          );
        },
      ),
      SettingItem(
        icon: Icons.admin_panel_settings_outlined,
        label: 'Warden Info',
        onTap: () {
          _showWardenDialog();
        },
      ),
      SettingItem(
        icon: Icons.code_outlined,
        label: 'Developer Info',
        onTap: () {
          _showDeveloperDialog();
        },
      ),
      SettingItem(
        icon: Icons.privacy_tip_outlined,
        label: 'Privacy Policy',
        onTap: () {
          context.push('/privacy');
        },
      ),
      SettingItem(
        icon: Icons.description_outlined,
        label: 'Terms of Service',
        onTap: () {
          context.push('/terms');
        },
      ),
      SettingItem(
        icon: Icons.logout_outlined,
        label: 'Logout',
        iconColor: AppColors.error,
        onTap: _logout,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: NeumorphicStyle.cardDecoration(
              context,
              borderRadius: 25,
            ),
            child: Column(
              children: settings.map((setting) {
                return _buildSettingItem(setting);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(SettingItem setting) {
    return GestureDetector(
      onTap: setting.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              setting.icon,
              size: 24,
              color: setting.iconColor ?? AppColors.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                setting.label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            if (setting.trailing != null) setting.trailing!,
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFFB0B0B0),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(String title, String name, String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(phone, style: GoogleFonts.roboto(fontSize: 16)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _launchDialer(phone);
              Navigator.pop(context);
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showWardenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Warden Info',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWardenItem(
              'Head Warden',
              'Mr. Vidyasheel Bagde',
              '+919823123845',
            ),
            const Divider(),
            _buildWardenItem('Boys Warden', 'Mr. Sharma', '+918619664663'),
            const Divider(),
            _buildWardenItem(
              'Girls Warden',
              'Ms. Sankareshwari',
              '+919423297439',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildWardenItem(String role, String name, String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _launchDialer(phone),
            child: Row(
              children: [
                const Icon(Icons.phone, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeveloperDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Developer Info',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
            const SizedBox(height: 16),
            Text(
              'Sujal Sadanand Khedekar',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Lead Developer & Creator',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondaryLight,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            _buildDeveloperLink(
              Icons.phone,
              '9359742537',
              () => _launchDialer('9359742537'),
            ),
            _buildDeveloperLink(
              Icons.email,
              'khedekarsujay720@gmail.com',
              () => _launchEmail('khedekarsujay720@gmail.com'),
            ),
            _buildDeveloperLink(
              Icons.link,
              'GitHub Profile',
              () => _launchUrl('https://github.com/Sujal-85'),
            ),
            _buildDeveloperLink(
              Icons.work,
              'LinkedIn Profile',
              () => _launchUrl(
                'https://www.linkedin.com/in/sujal-khedekar-a82b05293/',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperLink(IconData icon, String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.roboto(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header skeleton
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerEffect.circular(width: 100, height: 100),
                SizedBox(height: 16),
                ShimmerEffect.rectangular(
                  height: 24,
                  width: 150,
                  borderRadius: 12,
                ),
                SizedBox(height: 8),
                ShimmerEffect.rectangular(
                  height: 16,
                  width: 100,
                  borderRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info cards skeleton
          _buildInfoCardSkeleton(),
          const SizedBox(height: 16),
          _buildInfoCardSkeleton(),
          const SizedBox(height: 16),

          // Quick actions skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicStyle.cardDecoration(
              context,
              borderRadius: 25,
            ),
            child: Column(
              children: [
                const ShimmerEffect.rectangular(
                  height: 20,
                  width: 120,
                  borderRadius: 10,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: List.generate(5, (index) {
                    return Container(
                      decoration: NeumorphicStyle.cardDecoration(
                        context,
                        borderRadius: 20,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShimmerEffect.circular(width: 30, height: 30),
                          SizedBox(height: 8),
                          ShimmerEffect.rectangular(
                            height: 12,
                            width: 60,
                            borderRadius: 6,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardSkeleton() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerEffect.rectangular(
            height: 20,
            width: 150,
            borderRadius: 10,
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ShimmerEffect.rectangular(
                    height: 14,
                    width: 100,
                    borderRadius: 7,
                  ),
                  const ShimmerEffect.rectangular(
                    height: 14,
                    width: 150,
                    borderRadius: 7,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class UserProfile {
  final String name;
  final String collegeId;
  final String hostelBlock;
  final String roomNumber;
  final String email;
  final String phone;
  final String gender;
  final String messType;
  final String membershipStatus;
  final double currentBalance;
  final double lastPayment;
  final DateTime lastPaymentDate;
  final String? profileImage;

  UserProfile({
    required this.name,
    required this.collegeId,
    required this.hostelBlock,
    required this.roomNumber,
    required this.email,
    required this.phone,
    required this.gender,
    required this.messType,
    required this.membershipStatus,
    required this.currentBalance,
    required this.lastPayment,
    required this.lastPaymentDate,
    this.profileImage,
  });
}

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  QuickAction({required this.icon, required this.label, required this.onTap});
}

class SettingItem {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;

  SettingItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
    this.iconColor,
  });
}
