import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/rng.dart';
import '../core/sprites.dart';

/// Terrain decides what a command is worth. Every venue is really just a
/// sequence of these, and reading two segments ahead is the core skill.
enum Terrain { straight, corner, mud, puddle, hay, gravel, downhill, crowd }

extension TerrainInfo on Terrain {
  String get label => switch (this) {
    Terrain.straight => 'Straight',
    Terrain.corner => 'Corner',
    Terrain.mud => 'Mud',
    Terrain.puddle => 'Puddle',
    Terrain.hay => 'Hay Bales',
    Terrain.gravel => 'Gravel',
    Terrain.downhill => 'Downhill',
    Terrain.crowd => 'Crowd Stretch',
  };

  String get effect => switch (this) {
    Terrain.straight => 'Drafting refunds an extra stamina.',
    Terrain.corner => 'Momentum above your control burns that much stamina.',
    Terrain.mud => 'Every Move costs 2 extra stamina, less 1 per grip.',
    Terrain.puddle => 'Momentum resets unless you have 2 grip.',
    Terrain.hay => 'Lose 2 ground unless you have grip or Flap.',
    Terrain.gravel => 'Stride drops by 1 unless you have 2 grip.',
    Terrain.downhill => 'Free ground and momentum for everyone.',
    Terrain.crowd => 'The leader gains 1 effort next turn.',
  };

  Color get tint => switch (this) {
    Terrain.straight => Palette.momentum,
    Terrain.corner => Palette.amber,
    Terrain.mud => const Color(0xFF8A6236),
    Terrain.puddle => const Color(0xFF4A9FD0),
    Terrain.hay => const Color(0xFFD8A63C),
    Terrain.gravel => const Color(0xFF9AA9C0),
    Terrain.downhill => Palette.stamina,
    Terrain.crowd => Palette.schoolRainbow,
  };

  IconData get icon => switch (this) {
    Terrain.straight => Icons.remove,
    Terrain.corner => Icons.turn_right,
    Terrain.mud => Icons.water_drop,
    Terrain.puddle => Icons.waves,
    Terrain.hay => Icons.grass,
    Terrain.gravel => Icons.grain,
    Terrain.downhill => Icons.trending_down,
    Terrain.crowd => Icons.campaign,
  };
}

/// One stretch of track.
@immutable
class Segment {
  const Segment(this.terrain, this.length);

  final Terrain terrain;

  /// Ground units needed to clear the segment.
  final int length;
}

/// A venue: the terrain profile, the backdrop and the shape of its field.
@immutable
class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.blurb,
    required this.plate,
    required this.scenePlate,
    required this.segments,
    required this.weights,
    required this.fieldSize,
    required this.lengthScale,
  });

  final String id;
  final String name;
  final String blurb;

  /// Landscape racing plate.
  final String plate;

  /// Portrait scene plate, used on schedule cards and briefings.
  final String scenePlate;

  /// Number of segments in one lap of this venue.
  final int segments;

  /// Terrain draw weights, in [Terrain.values] order.
  final List<double> weights;

  final int fieldSize;

  /// Multiplier on segment length; endurance venues run long.
  final double lengthScale;

  static const List<Venue> all = [
    Venue(
      id: 'meadowgate',
      name: 'Meadowgate Mile',
      blurb: 'Even, honest ground. Nowhere to hide and nothing to blame.',
      plate: Plates.trackDay,
      scenePlate: 'assets/art/bg4.webp',
      segments: 7,
      weights: [4, 3, 1, 1, 1, 1, 1, 1],
      fieldSize: 4,
      lengthScale: 1.0,
    ),
    Venue(
      id: 'sunhill',
      name: 'Sunhill Sprint',
      blurb: 'Straights all the way. Whoever drafts best gets the purse.',
      plate: Plates.trackDay,
      scenePlate: 'assets/art/bg3.webp',
      segments: 6,
      weights: [7, 1, 0, 0, 1, 1, 2, 2],
      fieldSize: 4,
      lengthScale: 0.85,
    ),
    Venue(
      id: 'barnyard',
      name: 'Barnyard Bowl',
      blurb: 'Tight and short. The whole race is one long lane fight.',
      plate: Plates.trackDay,
      scenePlate: 'assets/art/bg2.webp',
      segments: 8,
      weights: [2, 6, 1, 1, 2, 1, 0, 3],
      fieldSize: 5,
      lengthScale: 0.7,
    ),
    Venue(
      id: 'blossom',
      name: 'Blossom Vale Circuit',
      blurb: 'It always rains here. Bring grip or bring excuses.',
      plate: Plates.trackAutumn,
      scenePlate: 'assets/art/bg7.webp',
      segments: 8,
      weights: [2, 3, 5, 4, 1, 1, 1, 2],
      fieldSize: 4,
      lengthScale: 1.0,
    ),
    Venue(
      id: 'autumn_ridge',
      name: 'Autumn Ridge',
      blurb: 'Downhill into corners. Momentum will happily kill you.',
      plate: Plates.trackAutumn,
      scenePlate: 'assets/art/bg6.webp',
      segments: 8,
      weights: [2, 5, 2, 1, 2, 3, 5, 1],
      fieldSize: 5,
      lengthScale: 1.05,
    ),
    Venue(
      id: 'frostpine',
      name: 'Frostpine Loop',
      blurb: 'Long cold corners over loose gravel. Stamina goes fast.',
      plate: Plates.trackNight,
      scenePlate: 'assets/art/bg1.webp',
      segments: 9,
      weights: [2, 5, 1, 2, 1, 5, 1, 1],
      fieldSize: 5,
      lengthScale: 1.1,
    ),
    Venue(
      id: 'goldfield',
      name: 'Goldfield Straight',
      blurb: 'The longest run on the circuit. An endurance test, plainly.',
      plate: Plates.trackDay,
      scenePlate: 'assets/art/bg5.webp',
      segments: 10,
      weights: [6, 2, 1, 1, 1, 2, 1, 2],
      fieldSize: 5,
      lengthScale: 1.35,
    ),
    Venue(
      id: 'midnight',
      name: 'Midnight Oval',
      blurb: 'Every terrain, three times over, under the lamps.',
      plate: Plates.trackNight,
      scenePlate: 'assets/art/bg8.webp',
      segments: 9,
      weights: [3, 4, 2, 2, 2, 2, 2, 3],
      fieldSize: 6,
      lengthScale: 1.15,
    ),
  ];

  static Venue byId(String id) =>
      all.firstWhere((v) => v.id == id, orElse: () => all.first);
}

