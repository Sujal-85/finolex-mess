import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppAnimations {
  // Durations
  static const Duration microInteraction = Duration(milliseconds: 200);
  static const Duration pageTransition = Duration(milliseconds: 500);
  static const Duration modalTransition = Duration(milliseconds: 400);
  static const Duration successAnimation = Duration(milliseconds: 800);
  static const Duration toastDuration = Duration(milliseconds: 2800);
  static const Duration toastSlide = Duration(milliseconds: 400);

  // Curves
  static const Curve microCurve = Curves.easeOutCubic;
  static const Curve pageCurve = Curves.easeInOutQuart;
  static const Curve bounceCurve = Curves.elasticOut;

  // Page Transitions
  static CustomTransitionPage<T> transitionPage<T>({
    required Widget child,
    required LocalKey key,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: pageCurve));
        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(CurveTween(curve: Curves.easeIn));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      transitionDuration: pageTransition,
    );
  }

  static PageRouteBuilder<T> fadeSlideTransition<T>({required Widget page}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: pageCurve));
        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(CurveTween(curve: Curves.easeIn));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      transitionDuration: pageTransition,
    );
  }
}
