import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/animations/shimmer_effect.dart';

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

  // Mock user data
  final UserProfile _userProfile = UserProfile(
    name: 'John Doe',
    collegeId: 'FAMT/2023/001',
    hostelBlock: 'A Block',
    roomNumber: '101',
    email: 'john.doe@famt.edu',
    phone: '+91 98765 43210',
    gender: 'Male',
    messType: 'Vegetarian',
    membershipStatus: 'Active',
    currentBalance: 1250.75,
    lastPayment: 500.00,
    lastPaymentDate: DateTime.now().subtract(const Duration(days: 3)),
  );

  bool _isLoading = false;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations after a small delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
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
        content: Text('Edit photo functionality would open here'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _editProfile() {
    // Navigate to edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit profile screen would open here'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _changePassword() {
    // Navigate to change password screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change password screen would open here'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _downloadID() {
    // Download ID functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID downloaded successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _viewReceipts() {
    // Navigate to receipts screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipts screen would open here'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _contactSupport() {
    // Open support chat or email
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support contact would open here'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _rechargeWallet() {
    // Navigate to recharge screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recharge screen would open here'),
        backgroundColor: AppColors.primary,
      ),
    );
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
            style: GoogleFonts.roboto(
              color: AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // In a real app, this would clear user session and navigate to login
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
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
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Header section
                  _buildHeaderSection(),

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
                ],
              ),
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
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
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
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Icon(
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
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
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
                _userProfile.name,
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
                    _userProfile.collegeId,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.verified,
                    size: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Hostel and room info
              Text(
                '${_userProfile.hostelBlock}, Room ${_userProfile.roomNumber}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
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
              _buildInfoRow('Full Name', _userProfile.name),
              _buildInfoRow('Email', _userProfile.email),
              _buildInfoRow('Phone Number', _userProfile.phone),
              _buildInfoRow('Gender', _userProfile.gender),
            ],
          ),
          const SizedBox(height: 16),

          // Hostel Details Card
          _buildInfoCard(
            title: 'Hostel Details',
            icon: Icons.apartment_outlined,
            children: [
              _buildInfoRow('Hostel Block', _userProfile.hostelBlock),
              _buildInfoRow('Room Number', _userProfile.roomNumber),
              _buildInfoRow('Mess Type', _userProfile.messType),
              _buildInfoRow('Membership Status', _userProfile.membershipStatus),
            ],
          ),
          const SizedBox(height: 16),

          // Account Details Card
          _buildInfoCard(
            title: 'Account Details',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              _buildBalanceRow(),
              _buildInfoRow(
                'Last Payment',
                '₹${_userProfile.lastPayment.toStringAsFixed(2)}',
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
  }) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        decoration: NeumorphicStyle.cardDecoration(
          context,
          borderRadius: 25,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
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
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${_userProfile.currentBalance.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
                    'Recharge',
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
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 32) / 3;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: (itemWidth - 16) / 80,
                children: actions.map((action) {
                  return _buildQuickActionButton(action);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: NeumorphicStyle.cardDecoration(
          context,
          borderRadius: 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              size: 24,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final settings = [
      SettingItem(
        icon: Icons.language_outlined,
        label: 'Language',
        trailing: Text(
          'English',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
          ),
        ),
        onTap: () {
          // Language selection
        },
      ),
      SettingItem(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        trailing: Switch(
          value: true,
          onChanged: (value) {},
          activeColor: AppColors.primary,
        ),
        onTap: () {
          // Notification settings
        },
      ),
      SettingItem(
        icon: Icons.privacy_tip_outlined,
        label: 'Privacy & Terms',
        onTap: () {
          // Privacy policy and terms
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
            bottom: BorderSide(
              color: Color(0xFFE0E0E0),
              width: 0.5,
            ),
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
                ShimmerEffect.circular(
                  width: 100,
                  height: 100,
                ),
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
          _buildInfoCardSkeleton(),
          const SizedBox(height: 24),

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
                          ShimmerEffect.circular(
                            width: 30,
                            height: 30,
                          ),
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
      width: double.infinity,
      decoration: NeumorphicStyle.cardDecoration(
        context,
        borderRadius: 25,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
  });
}

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
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