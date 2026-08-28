import 'package:flutter/material.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/look.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/heat/contender.dart';
import 'package:nestline_circuit/heat/engine.dart';
import 'package:nestline_circuit/heat/status.dart';
import 'package:nestline_circuit/heat/track.dart';
import 'package:nestline_circuit/view/widgets/bird_view.dart';

/// The terrain preview. Reading this two segments ahead is the whole skill of
/// the game, so it gets permanent screen space rather than a tooltip.
class TerrainStrip extends StatelessWidget {
  const TerrainStrip({
    super.key,
    required this.track,
    required this.distance,
    this.count = 6,
  });

  final Track track;
  final double distance;
  final int count;

  @override
  Widget build(BuildContext context) {
    final index = track.segmentIndexAt(distance);
    final progress = track.segmentProgress(distance);
    final segments = <int>[];
    for (
      var i = index;
      i < track.segments.length && segments.length < count;
      i++
    ) {
      segments.add(i);
    }

    return SizedBox(
      height: 46,
      child: Row(
        children: [
          for (final i in segments)
            Expanded(
              child: _TerrainCell(
                segment: track.segments[i],
                current: i == index,
                progress: i == index ? progress : 0,
                number: i + 1,
              ),
            ),
          if (segments.length < count)
            Expanded(
              flex: count - segments.length,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Pigment.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Corners.rSm),
                  border: Border.all(color: Pigment.amber),
                ),
                child: Center(
                  child: Text(
                    'FINISH',
                    style: Face.label(9, color: Pigment.amber),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TerrainCell extends StatelessWidget {
  const _TerrainCell({
    required this.segment,
    required this.current,
    required this.progress,
    required this.number,
  });

  final Segment segment;
  final bool current;
  final double progress;
  final int number;

  @override
  Widget build(BuildContext context) {
    final tint = segment.terrain.tint;
    return Tooltip(
      message: '${segment.terrain.label}\n${segment.terrain.effect}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: current ? 0.28 : 0.12),
          borderRadius: BorderRadius.circular(Corners.rSm),
          border: Border.all(
            color: current ? tint : tint.withValues(alpha: 0.3),
            width: current ? 1.8 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (current)
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.02, 1),
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(Corners.rSm),
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(segment.terrain.icon, size: 15, color: tint),
                const SizedBox(height: 1),
                Text(
                  segment.terrain.label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: Face.text(
                    8,
                    color: current ? Pigment.ink : Pigment.inkSoft,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The lane view: three bands, everyone's position within a moving window, and
/// the rivals' telegraphed intents.
class HeatField extends StatelessWidget {
  const HeatField({
    super.key,
    required this.engine,
    this.highlightLane,
    this.onLaneTap,
  });

  final HeatEngine engine;

  /// Lane being previewed while the player chooses a target lane.
  final int? highlightLane;
  final ValueChanged<int>? onLaneTap;

  /// Ground units visible across the width of the view.
  static const double window = 44;

  @override
  Widget build(BuildContext context) {
    final player = engine.player;
    final left = player.distance - window * 0.3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final laneHeight = constraints.maxHeight / engine.laneCount;
        final usable = constraints.maxWidth - 64;

        double xFor(double distance) =>
            (((distance - left) / window).clamp(-0.05, 1.05)) * usable + 8;

        return Stack(
          children: [
            for (var lane = 0; lane < engine.laneCount; lane++)
              Positioned(
                left: 0,
                right: 0,
                top: lane * laneHeight,
                height: laneHeight,
                child: _HeatBand(
                  lane: lane,
                  highlighted: highlightLane == lane,
                  isPlayerLane: player.lane == lane,
                  onTap: onLaneTap == null ? null : () => onLaneTap!(lane),
                ),
              ),
            // Finish marker, once it is inside the window.
            if (engine.track.totalLength - left < window)
              Positioned(
                left: xFor(engine.track.totalLength.toDouble()),
                top: 0,
                bottom: 0,
                child: const _TapePost(),
              ),
            for (final e in engine.entrants)
              Positioned(
                left: xFor(e.distance),
                top: e.lane * laneHeight + laneHeight * 0.06,
                height: laneHeight * 0.88,
                child: _ContenderMarker(
                  entrant: e,
                  height: laneHeight * 0.88,
                  position: engine.standings.indexOf(e) + 1,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeatBand extends StatelessWidget {
  const _HeatBand({
    required this.lane,
    required this.highlighted,
    required this.isPlayerLane,
    this.onTap,
  });

  final int lane;
  final bool highlighted;
  final bool isPlayerLane;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = Pigment.lanes[lane % Pigment.lanes.length];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: highlighted
              ? tint.withValues(alpha: 0.22)
              : Pigment.pitch.withValues(alpha: isPlayerLane ? 0.30 : 0.42),
          borderRadius: BorderRadius.circular(Corners.rSm),
          border: Border.all(
            color: highlighted
                ? tint
                : isPlayerLane
                ? tint.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              '${lane + 1}',
              style: Face.number(11, color: tint.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapePost extends StatelessWidget {
  const _TapePost();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 12; i++)
          Expanded(
            child: Container(
              width: 7,
              color: i.isEven ? Pigment.chalk : Pigment.pitch,
            ),
          ),
      ],
    );
  }
}

class _ContenderMarker extends StatelessWidget {
  const _ContenderMarker({
    required this.entrant,
    required this.height,
    required this.position,
  });

  final Contender entrant;

  /// Vertical room this marker has inside its lane band.
  final double height;

  final int position;

  static const double _labelHeight = 12;
  static const double _bubbleHeight = 16;
  static const double _minBird = 26;

  @override
  Widget build(BuildContext context) {
    // A lane band is only a third of the track view, which on a small phone in
    // landscape leaves barely more room than the bird itself. So the marker
    // drops its decorations in order of importance rather than overflowing:
    // the name goes first, then the telegraphed intent, and the bird stays.
    var showIntent =
        !entrant.isPlayer && entrant.intent != null && !entrant.finished;
    var showLabel = true;
    var bird = height - _labelHeight - (showIntent ? _bubbleHeight : 0);

    if (bird < _minBird && showLabel) {
      showLabel = false;
      bird += _labelHeight;
    }
    if (bird < _minBird && showIntent) {
      showIntent = false;
      bird += _bubbleHeight;
    }
    bird = bird.clamp(_minBird, 74.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showIntent)
          _TelegraphBubble(intent: entrant.intent!, height: _bubbleHeight - 2),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (entrant.isPlayer)
              Container(
                width: bird * 0.95,
                height: bird * 0.28,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Pigment.amber.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            HenView(
              pose: entrant.pose,
              plume: entrant.plume,
              size: bird,
              showPlume: false,
              dim: entrant.finished,
            ),
            if (entrant.blown)
              Positioned(
                top: -2,
                right: -2,
                child: Icon(Icons.sick, size: 13, color: Pigment.bad),
              ),
          ],
        ),
        if (showLabel)
          SizedBox(
            width: bird + 16,
            height: _labelHeight,
            child: Text(
              entrant.isPlayer ? entrant.name : '$position. ${entrant.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Face.text(
                8.5,
                color: entrant.isPlayer ? Pigment.amber : Pigment.inkSoft,
              ),
            ),
          ),
      ],
    );
  }
}

class _TelegraphBubble extends StatelessWidget {
  const _TelegraphBubble({required this.intent, required this.height});
  final Telegraph intent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tint = switch (intent.kind) {
      TelegraphKind.surge => Pigment.ember,
      TelegraphKind.clip => Pigment.bad,
      TelegraphKind.block => Pigment.momentum,
      TelegraphKind.steady => Pigment.stamina,
      _ => Pigment.inkSoft,
    };
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Pigment.pitch.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: tint.withValues(alpha: 0.7)),
      ),
      child: Text(
        intent.describe(),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: Face.text(8, color: tint),
      ),
    );
  }
}

/// Compact status readout for the player's bird.
class ConditionRow extends StatelessWidget {
  const ConditionRow({super.key, required this.entrant});
  final Contender entrant;

  @override
  Widget build(BuildContext context) {
    if (entrant.statuses.isEmpty) {
      return Text('No effects', style: Face.text(10, color: Pigment.inkMute));
    }
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        for (final entry in entrant.statuses.entries)
          Tooltip(
            message: '${entry.key.label}\n${entry.key.blurb}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: entry.key.tint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: entry.key.tint.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(entry.key.icon, size: 10, color: entry.key.tint),
                  const SizedBox(width: 3),
                  Text(
                    '${entry.value}',
                    style: Face.number(10, color: entry.key.tint),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Scrolling race commentary.
class HeatLog extends StatelessWidget {
  const HeatLog({super.key, required this.lines});
  final List<HeatLine> lines;

  @override
  Widget build(BuildContext context) {
    final recent = lines.reversed.take(7).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              line.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Face.text(
                9.5,
                color: switch (line.tone) {
                  HeatTone.good => Pigment.stamina,
                  HeatTone.bad => Pigment.bad,
                  HeatTone.rival => Pigment.momentum,
                  HeatTone.terrain => Pigment.amber,
                  HeatTone.neutral => Pigment.inkSoft,
                },
              ),
            ),
          ),
      ],
    );
  }
}
