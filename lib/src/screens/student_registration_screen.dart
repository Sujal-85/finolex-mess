import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/animations/famt_loader.dart';
import '../widgets/animations/success_confetti.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen>
    with TickerProviderStateMixin {
  // Controllers for form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _collegeIdController = TextEditingController();
  final TextEditingController _hostelBlockController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedHostelBlock;
  File? _profileImage;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  // Animation controllers
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Verification status
  final VerificationStatus _verificationStatus = VerificationStatus.pending;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
      _fadeController.forward();

      // Auto-fill email from AuthBloc
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && authState.email != null) {
        setState(() {
          _emailController.text = authState.email!;
        });
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _collegeIdController.dispose();
    _hostelBlockController.dispose();
    _roomNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Handle form submission
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
      });

      // Hide success animation after delay and navigate to home
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSuccess = false;
          });

          // Mark registration as completed
          context.read<AuthBloc>().add(RegistrationCompleted());

          // Navigate to home screen
          context.go('/home');
        }
      });
    }
  }

  // Handle save draft
  void _saveDraft() {
    // Save form data locally
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // Handle image selection
  void _selectImage() {
    // In a real app, this would open image picker
    // For now, we'll simulate selecting an image
    setState(() {
      _profileImage = File(''); // Placeholder
    });
  }

  // Handle image removal
  void _removeImage() {
    setState(() {
      _profileImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.backgroundLight,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Header with logo and title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // FAMT Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface(context),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.school,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          'Student Registration',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        // Subtitle
                        Text(
                          'Only for Pre-Verified Students',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form container with slide animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: NeumorphicStyle.cardDecoration(
                        context,
                        borderRadius: 25,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pre-verification status card
                              _buildVerificationStatusCard(),

                              const SizedBox(height: 24),

                              // Profile image upload
                              _buildProfileImageUpload(),

                              const SizedBox(height: 24),

                              // Full Name
                              _buildNeumorphicTextField(
                                controller: _fullNameController,
                                hint: 'Full Name',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // College ID
                              _buildNeumorphicTextField(
                                controller: _collegeIdController,
                                hint: 'College ID / Roll Number',
                                icon: Icons.school_outlined,
                                keyboardType: TextInputType.text,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your college ID';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Hostel Block
                              _buildHostelBlockDropdown(),

                              const SizedBox(height: 16),

                              // Room Number
                              _buildNeumorphicTextField(
                                controller: _roomNumberController,
                                hint: 'Room Number',
                                icon: Icons.bedroom_child_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your room number';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Phone Number
                              _buildNeumorphicTextField(
                                controller: _phoneController,
                                hint: 'Phone Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  if (value.length != 10) {
                                    return 'Please enter a valid 10-digit phone number';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Email (auto-filled if possible)
                              _buildNeumorphicTextField(
                                controller: _emailController,
                                hint: 'Email (auto-filled if possible)',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                enabled: _emailController
                                    .text
                                    .isEmpty, // Disable if auto-filled
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 32),

                              // Action buttons
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Success confetti overlay
          if (_showSuccess)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: SuccessConfetti(
                    onCompleted: () {
                      setState(() {
                        _showSuccess = false;
                      });
                    },
                  ),
                ),
              ),
            ),

          // Loading overlay
          if (_isSubmitting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(child: FamtLoader()),
              ),
            ),
        ],
      ),
    );
  }

  // Build verification status card
  Widget _buildVerificationStatusCard() {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (_verificationStatus) {
      case VerificationStatus.pending:
        statusIcon = Icons.access_time_outlined;
        statusColor = AppColors.warning;
        statusText = 'Pending Verification';
        break;
      case VerificationStatus.approved:
        statusIcon = Icons.check_circle_outline;
        statusColor = AppColors.success;
        statusText = 'Approved';
        break;
      case VerificationStatus.rejected:
        statusIcon = Icons.cancel_outlined;
        statusColor = AppColors.error;
        statusText = 'Rejected';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.cardDecoration(
        context,
        borderRadius: 20,
        shadowIntensity: 0.1,
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pre-Verification Status',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (_verificationStatus == VerificationStatus.pending)
            Icon(
              Icons.waves,
              color: AppColors.primary.withOpacity(0.2),
              size: 40,
            ),
        ],
      ),
    );
  }

  // Build profile image upload widget
  Widget _buildProfileImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Photo',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Stack(
            children: [
              // Profile image or placeholder
              GestureDetector(
                onTap: _selectImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface(context),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 12,
                        offset: const Offset(4, 4),
                      ),
                      BoxShadow(
                        color: Colors.white,
                        blurRadius: 12,
                        offset: const Offset(-4, -4),
                      ),
                    ],
                  ),
                  child: _profileImage != null
                      ? ClipOval(
                          // Use platform-appropriate image widget
                          child: kIsWeb
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.textSecondaryLight,
                                )
                              : Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.textSecondaryLight,
                                    );
                                  },
                                ),
                        )
                      : Icon(
                          Icons.person_outline,
                          size: 50,
                          color: AppColors.textSecondaryLight,
                        ),
                ),
              ),

              // Edit/Remove buttons
              if (_profileImage != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: AppColors.textSecondaryLight,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _selectImage();
                        } else if (value == 'remove') {
                          _removeImage();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Build neumorphic text field
  Widget _buildNeumorphicTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: NeumorphicStyle.cardDecoration(
        context,
        borderRadius: 20,
        shadowIntensity: enabled ? 0.1 : 0.05,
        color: enabled ? null : AppColors.background(context),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        validator: validator,
        style: GoogleFonts.roboto(
          fontSize: 16,
          color: AppColors.textPrimary(context),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.roboto(
            fontSize: 16,
            color: AppColors.textSecondaryLight.withOpacity(0.7),
          ),
          prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // Build hostel block dropdown
  Widget _buildHostelBlockDropdown() {
    final hostelBlocks = ['A Block', 'B Block', 'C Block', 'D Block'];

    return Container(
      decoration: NeumorphicStyle.cardDecoration(
        context,
        borderRadius: 20,
        shadowIntensity: 0.1,
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedHostelBlock,
        hint: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: [
              Icon(
                Icons.apartment_outlined,
                color: AppColors.primary.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Hostel Block',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: AppColors.textSecondaryLight.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        items: hostelBlocks.map((String block) {
          return DropdownMenuItem<String>(
            value: block,
            child: Text(
              block,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: AppColors.textPrimary(context),
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedHostelBlock = newValue;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a hostel block';
          }
          return null;
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  // Build action buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Submit button
        GestureDetector(
          onTap: _isSubmitting ? null : _submitForm,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: NeumorphicStyle.buttonDecoration(
              context,
              borderRadius: 20,
              color: _isSubmitting
                  ? AppColors.textSecondaryLight
                  : AppColors.accent,
            ),
            child: Center(
              child: Text(
                'Submit Registration',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Save draft button
        GestureDetector(
          onTap: _saveDraft,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: NeumorphicStyle.cardDecoration(
              context,
              borderRadius: 20,
              shadowIntensity: 0.05,
            ),
            child: Center(
              child: Text(
                'Save Draft',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Verification status enum
enum VerificationStatus { pending, approved, rejected }
