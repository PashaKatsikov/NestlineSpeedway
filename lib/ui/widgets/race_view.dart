import 'package:flutter/material.dart' hide Intent;

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/typography.dart';
import '../../race/entrant.dart';
import '../../race/race_engine.dart';
import '../../race/status.dart';
import '../../race/track.dart';
import 'bird_view.dart';

/// The terrain preview. Reading this two segments ahead is the whole skill of
/// the game, so it gets permanent screen space rather than a tooltip.
class TrackStrip extends StatelessWidget {
  const TrackStrip({
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
              child: _SegmentTile(
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
                  color: Palette.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Shape.rSm),
                  border: Border.all(color: Palette.amber),
                ),
                child: Center(
                  child: Text(
                    'FINISH',
                    style: Type.label(9, color: Palette.amber),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
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
          borderRadius: BorderRadius.circular(Shape.rSm),
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
                      borderRadius: BorderRadius.circular(Shape.rSm),
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
                  style: Type.text(
                    8,
                    color: current ? Palette.ink : Palette.inkSoft,
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
class LaneField extends StatelessWidget {
  const LaneField({
    super.key,
    required this.engine,
    this.highlightLane,
    this.onLaneTap,
  });

  final RaceEngine engine;

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
                child: _LaneBand(
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
                child: const _FinishPost(),
              ),
            for (final e in engine.entrants)
              Positioned(
                left: xFor(e.distance),
                top: e.lane * laneHeight + laneHeight * 0.06,
                height: laneHeight * 0.88,
                child: _EntrantMarker(
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

class _LaneBand extends StatelessWidget {
  const _LaneBand({
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
    final tint = Palette.lanes[lane % Palette.lanes.length];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: highlighted
              ? tint.withValues(alpha: 0.22)
              : Palette.pitch.withValues(alpha: isPlayerLane ? 0.30 : 0.42),
          borderRadius: BorderRadius.circular(Shape.rSm),
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
              style: Type.number(11, color: tint.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishPost extends StatelessWidget {
  const _FinishPost();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 12; i++)
          Expanded(
            child: Container(
              width: 7,
              color: i.isEven ? Palette.chalk : Palette.pitch,
            ),
          ),
      ],
    );
  }
}

class _EntrantMarker extends StatelessWidget {
  const _EntrantMarker({
    required this.entrant,
    required this.height,
    required this.position,
  });

  final Entrant entrant;

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
          _IntentBubble(intent: entrant.intent!, height: _bubbleHeight - 2),
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
                      Palette.amber.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            BirdView(
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
                child: Icon(Icons.sick, size: 13, color: Palette.bad),
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
              style: Type.text(
                8.5,
                color: entrant.isPlayer ? Palette.amber : Palette.inkSoft,
              ),
            ),
          ),
      ],
    );
  }
}

class _IntentBubble extends StatelessWidget {
  const _IntentBubble({required this.intent, required this.height});
  final Intent intent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tint = switch (intent.kind) {
      IntentKind.surge => Palette.ember,
      IntentKind.clip => Palette.bad,
      IntentKind.block => Palette.momentum,
      IntentKind.steady => Palette.stamina,
      _ => Palette.inkSoft,
    };
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.pitch.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: tint.withValues(alpha: 0.7)),
      ),
      child: Text(
        intent.describe(),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: Type.text(8, color: tint),
      ),
    );
  }
}

/// Compact status readout for the player's bird.
class StatusRow extends StatelessWidget {
  const StatusRow({super.key, required this.entrant});
  final Entrant entrant;

  @override
  Widget build(BuildContext context) {
    if (entrant.statuses.isEmpty) {
      return Text('No effects', style: Type.text(10, color: Palette.inkMute));
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
                    style: Type.number(10, color: entry.key.tint),
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
class RaceLog extends StatelessWidget {
  const RaceLog({super.key, required this.lines});
  final List<LogLine> lines;

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
              style: Type.text(
                9.5,
                color: switch (line.tone) {
                  LogTone.good => Palette.stamina,
                  LogTone.bad => Palette.bad,
                  LogTone.rival => Palette.momentum,
                  LogTone.terrain => Palette.amber,
                  LogTone.neutral => Palette.inkSoft,
                },
              ),
            ),
          ),
      ],
    );
  }
}
