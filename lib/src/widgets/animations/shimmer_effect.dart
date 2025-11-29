import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class ShimmerEffect extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final ShapeBorder shape;

  const ShimmerEffect.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  }) : shape = const RoundedRectangleBorder();

  const ShimmerEffect.circular({
    super.key,
    required this.width,
    required this.height,
  }) : shape = const CircleBorder(),
       borderRadius = 0;

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Accessibility check
    if (MediaQuery.of(context).disableAnimations) {
      return _buildStaticPlaceholder();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppColors.surface(context),
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.surface(context),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 - (_controller.value * 2.0), -0.3),
              end: Alignment(1.0 - (_controller.value * 2.0), 0.3),
              transform: _SlidingGradientTransform(percent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: _buildStaticPlaceholder(),
    );
  }

  Widget _buildStaticPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: ShapeDecoration(
        color: AppColors.surface(context).withValues(alpha: 0.5), // Base color
        shape: widget.shape is RoundedRectangleBorder
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              )
            : widget.shape,
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.percent});

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0.0, 0.0);
  }
}
