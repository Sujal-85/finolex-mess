import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/animations/famt_loader.dart';
import '../widgets/animations/success_confetti.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../theme/colors.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _hostelNameController = TextEditingController();
  final TextEditingController _roomNoController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final Map<int, GlobalKey<FormState>> _formKeys = <int, GlobalKey<FormState>>{
    0: GlobalKey<FormState>(),
    1: GlobalKey<FormState>(),
    2: GlobalKey<FormState>(),
  };

  XFile? _profileImage;
  DateTime? _selectedDate;
  bool _isSubmitting = false;
  bool _showSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isHostelite = false;
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  int _currentStep = 0;

  final AuthService _authService = AuthService();

  Future<void> _submitForm() async {
    if (!_formKeys[2]!.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Date of Birth')),
      );
      return;
    }
    if (!_isEmailVerified || !_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify both Email & Phone')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await CloudinaryService().uploadImage(_profileImage!);
      }

      final response = await _authService.signup({
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'dob': _selectedDate?.toIso8601String(),
        'profileImage': imageUrl,
        'hostelDetails': {
          'isHostelite': _isHostelite,
          'hostelName': _isHostelite ? _hostelNameController.text.trim() : '',
          'roomNo': _isHostelite ? _roomNoController.text.trim() : '',
        },
      });

      if (response['success']) {
        setState(() {
          _isSubmitting = false;
          _showSuccess = true;
        });

        await Future.delayed(const Duration(seconds: 4));
        if (!mounted) return;
        context.go('/login');
        _showSuccessDialog(response['studentId']);
      } else {
        throw response['message'] ?? 'Registration failed';
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showSuccessDialog(String studentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 32),
            const SizedBox(width: 12),
            Text(
              'Registered Successfully!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Student ID:',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              studentId,
              style: GoogleFonts.robotoMono(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Use this ID or your email to log in.',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => context.pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String? _verificationId;

  Future<void> _verifyContact(String type) async {
    final controller = type == 'email' ? _emailController : _phoneController;
    final value = controller.text.trim();
    if (value.isEmpty) return;

    setState(() => _isSubmitting = true);

    if (type == 'mobile') {
      // Firebase Phone Auth
      await _authService.verifyPhoneNumber(
        phoneNumber: '+91$value', // Prepending +91 for India, adjust if needed
        verificationCompleted: (PhoneAuthCredential credential) async {
          setState(() {
            _isPhoneVerified = true;
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone verified automatically!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Verification failed'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isSubmitting = false;
          });
          _showOtpDialog(type, value);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() => _verificationId = verificationId);
          }
        },
      );
      return;
    }

    // EMAIL OTP Verification
    final success = await _authService.sendEmailOtp(value);
    setState(() => _isSubmitting = false);

    if (success['success']) {
      _showOtpDialog(type, value);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showOtpDialog(String type, String contact) {
    bool isEmail = type == 'email';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEmail ? 'Verify Email' : 'Verify Phone',
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEmail)
              Text(
                'A verification code has been sent to $contact.\nPlease check your inbox/spam and enter the code below.',
                style: TextStyle(color: AppColors.textSecondary(context)),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Enter the 6-digit OTP sent to $contact',
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppColors.textPrimary(context)),
              decoration: InputDecoration(
                hintText: 'Enter 6-digit OTP',
                hintStyle: TextStyle(color: AppColors.textSecondary(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.textSecondary(context).withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          ),
          if (isEmail)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final otp = _otpController.text.trim();
                // We'll support 6 digit OTP
                if (otp.length != 6) return;

                Navigator.pop(context);
                _otpController.clear();

                setState(() => _isSubmitting = true);
                final verified = await _authService.verifyEmailOtp(
                  contact,
                  otp,
                );

                setState(() => _isSubmitting = false);

                if (verified['success']) {
                  setState(() => _isEmailVerified = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email verified!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  _showOtpDialog(type, contact); // Re-show dialog on error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(verified['message']),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text(
                'Verify Email',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final otp = _otpController.text.trim();
                if (otp.length != 6) return;

                Navigator.pop(context);
                _otpController.clear(); // Clear OTP field

                setState(() => _isSubmitting = true);
                Map<String, dynamic> verified;

                // Firebase Phone Verify
                verified = await _authService.verifyMobileOtp(
                  _verificationId ?? '',
                  otp,
                );

                setState(() => _isSubmitting = false);

                if (verified['success']) {
                  setState(() => _isPhoneVerified = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone verified!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  _showOtpDialog(type, contact); // Re-show dialog on failure
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(verified['message']),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text(
                'Verify',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Student Registration',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: AppColors.surface(context),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 4,
              ),

              // Step Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _getStepTitle(_currentStep),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Step ${_currentStep + 1} of 3',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKeys[_currentStep],
                    child: _buildCurrentStep(),
                  ),
                ),
              ),

              // Bottom Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.textSecondary(context).withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: AppColors.textSecondary(
                                context,
                              ).withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => setState(() => _currentStep--),
                          child: Text(
                            'Back',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (_currentStep < 2) {
                            if (_formKeys[_currentStep]!.currentState!
                                .validate()) {
                              setState(() => _currentStep++);
                            }
                          } else {
                            _submitForm();
                          }
                        },
                        child: Text(
                          _currentStep == 2 ? 'Create Account' : 'Next',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Overlays
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(child: FamtLoader()),
            ),

          if (_showSuccess)
            Container(
              color: Colors.black54,
              child: Center(child: SuccessConfetti(onCompleted: () {})),
            ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Details';
      case 1:
        return 'Hostel Information';
      case 2:
        return 'Security';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalStep();
      case 1:
        return _buildHostelStep();
      case 2:
        return _buildSecurityStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPersonalStep() => Column(
    children: [
      _buildProfileImagePicker(),
      const SizedBox(height: 32),
      _buildTextField(_fullNameController, 'Full Name', Icons.person_outline),
      const SizedBox(height: 20),
      // Date of Birth Picker
      GestureDetector(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(
              const Duration(days: 365 * 18),
            ),
            firstDate: DateTime(1990),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surface(context),
                    onSurface: AppColors.textPrimary(context),
                  ),
                  dialogTheme: DialogThemeData(
                    backgroundColor: AppColors.surface(context),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _selectedDate = picked;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textSecondary(context).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.textSecondary(context),
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                _selectedDate == null
                    ? 'Date of Birth'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                style: GoogleFonts.inter(
                  color: _selectedDate == null
                      ? AppColors.textSecondary(context)
                      : AppColors.textPrimary(context),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              _emailController,
              'Email Address',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(width: 10),
          _verifyButton('email', _isEmailVerified),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              _phoneController,
              'Phone Number',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(width: 10),
          _verifyButton('mobile', _isPhoneVerified),
        ],
      ),
    ],
  );

  Widget _buildHostelStep() => Column(
    children: [
      SwitchListTile(
        title: Text(
          'I stay in college hostel',
          style: TextStyle(fontSize: 17, color: AppColors.textPrimary(context)),
        ),
        value: _isHostelite,
        activeThumbColor: AppColors.primary,
        onChanged: (v) => setState(() => _isHostelite = v),
      ),
      if (_isHostelite) ...[
        const SizedBox(height: 20),
        _buildTextField(_hostelNameController, 'Hostel Name', Icons.apartment),
        const SizedBox(height: 20),
        _buildTextField(
          _roomNoController,
          'Room Number',
          Icons.door_front_door_outlined,
        ),
      ],
    ],
  );

  Widget _buildSecurityStep() => Column(
    children: [
      _buildTextField(
        _passwordController,
        'Create Password',
        Icons.lock_outline,
        obscureText: _obscurePassword,
        suffixIcon: _togglePasswordVisibility(
          () => _obscurePassword = !_obscurePassword,
        ),
      ),
      const SizedBox(height: 20),
      _buildTextField(
        _confirmPasswordController,
        'Confirm Password',
        Icons.lock_outline,
        obscureText: _obscureConfirmPassword,
        suffixIcon: _togglePasswordVisibility(
          () => _obscureConfirmPassword = !_obscureConfirmPassword,
        ),
        validator: (v) =>
            v != _passwordController.text ? 'Passwords do not match' : null,
      ),
    ],
  );

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: AppColors.textPrimary(context)),
      validator: validator ?? (v) => v!.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary(context)),
        prefixIcon: Icon(
          icon,
          color: AppColors.textSecondary(context),
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary(context).withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary(context).withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _togglePasswordVisibility(VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        _obscurePassword ? Icons.visibility_off : Icons.visibility,
        color: AppColors.textSecondary(context),
      ),
      onPressed: onTap,
    );
  }

  Widget _verifyButton(String type, bool verified) {
    return SizedBox(
      width: 80,
      child: verified
          ? const Icon(Icons.check_circle, color: AppColors.success, size: 32)
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: AppColors.primary),
              ),
              onPressed: () => _verifyContact(type),
              child: const Text('Verify', style: TextStyle(fontSize: 13)),
            ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: _profileImage == null
                  ? Container(
                      color: AppColors.surface(context),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.textSecondary(context),
                      ),
                    )
                  : (kIsWeb
                        ? Image.network(_profileImage!.path, fit: BoxFit.cover)
                        : Image.file(
                            File(_profileImage!.path),
                            fit: BoxFit.cover,
                          )),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (image != null) setState(() => _profileImage = image);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
