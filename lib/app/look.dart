import 'package:flutter/material.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/face.dart';

class Look {
  Look._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Pigment.pitch,
      colorScheme: base.colorScheme.copyWith(
        primary: Pigment.amber,
        secondary: Pigment.racingBlue,
        surface: Pigment.asphalt,
        error: Pigment.bad,
        onPrimary: Pigment.inkOnLight,
        onSurface: Pigment.ink,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: Face.body,
        bodyColor: Pigment.ink,
        displayColor: Pigment.ink,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: Pigment.slate,
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: Pigment.amber,
        inactiveTrackColor: Pigment.slate,
        thumbColor: Pigment.amber,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Pigment.asphaltHi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Pigment.slateHi),
        ),
        textStyle: Face.text(12, color: Pigment.ink),
      ),
    );
  }
}

/// Shared corner radii and shadows so panels stay visually consistent.
class Corners {
  Corners._();

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
