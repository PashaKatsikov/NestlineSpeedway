import 'package:flutter/material.dart';

/// Nestline Speedway runs on a night-circuit palette: asphalt and deep racing
/// blue for surfaces, sodium-lamp amber for anything the player can act on, and
/// a saturated accent ramp for lanes, stamina and grades.
class Palette {
  Palette._();

  // Surfaces, dark to light.
  static const Color pitch = Color(0xFF0B1220);
  static const Color asphalt = Color(0xFF141D2E);
  static const Color asphaltHi = Color(0xFF1C2942);
  static const Color slate = Color(0xFF27374F);
  static const Color slateHi = Color(0xFF37496A);
  static const Color chalk = Color(0xFFF3F6FB);

  // Brand accents.
  static const Color amber = Color(0xFFFFB627);
  static const Color amberDeep = Color(0xFFE8890B);
  static const Color ember = Color(0xFFFF6B35);
  static const Color racingBlue = Color(0xFF2E6BE6);
  static const Color racingBlueDeep = Color(0xFF1B47A8);

  // Text.
  static const Color ink = Color(0xFFF3F6FB);
  static const Color inkSoft = Color(0xFFAEBCD4);
  static const Color inkMute = Color(0xFF6C7C99);
  static const Color inkOnLight = Color(0xFF16203A);

  // Race resources.
  static const Color stamina = Color(0xFF3ED0A0);
  static const Color staminaLow = Color(0xFFFFC93C);
  static const Color momentum = Color(0xFF56C6F5);
  static const Color effort = Color(0xFFFFB627);
  static const Color distance = Color(0xFFB98BF0);

  // Feedback.
  static const Color good = Color(0xFF3ED0A0);
  static const Color warn = Color(0xFFFFC93C);
  static const Color bad = Color(0xFFF4586B);

  // Command schools, indexed by [PlumageAllele].
  static const Color schoolSpeckled = Color(0xFFC98A54);
  static const Color schoolGold = Color(0xFFFFB627);
  static const Color schoolWhite = Color(0xFFDDE6F5);
  static const Color schoolRainbow = Color(0xFFE267D6);

  /// Lane tints, front to back of the track.
  static const List<Color> lanes = [
    Color(0xFF56C6F5),
    Color(0xFFFFB627),
    Color(0xFFF4586B),
  ];

  /// Seven-tier egg ladder, reused for every rarity display in the game.
  static const List<Color> tiers = [
    Color(0xFF9AA9C0), // plain
    Color(0xFF7FC97F), // speckled
    Color(0xFF57A9F0), // burnished
    Color(0xFFFFB13C), // gilded
    Color(0xFFE267D6), // prism
    Color(0xFF8C7BF5), // crystal
    Color(0xFFFF5C7A), // heirloom
  ];
}

class Grads {
  Grads._();

  static const LinearGradient amber = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFC93C), Color(0xFFE8890B)],
  );

  static const LinearGradient blue = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4A86F5), Color(0xFF1B47A8)],
  );

  static const LinearGradient ember = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF8A4C), Color(0xFFE03E1A)],
  );

  static const LinearGradient panel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F2C46), Color(0xFF141D2E)],
  );

  static const LinearGradient screen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF16203A), Color(0xFF0B1220)],
  );

  static const LinearGradient stamina = LinearGradient(
    colors: [Color(0xFF3ED0A0), Color(0xFF1FA37B)],
  );
}
