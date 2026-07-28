import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../core/typography.dart';
import '../../genetics/racer.dart';
import 'ui_kit.dart';

/// A bird sprite with her silks feather behind her. Used for portraits, the
/// roster, the Hatchery and the race lanes.
class BirdView extends StatelessWidget {
  const BirdView({
    super.key,
    required this.pose,
    required this.plume,
    this.size = 90,
    this.flip = false,
    this.showPlume = true,
    this.dim = false,
  });

  final int pose;
  final int plume;
  final double size;
  final bool flip;
  final bool showPlume;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final bird = Image.asset(
      Sprites.bird(pose),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      color: dim ? Palette.pitch.withValues(alpha: 0.55) : null,
      colorBlendMode: dim ? BlendMode.srcATop : null,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showPlume)
            Positioned(
              right: size * 0.02,
              top: size * 0.04,
              child: Transform.rotate(
                angle: 0.5,
                child: Opacity(
                  opacity: 0.9,
                  child: Image.asset(
                    Sprites.plume(plume),
                    width: size * 0.42,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scaleByDouble(flip ? -1.0 : 1.0, 1.0, 1.0, 1.0),
            child: bird,
          ),
        ],
      ),
    );
  }
}

/// Breathing idle animation, so a bird on a static screen still feels alive.
class BreathingBird extends StatefulWidget {
  const BreathingBird({
    super.key,
    required this.pose,
    required this.plume,
    this.size = 110,
    this.flip = false,
  });

  final int pose;
  final int plume;
  final double size;
  final bool flip;

  @override
  State<BreathingBird> createState() => _BreathingBirdState();
}

class _BreathingBirdState extends State<BreathingBird>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -2 + t * 4),
          child: Transform.scale(scale: 0.99 + t * 0.02, child: child),
        );
      },
      child: BirdView(
        pose: widget.pose,
        plume: widget.plume,
        size: widget.size,
        flip: widget.flip,
      ),
    );
  }
}

/// Roster card: portrait, condition and career record.
class RacerCard extends StatelessWidget {
  const RacerCard({
    super.key,
    required this.racer,
    this.selected = false,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  final Racer racer;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  /// The badges under the name, most important first.
  List<(String, Color)> get _tags {
    final pheno = racer.basePhenotype;
    return [
      if (racer.races > 0) ('${racer.wins}W / ${racer.races}', Palette.amber),
      if (pheno.pureTraits.isNotEmpty)
        ('${pheno.pureTraits.length} pure', Palette.amber),
      if (pheno.synergies.isNotEmpty)
        ('${pheno.synergies.length} synergy', Palette.schoolRainbow),
      if (racer.injuries.isNotEmpty)
        ('${racer.injuries.length} injury', Palette.bad),
      if (racer.fatigue > 40) ('${racer.fatigue} fatigue', Palette.warn),
      if (racer.inbreedingPenalty.label.isNotEmpty)
        (racer.inbreedingPenalty.label, Palette.bad),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pheno = racer.basePhenotype;
    final tags = _tags;

    return Panel(
      onTap: onTap,
      selected: selected,
      accent: racer.careerOver ? Palette.bad : Palette.amber,
      padding: EdgeInsets.all(compact ? 9 : 12),
      child: Row(
        children: [
          BirdView(
            pose: racer.portraitPose,
            plume: racer.plume,
            size: compact ? 46 : 62,
            dim: racer.careerOver,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                // The card is used in grids and side panels of very different
                // heights, so it sheds detail from the bottom up rather than
                // spilling out of whatever cell it was given. Badges need two
                // rows' worth of room in a narrow card; below that they collapse
                // into one line of text, and below that they go entirely.
                final room = box.maxHeight;
                final badges = tags.isNotEmpty && room >= 94;
                final summary = tags.isNotEmpty && !badges && room >= 74;
                final showStats = room >= 42;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            racer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Type.title(compact ? 14 : 16),
                          ),
                        ),
                        if (racer.rank > 0) ...[
                          const SizedBox(width: 6),
                          _RankPips(rank: racer.rank),
                        ],
                      ],
                    ),
                    if (showStats) ...[
                      const SizedBox(height: 3),
                      Text(
                        racer.careerOver
                            ? 'Retired'
                            : '${pheno.stride} stride · ${pheno.staminaMax} wind'
                                  ' · ${pheno.effort} effort',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Type.text(compact ? 10.5 : 11.5),
                      ),
                    ],
                    if (badges) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          for (final (label, tint) in tags)
                            _MiniTag(label, tint),
                        ],
                      ),
                    ] else if (summary) ...[
                      const SizedBox(height: 4),
                      Text(
                        tags.map((t) => t.$1).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Type.text(9.5, color: Palette.inkMute),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _RankPips extends StatelessWidget {
  const _RankPips({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        rank,
        (_) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Palette.amber,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.text, this.tint);
  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: Type.text(9.5, color: tint)),
    );
  }
}

/// Stamina / fatigue style bar.
class MeterBar extends StatelessWidget {
  const MeterBar({
    super.key,
    required this.value,
    required this.max,
    required this.tint,
    this.label,
    this.height = 10,
    this.showNumbers = true,
  });

  final num value;
  final num max;
  final Color tint;
  final String? label;
  final double height;
  final bool showNumbers;

  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showNumbers)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                if (label != null)
                  Flexible(
                    child: Text(
                      label!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: Type.label(9),
                    ),
                  ),
                const Spacer(),
                if (showNumbers)
                  Text(
                    '${value.round()} / ${max.round()}',
                    style: Type.number(11, color: tint),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Container(
            height: height,
            color: Palette.pitch,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                widthFactor: fraction,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tint.withValues(alpha: 0.75), tint],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Row of pips for a small integer resource such as Effort.
class PipRow extends StatelessWidget {
  const PipRow({
    super.key,
    required this.filled,
    required this.total,
    required this.tint,
    this.size = 12,
  });

  final int filled;
  final int total;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    final count = math.max(total, filled);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final on = i < filled;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: on ? tint : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: on ? tint : Palette.slateHi,
                width: on ? 0 : 1.5,
              ),
              boxShadow: on ? Shape.glow(tint, 0.35) : null,
            ),
          ),
        );
      }),
    );
  }
}
