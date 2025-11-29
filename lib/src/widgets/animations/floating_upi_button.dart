import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/animations.dart';

class FloatingUPIButton extends StatefulWidget {
  final VoidCallback onTap;

  const FloatingUPIButton({super.key, required this.onTap});

  @override
  State<FloatingUPIButton> createState() => _FloatingUPIButtonState();
}

class _FloatingUPIButtonState extends State<FloatingUPIButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.microInteraction,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.microCurve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded) ...[
          _buildOption(Icons.qr_code_scanner, 'Scan QR', () {
            _toggleExpand();
            widget.onTap();
          }),
          const SizedBox(height: 16),
          _buildOption(Icons.history, 'History', () {
            _toggleExpand();
            // Navigate to history
          }),
          const SizedBox(height: 16),
        ],
        FloatingActionButton.extended(
          onPressed: _toggleExpand,
          backgroundColor: AppColors.accent,
          icon: RotationTransition(
            turns: _expandAnimation.drive(
              Tween(begin: 0.0, end: 0.125),
            ), // 45 degrees
            child: const Icon(Icons.add, color: Colors.white),
          ),
          label: SizeTransition(
            sizeFactor: ReverseAnimation(_expandAnimation),
            axis: Axis.horizontal,
            child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(IconData icon, String label, VoidCallback onTap) {
    return ScaleTransition(
      scale: _expandAnimation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: onTap,
            backgroundColor: AppColors.surface(context),
            child: Icon(icon, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
