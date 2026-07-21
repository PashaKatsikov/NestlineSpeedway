import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text styles + Material theme wiring. Fredoka (chunky) is used for display
/// headings & numbers, Nunito for body copy. Both are bundled for offline use.
class AppText {
  AppText._();

  static const String display = 'Fredoka';
  static const String body = 'Nunito';

  static TextStyle heading(double size,
          {Color color = AppColors.ink, double? height}) =>
      TextStyle(
        fontFamily: display,
        fontSize: size,
        color: color,
        height: height,
        letterSpacing: 0.2,
      );

  static TextStyle text(double size,
          {Color color = AppColors.inkSoft,
          FontWeight weight = FontWeight.w700,
          double? height}) =>
      TextStyle(
        fontFamily: body,
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AppText.body,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        primary: AppColors.gold,
        surface: AppColors.creamCard,
      ),
    );
    return base.copyWith(
      splashFactory: InkRipple.splashFactory,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
    );
  }
}
