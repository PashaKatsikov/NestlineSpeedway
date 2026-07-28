import 'package:flutter/material.dart';

import 'palette.dart';

/// Display type is Fredoka (the chunky racing voice), body copy is Nunito.
class Type {
  Type._();

  static const String display = 'Fredoka';
  static const String body = 'Nunito';

  static TextStyle title(
    double size, {
    Color color = Palette.ink,
    double spacing = 0.5,
  }) => TextStyle(
    fontFamily: display,
    fontSize: size,
    letterSpacing: spacing,
    height: 1.1,
    color: color,
  );

  static TextStyle text(
    double size, {
    Color color = Palette.inkSoft,
    FontWeight weight = FontWeight.w600,
    double height = 1.3,
  }) => TextStyle(
    fontFamily: body,
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
  );

  /// Tabular-ish numeric style for stat readouts.
  static TextStyle number(double size, {Color color = Palette.ink}) =>
      TextStyle(
        fontFamily: display,
        fontSize: size,
        color: color,
        letterSpacing: 0,
        height: 1.0,
      );

  static TextStyle label(double size, {Color color = Palette.inkMute}) =>
      TextStyle(
        fontFamily: body,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: color,
      );
}
