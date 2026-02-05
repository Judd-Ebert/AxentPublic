import 'package:flutter/material.dart';

/// Professional page transitions for onboarding flow
class PageTransitions {
  
  /// Smooth fade transition with slight slide - for main forward navigation
  static PageRouteBuilder fadeSlideTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    Offset slideOffset = const Offset(0.3, 0.0), // Slide from right
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Primary animation curves for smooth, professional feel
        final slideAnimation = Tween<Offset>(
          begin: slideOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic, // Professional easing
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));

        // Reverse animation for page being replaced
        final reverseFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOut,
        ));

        return Stack(
          children: [
            // Outgoing page with fade out
            if (secondaryAnimation.status != AnimationStatus.dismissed)
              FadeTransition(
                opacity: reverseFadeAnimation,
                child: Container(), // Placeholder for outgoing page
              ),
            // Incoming page with slide + fade
            SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Gentle fade transition - for seamless switches like login/signup
  static PageRouteBuilder fadeTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeInAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));

        final fadeOutAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOut,
        ));

        return Stack(
          children: [
            // Outgoing page fade out
            if (secondaryAnimation.status != AnimationStatus.dismissed)
              FadeTransition(
                opacity: fadeOutAnimation,
                child: Container(),
              ),
            // Incoming page fade in
            FadeTransition(
              opacity: fadeInAnimation,
              child: child,
            ),
          ],
        );
      },
    );
  }

  /// Slide transition for directional navigation
  static PageRouteBuilder slideTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    SlideDirection direction = SlideDirection.rightToLeft,
  }) {
    Offset beginOffset;
    switch (direction) {
      case SlideDirection.rightToLeft:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.leftToRight:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.bottomToTop:
        beginOffset = const Offset(0.0, 1.0);
        break;
      case SlideDirection.topToBottom:
        beginOffset = const Offset(0.0, -1.0);
        break;
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        // Parallax effect for outgoing page
        final reverseSlideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(-beginOffset.dx * 0.3, -beginOffset.dy * 0.3),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInCubic,
        ));

        return Stack(
          children: [
            // Outgoing page with subtle parallax
            if (secondaryAnimation.status != AnimationStatus.dismissed)
              SlideTransition(
                position: reverseSlideAnimation,
                child: Container(),
              ),
            // Incoming page
            SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          ],
        );
      },
    );
  }
}

/// Direction enum for slide transitions
enum SlideDirection {
  rightToLeft,
  leftToRight,
  bottomToTop,
  topToBottom,
}
