import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/typography.dart';
import 'ui_kit.dart';

/// One thing to point at and one thing to say about it.
class CoachStep {
  const CoachStep({
    required this.anchor,
    required this.title,
    required this.body,
    this.icon,
    this.inflate = 7,
  });

  /// Key on the widget being explained. A step whose anchor is missing — a panel
  /// the current screen size chose not to draw, say — is still shown, just
  /// centred and without a spotlight.
  final GlobalKey anchor;

  final String title;
  final String body;
  final IconData? icon;

  /// How far the spotlight is opened beyond the widget's own bounds.
  final double inflate;
}

/// Walks the player through a screen by dimming it and cutting a hole around one
/// widget at a time.
///
/// Wrap the whole screen so that anything on it, including the header, can be
/// spotlit:
///
/// ```dart
/// CoachOverlay(
///   active: game.needsLesson(Lesson.stable),
///   onDone: () => game.completeLesson(Lesson.stable),
///   steps: [...],
///   child: GameScreen(...),
/// )
/// ```
class CoachOverlay extends StatefulWidget {
  const CoachOverlay({
    super.key,
    required this.child,
    required this.steps,
    required this.active,
    required this.onDone,
  });

  final Widget child;
  final List<CoachStep> steps;

  /// Whether the walkthrough is owed. Read once, when the overlay is created, so
  /// that marking the lesson finished cannot restart it.
  final bool active;

  /// Called when the player reaches the end or skips.
  final VoidCallback onDone;

  @override
  State<CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<CoachOverlay> {
  final GlobalKey _rootKey = GlobalKey();

  int _index = -1;
  Rect? _hole;

  @override
  void initState() {
    super.initState();
    if (!widget.active || widget.steps.isEmpty) return;
    // The anchors have no geometry until the screen underneath has been laid
    // out, so the first step waits for that frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _show(0));
  }

  void _show(int index) {
    if (!mounted) return;
    if (index >= widget.steps.length) {
      _finish();
      return;
    }
    setState(() {
      _index = index;
      _hole = _rectOf(widget.steps[index]);
    });
  }

  void _finish() {
    if (_index < 0) return;
    setState(() {
      _index = -1;
      _hole = null;
    });
    widget.onDone();
  }

  /// The anchor's bounds in the overlay's own coordinates.
  Rect? _rectOf(CoachStep step) {
    final target = step.anchor.currentContext?.findRenderObject();
    final root = _rootKey.currentContext?.findRenderObject();
    if (target is! RenderBox || root is! RenderBox) return null;
    if (!target.hasSize || !target.attached) return null;

    final origin = target.localToGlobal(Offset.zero, ancestor: root);
    final rect = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      target.size.width,
      target.size.height,
    ).inflate(step.inflate);

    // An anchor scrolled out of view would put the spotlight off screen, which
    // reads as a bug; better to fall back to a plain centred card.
    final bounds = Offset.zero & root.size;
    return bounds.overlaps(rect) ? rect : null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _rootKey,
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_index >= 0)
          _CoachLayer(
            step: widget.steps[_index],
            hole: _hole,
            index: _index,
            total: widget.steps.length,
            onNext: () => _show(_index + 1),
            onSkip: _finish,
          ),
      ],
    );
  }
}

