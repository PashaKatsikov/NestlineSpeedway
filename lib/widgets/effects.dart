import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A living, dreamy background: a soft animated gradient with slowly drifting
/// light orbs and a field of floating glow motes. This is the signature look
/// used behind every screen.
class EnchantedBackground extends StatefulWidget {
  final List<Color> colors;
  final List<Color> orbs;
  final Widget? child;
  final bool dense;
  const EnchantedBackground({
    super.key,
    required this.colors,
    required this.orbs,
    this.child,
    this.dense = false,
  });

  @override
  State<EnchantedBackground> createState() => _EnchantedBackgroundState();
}

class _EnchantedBackgroundState extends State<EnchantedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  late final List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    final rng = Random(7);
    final count = widget.dense ? 42 : 28;
    _motes = List.generate(count, (i) {
      return _Mote(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        r: 1.5 + rng.nextDouble() * (widget.dense ? 5 : 4),
        speed: 0.04 + rng.nextDouble() * 0.13,
        phase: rng.nextDouble() * pi * 2,
        drift: 0.01 + rng.nextDouble() * 0.05,
        twinkle: rng.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return CustomPaint(
            painter: _EnchantedPainter(
              t: _c.value,
              colors: widget.colors,
              orbs: widget.orbs,
              motes: _motes,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _Mote {
  final double x, y, r, speed, phase, drift, twinkle;
  _Mote({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
    required this.drift,
    required this.twinkle,
  });
}

class _EnchantedPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  final List<Color> orbs;
  final List<_Mote> motes;
  _EnchantedPainter({
    required this.t,
    required this.colors,
    required this.orbs,
    required this.motes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base diagonal gradient. ui.Gradient.linear requires explicit colour
    // stops whenever the colour list isn't exactly length 2, so we always
    // provide evenly spaced stops to support any palette size safely.
    final base = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        colors,
        _evenStops(colors.length),
      );
    canvas.drawRect(rect, base);

    // Slowly drifting soft light orbs (bokeh) for depth.
    for (int i = 0; i < orbs.length; i++) {
      final a = t * 2 * pi + i * 1.7;
      final cx = size.width * (0.25 + 0.55 * (0.5 + 0.5 * sin(a * 0.6 + i)));
      final cy = size.height * (0.3 + 0.5 * (0.5 + 0.5 * cos(a * 0.5 + i * 1.3)));
      final radius = size.shortestSide * (0.35 + 0.12 * sin(a + i));
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [orbs[i].withValues(alpha: 0.55), orbs[i].withValues(alpha: 0.0)],
        )
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    // Floating glow motes.
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (final m in motes) {
      final progress = (m.y - t * m.speed) % 1.0;
      final py = progress * size.height;
      final px = (m.x + sin(t * 2 * pi + m.phase) * m.drift) * size.width;
      final tw = 0.5 + 0.5 * sin(t * 2 * pi * 2 + m.twinkle * 6.28);
      final alpha = (0.25 + 0.55 * tw).clamp(0.0, 1.0);
      glow.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), m.r, glow);
    }

    // Gentle top sheen + bottom vignette for richness.
    final sheen = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.06),
          Colors.black.withValues(alpha: 0.14),
        ],
        [0.0, 0.32, 0.7, 1.0],
      );
    canvas.drawRect(rect, sheen);
  }

  @override
  bool shouldRepaint(covariant _EnchantedPainter old) => old.t != t;
}

/// Evenly spaced gradient stops for [n] colours (e.g. n=3 -> [0, 0.5, 1]).
List<double> _evenStops(int n) {
  if (n <= 1) return const [0.0];
  return [for (int i = 0; i < n; i++) i / (n - 1)];
}

/// A transparent overlay of drifting glow motes + a couple of soft light orbs,
/// layered on top of the coop scene on the home screen for atmosphere.
class MotesOverlay extends StatefulWidget {
  final int count;
  const MotesOverlay({super.key, this.count = 26});

  @override
  State<MotesOverlay> createState() => _MotesOverlayState();
}

class _MotesOverlayState extends State<MotesOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();
  late final List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    final rng = Random(21);
    _motes = List.generate(widget.count, (i) {
      return _Mote(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        r: 1.5 + rng.nextDouble() * 4.5,
        speed: 0.03 + rng.nextDouble() * 0.1,
        phase: rng.nextDouble() * pi * 2,
        drift: 0.01 + rng.nextDouble() * 0.05,
        twinkle: rng.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return CustomPaint(
              painter: _MotesPainter(t: _c.value, motes: _motes),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _MotesPainter extends CustomPainter {
  final double t;
  final List<_Mote> motes;
  _MotesPainter({required this.t, required this.motes});

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (final m in motes) {
      final progress = (m.y - t * m.speed) % 1.0;
      final py = progress * size.height;
      final px = (m.x + sin(t * 2 * pi + m.phase) * m.drift) * size.width;
      final tw = 0.5 + 0.5 * sin(t * 2 * pi * 2 + m.twinkle * 6.28);
      glow.color = Colors.white.withValues(alpha: (0.2 + 0.5 * tw).clamp(0, 1));
      canvas.drawCircle(Offset(px, py), m.r, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _MotesPainter old) => old.t != t;
}

/// Text painted with a gradient fill and a soft glow — used for big headings.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  final List<Shadow>? glow;
  final TextAlign? align;
  final int? maxLines;
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    required this.gradient,
    this.glow,
    this.align,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        style: style.copyWith(color: Colors.white, shadows: glow),
      ),
    );
  }
}

/// A slow shimmering highlight that sweeps across its child (for premium chips).
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color color;
  const Shimmer({super.key, required this.child, this.color = Colors.white});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_c.value * 2 - 0.5);
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                widget.color.withValues(alpha: 0.55),
                Colors.transparent,
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx / bounds.width),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * dx, 0, 0);
  }
}

/// Palettes used to theme the enchanted background per screen family.
class ScenePalettes {
  ScenePalettes._();

  static const List<Color> honey = [
    Color(0xFFFFF3D6),
    Color(0xFFFFE0A8),
    Color(0xFFFFC876),
  ];
  static const List<Color> honeyOrbs = [
    Color(0xFFFFD873),
    Color(0xFFFFB25A),
    Color(0xFFFFF0C2),
  ];

  static const List<Color> berry = [
    Color(0xFFFFE3F1),
    Color(0xFFF6C6E8),
    Color(0xFFD9A8F0),
  ];
  static const List<Color> berryOrbs = [
    Color(0xFFFF9ED6),
    Color(0xFFC58CF0),
    Color(0xFFFFD1EC),
  ];

  static const List<Color> meadow = [
    Color(0xFFE6FBD6),
    Color(0xFFBFECB0),
    Color(0xFF8FD98C),
  ];
  static const List<Color> meadowOrbs = [
    Color(0xFFB6F08A),
    Color(0xFF7FD0A0),
    Color(0xFFE7FFC9),
  ];

  static const List<Color> lagoon = [
    Color(0xFFDDF4FF),
    Color(0xFFB4E0FB),
    Color(0xFF8CC6F5),
  ];
  static const List<Color> lagoonOrbs = [
    Color(0xFF8FD3FF),
    Color(0xFF7FB0F0),
    Color(0xFFD6F1FF),
  ];

  static const List<Color> dusk = [
    Color(0xFFEFE0FF),
    Color(0xFFCDB8FF),
    Color(0xFF9E86F0),
  ];
  static const List<Color> duskOrbs = [
    Color(0xFFC7A8FF),
    Color(0xFF8A79F0),
    Color(0xFFEAD9FF),
  ];
}
