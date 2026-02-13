import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';

import 'complaint_history_screen.dart';
import '../widgets/profile_style_header.dart';
import '../services/auth_service.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  // Animation controllers

  // State variables
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _showAttachmentOptions = false;
  final List<String> _attachments = [];
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  int _currentStep =
      0; // 0: category, 1: description, 2: attachment, 3: submitting, 4: submitted
  String _selectedCategory = '';
  String _ticketId = '';
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _currentUser;

  // Mock data
  final List<String> _categories = [
    'Food Quality',
    'Cleanliness',
    'Staff Behavior',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
    });

    // Add initial bot message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addBotMessage('Hello! 👋 How can I help you today?');
      Future.delayed(const Duration(milliseconds: 1000), () {
        _addBotMessage(
          'What issue are you facing?',
          MessageType.categoryPicker,
        );
      });
    });
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, [MessageType type = MessageType.text]) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          sender: MessageSender.bot,
          type: type,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text, [MessageType type = MessageType.text]) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          sender: MessageSender.user,
          type: type,
          timestamp: DateTime.now(),
          attachments: List.from(_attachments),
        ),
      );
      _attachments.clear();
      _showAttachmentOptions = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _attachments.isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    if (_currentStep == 0) {
      // Category selection
      _addUserMessage(message, MessageType.category);
      _selectedCategory = message;
      setState(() {
        _currentStep = 1;
      });
      _addBotMessage('Please describe your problem in detail.');
    } else if (_currentStep == 1) {
      // Description
      _addUserMessage(message);
      setState(() {
        _currentStep = 2;
      });
      _addBotMessage(
        'Would you like to attach any images to support your complaint?',
        MessageType.attachmentPrompt,
      );
    } else if (_currentStep == 2) {
      // Handle attachment response
      _addUserMessage(message);
      if (message.toLowerCase().contains('yes') ||
          message.toLowerCase().contains('attach')) {
        _showAttachmentOptions = true;
      } else {
        _submitComplaint();
      }
    } else {
      // Regular message
      _addUserMessage(message);
    }
  }

  void _selectCategory(String category) {
    _messageController.text = category;
    _sendMessage();
  }

  void _submitComplaint() async {
    setState(() {
      _currentStep = 3; // submitting
      _isSending = true;
    });

    _addBotMessage('Submitting your complaint...', MessageType.submitting);

    try {
      List<String> imageUrls = [];
      // 1. Upload Images if exist
      if (_selectedImages.isNotEmpty) {
        final cloudinary = CloudinaryService();
        for (var image in _selectedImages) {
          final url = await cloudinary.uploadImage(image);
          if (url != null) {
            imageUrls.add(url);
          }
        }
      }

      // 2. Submit to Backend
      final api = ApiService();
      final response = await api.post(
        '/complaints',
        data: {
          'studentId': _currentUser?['id'] ?? 'Unknown',
          'studentName': _currentUser?['name'] ?? 'Unknown',
          'category': _getBackendCategory(_selectedCategory),
          'title': _selectedCategory,
          'subject': 'General Inquiry', // Default subject
          'priority': 'Medium',
          'internalNotes': [],
          'description': _messages
              .where(
                (m) =>
                    m.sender == MessageSender.user &&
                    m.type == MessageType.text,
              )
              .map((m) => m.text)
              .join('\n'),
          'images': imageUrls,
          'status': 'pending',
        },
      );

      final ticketId = response.data['_id'];

      setState(() {
        _isSending = false;
        _currentStep = 4; // submitted
        _ticketId = ticketId;
      });

      _addBotMessage(
        'Your complaint has been submitted successfully!\n\nTicket ID: $_ticketId',
        MessageType.ticketCreated,
      );

      // Add status tracking message
      Future.delayed(const Duration(milliseconds: 500), () {
        _addBotMessage('', MessageType.statusTracking);
      });
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      _addBotMessage('Failed to submit complaint. Please try again.');
      debugPrint('Error submitting complaint: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          // Header
          ProfileStyleHeader(
            title: 'Complaint Support',
            subtitle: 'Student ID: STU12345',
            showBackButton: true,
            onBackTap: () => context.pop(),
            actions: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ComplaintHistoryScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Chat messages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Chat messages list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
                  ),

                  // Attachment options
                  if (_showAttachmentOptions) _buildAttachmentOptions(),

                  // Typing indicator
                  if (_isSending)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Lottie.asset(
                        'assets/lottie/loading animation.json',
                        width: 50,
                        height: 30,
                      ),
                    ),

                  // Input area
                  _buildInputArea(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    final bubbleColor = isUser
        ? AppColors.primary
        : AppColors.surface(context).withOpacity(0.7);
    final textColor = isUser ? Colors.white : AppColors.textPrimary(context);

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Message container
        Container(
          margin: EdgeInsets.only(
            left: isUser ? 60 : 0,
            right: isUser ? 0 : 60,
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Bubble
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft: Radius.circular(isUser ? 24 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content based on type
                    if (message.type == MessageType.categoryPicker)
                      _buildCategoryPicker()
                    else if (message.type == MessageType.attachmentPrompt)
                      _buildAttachmentPrompt()
                    else if (message.type == MessageType.submitting)
                      _buildSubmittingMessage()
                    else if (message.type == MessageType.ticketCreated)
                      _buildTicketCreatedMessage(message.text)
                    else if (message.type == MessageType.statusTracking)
                      _buildStatusTrackingCard()
                    else if (message.type == MessageType.imageAttachment &&
                        message.attachments.isNotEmpty)
                      _buildImageAttachments(message.attachments)
                    else
                      Text(
                        message.text,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Timestamp
              Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What issue are you facing?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            return GestureDetector(
              onTap: () => _selectCategory(category),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: NeumorphicStyle.buttonDecoration(
                  context,
                  borderRadius: 20,
                  color: AppColors.primary,
                ),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttachmentPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Would you like to attach any images to support your complaint?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAttachmentOptions = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: NeumorphicStyle.buttonDecoration(
                    context,
                    borderRadius: 20,
                    color: AppColors.primary,
                  ),
                  child: Text(
                    'Yes, Attach',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _submitComplaint,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: NeumorphicStyle.cardDecoration(
                    context,
                    borderRadius: 20,
                  ),
                  child: Text(
                    'No, Submit',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmittingMessage() {
    return Row(
      children: [
        Lottie.asset(
          'assets/lottie/loading animation.json', // Placeholder for broken complaint_processing.lottie
          height: 50,
          width: 50,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
        ),
        const SizedBox(width: 12),
        Text(
          'Submitting your complaint...',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppColors.textPrimary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCreatedMessage(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.split('\n')[0],
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      message.split('\n')[2],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Open',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    _selectedCategory,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Submitted:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    _formatDate(DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _resetComplaint,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: NeumorphicStyle.buttonDecoration(
                    context,
                    borderRadius: 25,
                    color: AppColors.primary,
                  ),
                  child: Center(
                    child: Text(
                      'Start New Complaint',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTrackingCard() {
    final steps = ['Created', 'In Review', 'Resolved'];
    final icons = [Icons.check_circle, Icons.pending_actions, Icons.done_all];
    final timestamps = [
      DateTime.now().subtract(const Duration(hours: 2)),
      DateTime.now().subtract(const Duration(hours: 1)),
      null,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ticket Status Tracking',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final isActive = index <= _currentStep;
            final isCompleted = index < _currentStep;

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.success
                            : (isActive ? AppColors.primary : Colors.grey),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : icons[index],
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[index],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isCompleted
                                  ? AppColors.success
                                  : (isActive
                                        ? AppColors.textPrimary(context)
                                        : AppColors.textSecondaryLight),
                            ),
                          ),
                          if (timestamps[index] != null)
                            Text(
                              _formatDateTime(timestamps[index]!),
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Container(
                    height: 30,
                    width: 2,
                    margin: const EdgeInsets.only(left: 15),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success
                          : (isActive ? AppColors.primary : Colors.grey),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _attachImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
        _attachments.add(image.path);
      });
    }
  }

  Future<void> _attachFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        _attachments.addAll(images.map((e) => e.path));
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
      if (index < _selectedImages.length) {
        _selectedImages.removeAt(index);
      }
    });
  }

  Widget _buildImageAttachments(List<String> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final path = attachments[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: (path.startsWith('http') || kIsWeb)
                        ? NetworkImage(path)
                        : FileImage(File(path)) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => _removeAttachment(index),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_attachments.isNotEmpty) ...[
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _attachments.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(_attachments[index])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOptionButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: _attachImage,
              ),
              _buildOptionButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _attachFromGallery,
              ),
              if (_attachments.isNotEmpty)
                _buildOptionButton(
                  icon: Icons.check,
                  label: 'Done',
                  onTap: () {
                    setState(() {
                      _showAttachmentOptions = false;
                    });
                    _addUserMessage(
                      '${_attachments.length} Image${_attachments.length > 1 ? 's' : ''} attached',
                      MessageType.imageAttachment,
                    );
                  },
                  color: AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicStyle.buttonDecoration(
              context,
              borderRadius: 20,
              color: color ?? AppColors.primary,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Attachment button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showAttachmentOptions = !_showAttachmentOptions;
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: NeumorphicStyle.cardDecoration(
                    context,
                    borderRadius: 22,
                  ),
                  child: const Icon(Icons.add, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),

              // Message input
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: NeumorphicStyle.cardDecoration(
                    context,
                    borderRadius: 25,
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    maxLines: null,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: AppColors.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.roboto(
                        fontSize: 16,
                        color: AppColors.textSecondaryLight.withOpacity(0.7),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Send button
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: NeumorphicStyle.buttonDecoration(
                    context,
                    borderRadius: 22,
                    color: AppColors.primary,
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _resetComplaint() {
    setState(() {
      _messages.clear();
      _attachments.clear();
      _selectedImages.clear();
      _currentStep = 0;
      _selectedCategory = '';
      _ticketId = '';
    });

    // Add initial bot message again
    _addBotMessage('Hello! 👋 How can I help you today?');
    Future.delayed(const Duration(milliseconds: 1000), () {
      _addBotMessage('What issue are you facing?', MessageType.categoryPicker);
    });
  }

  String _getBackendCategory(String displayCategory) {
    switch (displayCategory) {
      case 'Food Quality':
        return 'food';
      case 'Staff Behavior':
        return 'service';
      case 'Cleanliness':
        return 'cleanliness';
      default:
        return 'other';
    }
  }
}

enum MessageSender { user, bot }

enum MessageType {
  text,
  category,
  categoryPicker,
  attachmentPrompt,
  imageAttachment,
  submitting,
  ticketCreated,
  statusTracking,
}

class ChatMessage {
  final String text;
  final MessageSender sender;
  final MessageType type;
  final DateTime timestamp;
  final List<String> attachments;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.type,
    required this.timestamp,
    this.attachments = const [],
  });
}
