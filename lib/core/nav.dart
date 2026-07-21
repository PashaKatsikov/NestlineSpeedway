import 'package:flutter/material.dart';

/// Pushes a screen with a gentle slide+fade transition.
Future<T?> pushScreen<T>(BuildContext context, Widget screen) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, animation, _) => screen,
      transitionsBuilder: (_, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}