/// A generated track: the concrete segment list a race runs on.
class Track {
  Track({required this.venue, required this.segments, required this.laps});

  final Venue venue;
  final List<Segment> segments;
  final int laps;

  late final List<int> _cumulative = _buildCumulative();

  List<int> _buildCumulative() {
    final out = <int>[];
    var total = 0;
    for (final s in segments) {
      total += s.length;
      out.add(total);
    }
    return out;
  }

  int get totalLength => _cumulative.isEmpty ? 0 : _cumulative.last;

  /// Index of the segment containing [distance], clamped to the last segment.
  int segmentIndexAt(double distance) {
    for (var i = 0; i < _cumulative.length; i++) {
      if (distance < _cumulative[i]) return i;
    }
    return segments.length - 1;
  }

  Segment segmentAt(double distance) => segments[segmentIndexAt(distance)];

  Terrain terrainAt(double distance) => segmentAt(distance).terrain;

  /// Progress through the segment containing [distance], 0–1.
  double segmentProgress(double distance) {
    final i = segmentIndexAt(distance);
    final start = i == 0 ? 0 : _cumulative[i - 1];
    final len = segments[i].length;
    if (len <= 0) return 1;
    return ((distance - start) / len).clamp(0, 1);
  }

  /// The next [count] segments from [distance], for the track preview strip.
  List<Segment> upcoming(double distance, int count) {
    final i = segmentIndexAt(distance);
    return segments.skip(i).take(count).toList(growable: false);
  }

  /// Builds a track for [venue]. Every lap repeats the same profile so the
  /// player can learn a venue instead of re-reading a new random layout.
  static Track generate(Venue venue, Rng rng, {int laps = 1, int grade = 0}) {
    final lapSegments = <Segment>[];
    for (var i = 0; i < venue.segments; i++) {
      // Open every lap on a straight so the field can settle before the fight.
      final terrain = i == 0
          ? Terrain.straight
          : rng.weighted(Terrain.values, venue.weights);
      final base = rng.range(9, 14);
      final len = (base * venue.lengthScale).round().clamp(6, 26);
      lapSegments.add(Segment(terrain, len));
    }

    final segments = <Segment>[];
    for (var lap = 0; lap < laps; lap++) {
      segments.addAll(lapSegments);
    }

    // Higher grades stretch the track a little rather than inflating rivals.
    if (grade > 0) {
      final extra = (grade / 3).floor();
      for (var i = 0; i < extra; i++) {
        segments.add(lapSegments[i % lapSegments.length]);
      }
    }

    return Track(venue: venue, segments: segments, laps: laps);
  }
}
