import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Palette.pitch,
      colorScheme: base.colorScheme.copyWith(
        primary: Palette.amber,
        secondary: Palette.racingBlue,
        surface: Palette.asphalt,
        error: Palette.bad,
        onPrimary: Palette.inkOnLight,
        onSurface: Palette.ink,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: Type.body,
        bodyColor: Palette.ink,
        displayColor: Palette.ink,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: Palette.slate,
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: Palette.amber,
        inactiveTrackColor: Palette.slate,
        thumbColor: Palette.amber,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Palette.asphaltHi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Palette.slateHi),
        ),
        textStyle: Type.text(12, color: Palette.ink),
      ),
    );
  }
}

/// Shared corner radii and shadows so panels stay visually consistent.
class Shape {
  Shape._();

  static const double rSm = 10;
  static const double rMd = 16;
  static const double rLg = 22;

  static BorderRadius get sm => BorderRadius.circular(rSm);
  static BorderRadius get md => BorderRadius.circular(rMd);
  static BorderRadius get lg => BorderRadius.circular(rLg);

  static List<BoxShadow> lift([double strength = 1]) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35 * strength),
      blurRadius: 14 * strength,
      offset: Offset(0, 6 * strength),
    ),
  ];

  static List<BoxShadow> glow(Color c, [double strength = 1]) => [
    BoxShadow(
      color: c.withValues(alpha: 0.45 * strength),
      blurRadius: 18 * strength,
    ),
  ];
}