class _CoachLayer extends StatefulWidget {
  const _CoachLayer({
    required this.step,
    required this.hole,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final CoachStep step;
  final Rect? hole;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<_CoachLayer> createState() => _CoachLayerState();
}

class _CoachLayerState extends State<_CoachLayer>
    with SingleTickerProviderStateMixin {
  static const double _cardWidth = 306;
  static const double _gap = 14;
  static const double _margin = 14;

  /// Room the card is assumed to need. The copy is written to fit it, and the
  /// screen-layout tests keep it honest.
  static const double _cardHeight = 152;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Rect?>(
      tween: RectTween(end: widget.hole),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, hole, _) => LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, box.maxHeight);
          return Material(
            // The overlay sits above the screen's own Scaffold rather than
            // inside it, and text with no Material ancestor is painted in the
            // framework's yellow underlined warning style.
            type: MaterialType.transparency,
            child: GestureDetector(
              // Swallows taps meant for the screen underneath, and lets the
              // player advance by tapping anywhere rather than hunting for the
              // button.
              behavior: HitTestBehavior.opaque,
              onTap: widget.onNext,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) => CustomPaint(
                        painter: _SpotlightPainter(
                          hole: hole,
                          glow: _pulse.value,
                        ),
                      ),
                    ),
                  ),
                  _positionCard(size, hole),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Puts the card in the largest gap the spotlight leaves: under it, over it,
  /// or off to one side.
  ///
  /// A full-height panel leaves nothing above or below it, and a card shoved off
  /// the top of the screen teaches nobody anything, so every side is considered
  /// before falling back to the middle.
  Widget _positionCard(Size size, Rect? hole) {
    final width = _cardWidth > size.width - _margin * 2
        ? size.width - _margin * 2
        : _cardWidth;
    final card = _CoachCard(
      step: widget.step,
      index: widget.index,
      total: widget.total,
      width: width,
      onNext: widget.onNext,
      onSkip: widget.onSkip,
    );

    if (hole == null) return Center(child: card);

    /// Keeps an edge of the card inside the screen along one axis.
    double fit(double value, double extent, double room) =>
        room - extent < _margin * 2
        ? _margin
        : value.clamp(_margin, room - extent - _margin);

    if (size.height - hole.bottom >= _cardHeight + _gap) {
      return Positioned(
        left: fit(hole.center.dx - width / 2, width, size.width),
        top: hole.bottom + _gap,
        width: width,
        child: card,
      );
    }
    if (hole.top >= _cardHeight + _gap) {
      return Positioned(
        left: fit(hole.center.dx - width / 2, width, size.width),
        bottom: size.height - hole.top + _gap,
        width: width,
        child: card,
      );
    }
    if (size.width - hole.right >= width + _gap) {
      return Positioned(
        left: hole.right + _gap,
        top: fit(hole.center.dy - _cardHeight / 2, _cardHeight, size.height),
        width: width,
        child: card,
      );
    }
    if (hole.left >= width + _gap) {
      return Positioned(
        left: fit(hole.left - width - _gap, width, size.width),
        top: fit(hole.center.dy - _cardHeight / 2, _cardHeight, size.height),
        width: width,
        child: card,
      );
    }

    // The spotlight covers the whole screen. Its ring still shows around the
    // edges, so the card simply sits in the middle of it.
    return Center(
      child: SizedBox(width: width, child: card),
    );
  }
}

/// Dims everything except a rounded window onto the widget being explained.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.glow});

  final Rect? hole;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Palette.pitch.withValues(alpha: 0.84);
    final screen = Path()..addRect(Offset.zero & size);

    if (hole == null) {
      canvas.drawPath(screen, scrim);
      return;
    }

    final window = RRect.fromRectAndRadius(
      hole!,
      const Radius.circular(Shape.rSm),
    );
    canvas.drawPath(
      Path.combine(PathOperation.difference, screen, Path()..addRRect(window)),
      scrim,
    );

    // A ring that breathes, so the eye lands on the cut-out rather than the card.
    canvas.drawRRect(
      window,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Palette.amber.withValues(alpha: 0.55 + glow * 0.45),
    );
    canvas.drawRRect(
      window.inflate(4 + glow * 4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Palette.amber.withValues(alpha: 0.26 * (1 - glow)),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.glow != glow;
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.step,
    required this.index,
    required this.total,
    required this.width,
    required this.onNext,
    required this.onSkip,
  });

  final CoachStep step;
  final int index;
  final int total;
  final double width;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final last = index == total - 1;

    return TweenAnimationBuilder<double>(
      // Keyed on the step so each one fades and lifts in on its own.
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: child,
        ),
      ),
      child: Panel(
        accent: Palette.amber,
        selected: true,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (step.icon != null) ...[
                  Icon(step.icon, size: 17, color: Palette.amber),
                  const SizedBox(width: 7),
                ],
                Expanded(
                  child: Text(
                    step.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Type.title(15, color: Palette.amber),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${index + 1}/$total', style: Type.number(11)),
              ],
            ),
            const SizedBox(height: 6),
            Text(step.body, style: Type.text(11.5, height: 1.4)),
            const SizedBox(height: 11),
            Row(
              children: [
                if (!last)
                  GhostButton(label: 'Skip', compact: true, onTap: onSkip),
                const Spacer(),
                PrimaryButton(
                  label: last ? 'Got it' : 'Next',
                  icon: last
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  compact: true,
                  onTap: onNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
