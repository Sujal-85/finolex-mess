import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/profile_style_header.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _commentController = TextEditingController();

  // Animation controllers
  // Animation controllers
  late AnimationController _cardController;
  late Animation<double> _cardFadeAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late AnimationController _successController;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successFadeAnimation;

  // State variables
  int _selectedRating = -1; // -1 means no selection
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;
  bool _showSuccess = false;
  XFile? _selectedImage;
  final AuthService _authService = AuthService();

  // Mock data
  final List<Map<String, dynamic>> _emojis = [
    {'emoji': '😡', 'label': 'Very poor', 'color': Colors.red},
    {'emoji': '😕', 'label': 'Poor', 'color': Colors.orange},
    {'emoji': '😐', 'label': 'Okay', 'color': Colors.yellow},
    {'emoji': '🙂', 'label': 'Good', 'color': Colors.lightGreen},
    {'emoji': '😍', 'label': 'Excellent', 'color': Colors.green},
  ];

  final List<String> _tags = [
    'Food',
    'Quality',
    'Hygiene',
    'Cleanliness',
    'Staff',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    // Initialize animations
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardFadeAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );

    _cardSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _successScaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOutBack,
    );

    _successFadeAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOut,
    );

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _cardController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _selectRating(int index) {
    setState(() {
      _selectedRating = index;
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  String _mapTagToType() {
    if (_selectedTags.isEmpty) return 'Other';
    final tag = _selectedTags.first;
    switch (tag) {
      case 'Food':
      case 'Quality':
        return 'Food Quality';
      case 'Hygiene':
      case 'Cleanliness':
        return 'Hygiene';
      case 'Staff':
        return 'Staff Behavior';
      default:
        return 'Other';
    }
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await _authService.getUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      String? imageUrl;
      if (_selectedImage != null) {
        final cloudinary = CloudinaryService();
        imageUrl = await cloudinary.uploadImage(_selectedImage!);
      }

      final api = ApiService();
      await api.post(
        '/feedback',
        data: {
          'studentId':
              user['id'], // Assuming user object has 'id' (which is _id from backend)
          'type': _mapTagToType(),
          'rating': _selectedRating + 1,
          'description': _commentController.text.trim().isEmpty
              ? 'No description provided'
              : _commentController.text.trim(),
          'images': imageUrl != null ? [imageUrl] : [],
        },
      );

      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
      });

      _successController.forward();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSuccess = false;
          });
          _successController.reset();
          context.pop();
        }
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header
                // Header
                ProfileStyleHeader(
                  title: 'Feedback',
                  showBackButton: true,
                  onBackTap: () => context.pop(),
                ),

                const SizedBox(height: 24),

                // Emoji rating slider
                _buildEmojiRatingSlider(),

                const SizedBox(height: 24),

                // Tags section
                _buildTagsSection(),

                const SizedBox(height: 24),

                // Comment box
                _buildCommentBox(),

                const SizedBox(height: 24),

                // Image Upload
                _buildImageUpload(),

                const SizedBox(height: 24),

                // Submit button
                _buildSubmitButton(),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Success overlay
          if (_showSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildEmojiRatingSlider() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How was your experience?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 20),

              // Emoji slider track
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_emojis.length, (index) {
                    final isSelected = _selectedRating == index;
                    return GestureDetector(
                      onTap: () => _selectRating(index),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: Matrix4.identity()
                              ..scale(isSelected ? 1.2 : 1.0),
                            child: Text(
                              _emojis[index]['emoji'],
                              style: TextStyle(
                                fontSize: 32,
                                shadows: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _emojis[index]['color']
                                              .withOpacity(0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _emojis[index]['label'],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? _emojis[index]['color']
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What did you like?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _tags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () => _toggleTag(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surface(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondaryLight.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentBox() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Additional Comments',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: NeumorphicStyle.cardDecoration(
                  context,
                  borderRadius: 20,
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: null,
                  minLines: 4,
                  keyboardType: TextInputType.multiline,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Share your feedback...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight.withOpacity(0.7),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEnabled = _selectedRating != -1;
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedScale(
            scale: _isSubmitting ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: isEnabled && !_isSubmitting ? _submitFeedback : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: isEnabled
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent,
                            AppColors.accent.withValues(alpha: 0.8),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.textSecondaryLight.withOpacity(0.3),
                            AppColors.textSecondaryLight.withOpacity(0.2),
                          ],
                        ),
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            backgroundColor: Colors.white.withOpacity(0.3),
                          ),
                        )
                      : Text(
                          'Submit Feedback',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isEnabled ? Colors.white : Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Stack(
        children: [
          // Confetti animation
          Lottie.asset(
            'assets/lottie/party propper.json',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          // Success card
          Center(
            child: ScaleTransition(
              scale: _successScaleAnimation,
              child: FadeTransition(
                opacity: _successFadeAnimation,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(30),
                  decoration: NeumorphicStyle.cardDecoration(
                    context,
                    borderRadius: 25,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Thank You!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your feedback helps us improve our mess service.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.textSecondaryLight,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUpload() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _cardFadeAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Photo (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectImage,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.textSecondaryLight.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                _selectedImage!.path,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.image),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 32,
                              color: AppColors.textSecondaryLight,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
