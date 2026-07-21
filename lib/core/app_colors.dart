import 'package:flutter/material.dart';

/// Central colour palette for Nestline Speedway. Warm, cozy farm tones with
/// bright candy accents so the whole UI feels friendly and playful.
class AppColors {
  AppColors._();

  // Brand / primary
  static const Color gold = Color(0xFFFFC02E);
  static const Color goldDeep = Color(0xFFF5A215);
  static const Color amber = Color(0xFFFF9E3D);
  static const Color orange = Color(0xFFFF7A45);

  // Surfaces
  static const Color cream = Color(0xFFFFF6E4);
  static const Color creamCard = Color(0xFFFFFDF7);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color wood = Color(0xFF9A5B33);
  static const Color woodDark = Color(0xFF6E3F22);
  static const Color woodLight = Color(0xFFC98A54);

  // Sky / nature
  static const Color sky = Color(0xFF7FC7FF);
  static const Color skyDeep = Color(0xFF3E9BE6);
  static const Color leaf = Color(0xFF6FBF54);
  static const Color leafDeep = Color(0xFF3E8E3F);

  // Text
  static const Color ink = Color(0xFF4A2E1C);
  static const Color inkSoft = Color(0xFF7A5A44);
  static const Color inkMute = Color(0xFFB59A82);

  // Stats
  static const Color hunger = Color(0xFFFF8A3D);
  static const Color mood = Color(0xFFFFC02E);
  static const Color health = Color(0xFFFF5C7A);
  static const Color energy = Color(0xFF57C7E3);
  static const Color trust = Color(0xFFB07BE8);

  // Feedback
  static const Color success = Color(0xFF4CC66A);
  static const Color danger = Color(0xFFEF5350);
  static const Color coin = Color(0xFFFFC93C);

  // Rarity ladder (egg / item rarities)
  static const List<Color> rarity = [
    Color(0xFFB8C4CE), // common
    Color(0xFF7FC97F), // uncommon
    Color(0xFF57A9F0), // rare
    Color(0xFFFFB13C), // epic
    Color(0xFFE267D6), // legendary
    Color(0xFF7A6BF0), // mythic
    Color(0xFFFF5C7A), // divine
  ];

  static const List<Color> homeSky = [Color(0xFFFFE6A8), Color(0xFFFFC97A)];
}

/// Reusable gradients.
class AppGradients {
  AppGradients._();

  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFD65C), Color(0xFFF5A215)],
  );

  static const LinearGradient orange = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFA94D), Color(0xFFFF7A45)],
  );

  static const LinearGradient sky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF8FD0FF), Color(0xFF4FA3E8)],
  );

  static const LinearGradient leaf = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF86D46B), Color(0xFF4C9E43)],
  );

  static const LinearGradient cream = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF9EC), Color(0xFFFFE9C4)],
  );

  static const LinearGradient screen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF1D2), Color(0xFFFFE0B0), Color(0xFFFFCE93)],
  );
}
