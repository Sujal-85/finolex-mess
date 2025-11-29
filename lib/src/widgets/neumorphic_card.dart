import 'package:flutter/material.dart';

import '../theme/neumorphism.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: NeumorphicStyle.cardDecoration(
          context,
          borderRadius: borderRadius,
          color: backgroundColor,
        ),
        child: child,
      ),
    );
  }
}
