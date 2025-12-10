import 'dart:io';
import 'package:flutter/material.dart'; // Removed foundation import
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
  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _hostelNameController = TextEditingController();
  final TextEditingController _roomNoController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Keys
  final Map<int, GlobalKey<FormState>> _formKeys = {
    0: GlobalKey<FormState>(),
    1: GlobalKey<FormState>(),
    2: GlobalKey<FormState>(),
  };

  // State
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _showSuccess = false;
  XFile? _profileImage;
  DateTime? _selectedDate;

  // Toggles
  bool _isHostelite = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Verification
  bool _isPhoneVerified = false;
  String? _verificationId;

  // Services
  final AuthService _authService = AuthService();

  // Password Strength
  double _passwordStrength = 0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;

  Future<void> _submitForm() async {
    // Explicitly dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKeys[2]!.currentState!.validate()) return;

    // Final check logic
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your phone number in Step 2'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload Image
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await CloudinaryService().uploadImage(_profileImage!);
      }

      // 2. Register
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
        'isEmailVerified': true, // Trusted as per requirements
        'isPhoneVerified': true, // Enforced by UI
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // DEV BYPASS: Allow 9876543210 to skip Firebase (useful if blocked)
    if (phone == '9876543210') {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      setState(() {
        _isPhoneVerified = true;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dev Mode Bypass: Verified!'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          setState(() {
            _isPhoneVerified = true;
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verified Automatically!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Verification Failed'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isSubmitting = false;
          });
          _showOtpDialog();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showOtpDialog() {
    _otpController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Verify Mobile',
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the 6-digit code sent to ${_phoneController.text}',
              style: TextStyle(color: AppColors.textSecondary(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final otp = _otpController.text.trim();
              if (otp.length != 6) return;
              Navigator.pop(context);

              setState(() => _isSubmitting = true);
              final res = await _authService.verifyMobileOtp(
                _verificationId ?? '',
                otp,
              );
              setState(() => _isSubmitting = false);

              if (res['success']) {
                setState(() => _isPhoneVerified = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone Verified!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message']),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Verify', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
              'Success!',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Student ID:',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 8),
            SelectableText(
              studentId,
              style: GoogleFonts.robotoMono(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please screenshot this ID.',
              style: TextStyle(fontSize: 12, color: AppColors.error),
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

  @override
  Widget build(BuildContext context) {
    // Stepper Color Logic
    Color activeColor = AppColors.primary;
    Color inactiveColor = AppColors.textSecondary(context).withOpacity(0.3);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Registration',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(context)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Custom Stepper Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildStepIcon(0, Icons.person_outline),
                    _buildStepLine(0),
                    _buildStepIcon(1, Icons.verified_user_outlined),
                    _buildStepLine(1),
                    _buildStepIcon(2, Icons.lock_outline),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKeys[_currentStep],
                    child: _buildCurrentStep(),
                  ),
                ),
              ),

              // Navigation Buttons
              Container(
                padding: const EdgeInsets.all(24),
                color: AppColors.surface(context),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
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
                          child: Text(
                            'Back',
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentStep == 1 && !_isPhoneVerified) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please verify your phone number first',
                                ),
                              ),
                            );
                            return;
                          }

                          if (_formKeys[_currentStep]!.currentState!
                              .validate()) {
                            if (_currentStep < 2) {
                              setState(() => _currentStep++);
                            } else {
                              _submitForm();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          _currentStep == 2 ? 'Create Account' : 'Next',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

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

  // Custom Stepper Components
  Widget _buildStepIcon(int step, IconData icon) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;
    bool isCompleted = _currentStep > step;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCurrent ? 48 : 40,
      height: isCurrent ? 48 : 40,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.background(context),
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : AppColors.textSecondary(context).withOpacity(0.3),
        ),
      ),
      child: Icon(
        isCompleted ? Icons.check : icon,
        color: isActive ? Colors.white : AppColors.textSecondary(context),
        size: isCurrent ? 24 : 20,
      ),
    );
  }

  Widget _buildStepLine(int index) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > index
            ? AppColors.primary
            : AppColors.textSecondary(context).withOpacity(0.2),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildIdentityStep();
      case 1:
        return _buildVerificationStep();
      case 2:
        return _buildSecurityStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Identity & Residence
  Widget _buildIdentityStep() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) setState(() => _profileImage = image);
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surface(context),
                  backgroundImage: _profileImage != null
                      ? FileImage(File(_profileImage!.path))
                      : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(_fullNameController, 'Full Name', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(
          _emailController,
          'Email Address',
          Icons.email_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Email is required';
            final emailRegex = RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
            );
            if (!emailRegex.hasMatch(value)) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Date Picker
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(
                const Duration(days: 365 * 18),
              ),
              firstDate: DateTime(1990),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
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
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Date of Birth',
                  style: TextStyle(
                    color: _selectedDate != null
                        ? AppColors.textPrimary(context)
                        : AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Hostel Switch
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHostelite ? AppColors.primary : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
            ],
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  'I live in College Hostel',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Enable if you stay in the campus hostel',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                value: _isHostelite,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _isHostelite = v),
              ),
              if (_isHostelite) ...[
                const Divider(),
                const SizedBox(height: 8),
                _buildTextField(
                  _hostelNameController,
                  'Hostel Name',
                  Icons.apartment,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _roomNoController,
                  'Room Number',
                  Icons.door_front_door_outlined,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // STEP 2: Verification
  Widget _buildVerificationStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.phonelink_ring_outlined,
          size: 80,
          color: AppColors.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Mobile Verification',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We need to verify your phone number to secure your account.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _phoneController,
                'Phone Number',
                Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isPhoneVerified ? null : _verifyPhone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPhoneVerified
                      ? AppColors.success
                      : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isPhoneVerified
                    ? const Icon(Icons.check, color: Colors.white)
                    : const Text(
                        'Send OTP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        if (_isPhoneVerified)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Phone Verified Successfully',
                  style: GoogleFonts.inter(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Password Criteria
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigits = false;
  bool _hasSpecialChars = false;

  void _checkPasswordStrength(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigits = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      double strength = 0;
      if (_hasMinLength) strength += 0.2;
      if (_hasUppercase) strength += 0.2;
      if (_hasLowercase) strength += 0.2;
      if (_hasDigits) strength += 0.2;
      if (_hasSpecialChars) strength += 0.2;

      _passwordStrength = strength;
      if (strength <= 0.2) {
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (strength <= 0.6) {
        _passwordStrengthText = 'Medium';
        _passwordStrengthColor = Colors.orange;
      } else {
        _passwordStrengthText = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  // STEP 3: Security
  Widget _buildSecurityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create a Strong Password',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          _passwordController,
          'Password',
          Icons.lock_outline,
          obscureText: _obscurePassword,
          onChanged: _checkPasswordStrength,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary(context),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),

        // Password Criteria Checklist
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCriteriaChip('Min 8 characters are required', _hasMinLength),
            _buildCriteriaChip(
              'Atleast 1 Uppercase letter is required.',
              _hasUppercase,
            ),
            _buildCriteriaChip(
              'Atleast 1 Lowercase letter is required.',
              _hasLowercase,
            ),
            _buildCriteriaChip('Atleast 1 Number is required.', _hasDigits),
            _buildCriteriaChip(
              'Atleast 1 Symbol is required.',
              _hasSpecialChars,
            ),
          ],
        ),

        const SizedBox(height: 16),
        // Strength Meter
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: Colors.grey.withOpacity(0.2),
            color: _passwordStrengthColor,
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _passwordStrengthText,
            style: TextStyle(
              color: _passwordStrengthColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          _confirmPasswordController,
          'Confirm Password',
          Icons.lock,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary(context),
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          validator: (v) =>
              v != _passwordController.text ? 'Passwords do not match' : null,
        ),
      ],
    );
  }

  Widget _buildCriteriaChip(String label, bool isMet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isMet
            ? AppColors.success.withOpacity(0.1)
            : AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMet
              ? AppColors.success
              : AppColors.textSecondary(context).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet ? AppColors.success : AppColors.textSecondary(context),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
              color: isMet
                  ? AppColors.success
                  : AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.textPrimary(context)),
      validator: validator ?? (v) => v!.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary(context)),
        prefixIcon: Icon(icon, color: AppColors.textSecondary(context)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary(context).withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
