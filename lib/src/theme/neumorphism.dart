import 'package:flutter/material.dart';
import 'colors.dart';

class NeumorphicStyle {
  static BoxDecoration cardDecoration(
    BuildContext context, {
    double borderRadius = 20,
    bool isPressed = false,
    double shadowIntensity = 0.15,
    Color? color,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor =
        color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    // Subtle shadow for light mode, deeper for dark
    final Color shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : AppColors.shadowLight;
    final Color highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;

    if (isPressed) {
      return BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Inner shadow (top-left)
          BoxShadow(
            color: shadowColor,
            offset: const Offset(4, 4),
            blurRadius: 6,
            spreadRadius: -2, // Inset effect
          ),
          // Inner highlight (bottom-right)
          BoxShadow(
            color: highlightColor,
            offset: const Offset(-4, -4),
            blurRadius: 6,
            spreadRadius: -2, // Inset effect
          ),
        ],
      );
    }

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        // Drop shadow (bottom-right)
        BoxShadow(
          color: shadowColor,
          offset: const Offset(8, 8),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        // Highlight (top-left)
        BoxShadow(
          color: highlightColor,
          offset: const Offset(-8, -8),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static BoxDecoration buttonDecoration(
    BuildContext context, {
    double borderRadius = 12,
    bool isPressed = false,
    Color? color,
    double shadowIntensity = 0.4,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor =
        color ?? (isDark ? AppColors.primary : AppColors.primary);

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isPressed
          ? []
          : [
              BoxShadow(
                color: baseColor.withValues(alpha: shadowIntensity),
                offset: const Offset(4, 4),
                blurRadius: 8,
              ),
            ],
    );
  }
}
