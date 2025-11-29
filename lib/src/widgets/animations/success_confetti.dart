import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/animations.dart';

class SuccessConfetti extends StatefulWidget {
  final VoidCallback? onCompleted;

  const SuccessConfetti({super.key, this.onCompleted});

  @override
  State<SuccessConfetti> createState() => _SuccessConfettiState();
}

class _SuccessConfettiState extends State<SuccessConfetti>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.successAnimation,
    );

    _particles = List.generate(20, (index) => ConfettiParticle());

    _controller.forward().then((_) {
      widget.onCompleted?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(
                  particles: _particles,
                  progress: _controller.value,
                  color: AppColors.primary,
                  accent: AppColors.accent,
                ),
                size: const Size(200, 200),
              );
            },
          ),
          // Tick
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiParticle {
  final double angle;
  final double distance;
  final double size;
  final bool isAccent;

  ConfettiParticle()
    : angle = Random().nextDouble() * 2 * pi,
      distance = Random().nextDouble() * 80 + 20,
      size = Random().nextDouble() * 4 + 2,
      isAccent = Random().nextBool();
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;
  final Color color;
  final Color accent;

  ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.color,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      final currentDistance =
          particle.distance * Curves.easeOutCubic.transform(progress);
      final dx = center.dx + currentDistance * cos(particle.angle);
      final dy = center.dy + currentDistance * sin(particle.angle);

      // Fade out at the end
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = (particle.isAccent ? accent : color).withValues(
        alpha: opacity,
      );

      canvas.drawCircle(Offset(dx, dy), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
