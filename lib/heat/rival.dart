import 'package:nestline_circuit/app/dice.dart';
import 'package:nestline_circuit/blood/heredity.dart';
import 'package:nestline_circuit/heat/contender.dart';
import 'package:nestline_circuit/heat/track.dart';

/// Read-only view of the race handed to a rival's planner.
class RivalSight {
  RivalSight({
    required this.self,
    required this.field,
    required this.track,
    required this.turn,
    required this.rng,
  });

  final Contender self;
  final List<Contender> field;
  final Track track;
  final int turn;
  final Dice rng;

  double get raceProgress =>
      (self.distance / track.totalLength).clamp(0.0, 1.0);

  double get staminaFraction =>
      self.staminaMax == 0 ? 0 : self.stamina / self.staminaMax;

  Contender get leader =>
      field.reduce((a, b) => a.distance >= b.distance ? a : b);

  bool get isLeading => leader.id == self.id;

  int get positionIndex {
    final sorted = List<Contender>.of(field)
      ..sort((a, b) => b.distance.compareTo(a.distance));
    return sorted.indexWhere((e) => e.id == self.id);
  }

  Contender? get player {
    for (final e in field) {
      if (e.isPlayer) return e;
    }
    return null;
  }

  /// The nearest entrant ahead in the same lane, if close enough to draft.
  Contender? get aheadSameLane {
    Contender? best;
    for (final e in field) {
      if (e.id == self.id || e.lane != self.lane) continue;
      if (e.distance <= self.distance) continue;
      if (best == null || e.distance < best.distance) best = e;
    }
    if (best == null) return null;
    return (best.distance - self.distance) <= 6 ? best : null;
  }

  Terrain get terrainHere => track.terrainAt(self.distance);

  Terrain get terrainNext {
    final upcoming = track.upcoming(self.distance, 2);
    return upcoming.length > 1 ? upcoming[1].terrain : terrainHere;
  }
}

/// A rival's behaviour. Archetypes are deliberately legible: the player should
/// be able to name what a rival is doing after watching it for two turns.
class Archetype {
  const Archetype({
    required this.id,
    required this.name,
    required this.blurb,
    required this.plan,
    this.staminaScale = 1.0,
    this.strideBonus = 0,
  });

  final String id;
  final String name;
  final String blurb;
  final Telegraph Function(RivalSight view) plan;
  final double staminaScale;
  final int strideBonus;

  static const List<String> ids = [
    'frontrunner',
    'closer',
    'pacer',
    'bruiser',
    'technician',
  ];

  static Archetype byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);

  static final List<Archetype> all = [
    Archetype(
      id: 'frontrunner',
      name: 'Frontrunner',
      blurb: 'Goes to the front immediately and dares you to come get her.',
      staminaScale: 0.95,
      strideBonus: 1,
      plan: (v) {
        if (v.staminaFraction < 0.18) return const Telegraph(TelegraphKind.steady);
        if (v.raceProgress < 0.62) {
          return Telegraph(TelegraphKind.surge, magnitude: v.isLeading ? 2 : 4);
        }
        if (v.staminaFraction > 0.45) {
          return const Telegraph(TelegraphKind.surge, magnitude: 3);
        }
        return const Telegraph(TelegraphKind.cruise, magnitude: 1);
      },
    ),
    Archetype(
      id: 'closer',
      name: 'Closer',
      blurb: 'Sits in your slipstream all race, then kicks when it counts.',
      staminaScale: 1.1,
      plan: (v) {
        if (v.raceProgress > 0.72) {
          if (v.staminaFraction < 0.15) {
            return const Telegraph(TelegraphKind.cruise, magnitude: 1);
          }
          return const Telegraph(TelegraphKind.surge, magnitude: 5);
        }
        if (v.aheadSameLane != null) return const Telegraph(TelegraphKind.draft);
        final target = v.player?.lane ?? v.self.lane;
        if (target != v.self.lane) {
          return Telegraph(TelegraphKind.cut, targetLane: target);
        }
        return const Telegraph(TelegraphKind.cruise, magnitude: 1);
      },
    ),
    Archetype(
      id: 'pacer',
      name: 'Pacer',
      blurb: 'Never blows up. Never spectacular. Always there at the line.',
      staminaScale: 1.2,
      plan: (v) {
        if (v.staminaFraction < 0.35) return const Telegraph(TelegraphKind.steady);
        if (v.terrainNext == Terrain.corner && v.self.momentum > 2) {
          return const Telegraph(TelegraphKind.steady);
        }
        return const Telegraph(TelegraphKind.cruise, magnitude: 2);
      },
    ),
    Archetype(
      id: 'bruiser',
      name: 'Bruiser',
      blurb: 'Would rather ruin your race than win her own.',
      staminaScale: 1.05,
      plan: (v) {
        final player = v.player;
        if (player != null &&
            !player.finished &&
            player.lane == v.self.lane &&
            (player.distance - v.self.distance).abs() <= 7) {
          return const Telegraph(TelegraphKind.clip);
        }
        if (v.isLeading) return const Telegraph(TelegraphKind.block);
        if (player != null && player.lane != v.self.lane && v.rng.chance(0.5)) {
          return Telegraph(TelegraphKind.cut, targetLane: player.lane);
        }
        return const Telegraph(TelegraphKind.cruise, magnitude: 2);
      },
    ),
    Archetype(
      id: 'technician',
      name: 'Technician',
      blurb: 'Reads every corner correctly. Punishes anyone who does not.',
      staminaScale: 1.0,
      strideBonus: 1,
      plan: (v) {
        final here = v.terrainHere;
        final next = v.terrainNext;
        if (next == Terrain.corner && v.self.momentum > v.self.control) {
          return const Telegraph(TelegraphKind.steady);
        }
        if (here == Terrain.straight || here == Terrain.downhill) {
          if (v.aheadSameLane != null && v.staminaFraction < 0.55) {
            return const Telegraph(TelegraphKind.draft);
          }
          return const Telegraph(TelegraphKind.surge, magnitude: 3);
        }
        if (here == Terrain.mud || here == Terrain.gravel) {
          return const Telegraph(TelegraphKind.cruise, magnitude: 1);
        }
        return const Telegraph(TelegraphKind.cruise, magnitude: 2);
      },
    ),
  ];
}

/// A champion: a named rival with a title, a fixed archetype and better stock.
class Champion {
  const Champion({
    required this.id,
    required this.name,
    required this.title,
    required this.archetypeId,
    required this.venueId,
    required this.blurb,
    required this.staminaBonus,
    required this.strideBonus,
  });

  final String id;
  final String name;
  final String title;
  final String archetypeId;
  final String venueId;
  final String blurb;
  final int staminaBonus;
  final int strideBonus;

  static const List<Champion> all = [
    Champion(
      id: 'brass_hen',
      name: 'Brasslegs',
      title: 'The Sunhill Record',
      archetypeId: 'frontrunner',
      venueId: 'sunhill',
      blurb: 'Holds the Sunhill mark and has never been headed on a straight.',
      staminaBonus: 20,
      strideBonus: 2,
    ),
    Champion(
      id: 'grey_vane',
      name: 'Grey Vane',
      title: 'The Ridge Technician',
      archetypeId: 'technician',
      venueId: 'autumn_ridge',
      blurb: 'Has not overcooked a corner in four seasons.',
      staminaBonus: 26,
      strideBonus: 2,
    ),
    Champion(
      id: 'nightjar',
      name: 'Nightjar',
      title: 'Queen of the Oval',
      archetypeId: 'closer',
      venueId: 'midnight',
      blurb: 'Lets you lead for two laps, then takes the race in nine strides.',
      staminaBonus: 34,
      strideBonus: 3,
    ),
  ];

  static Champion forVenue(String venueId) =>
      all.firstWhere((c) => c.venueId == venueId, orElse: () => all.last);
}

/// Builds the rival field for a race.
class FieldFactory {
  FieldFactory._();

  static const List<String> _names = [
    'Corvine',
    'Thatch',
    'Bellows',
    'Pike',
    'Rasp',
    'Tinder',
    'Halyard',
    'Bramblewick',
    'Scour',
    'Mistral',
    'Copperpin',
    'Dunlin',
    'Fennel',
    'Gantry',
    'Hobble',
    'Ketch',
    'Lintel',
    'Mallow',
    'Notch',
    'Purlin',
  ];

  /// Creates [count] rivals scaled to [grade] and the player's [playerRating].
  static List<Contender> field({
    required int count,
    required int grade,
    required int playerRating,
    required Dice rng,
    Champion? champion,
  }) {
    final out = <Contender>[];
    final names = rng.sample(_names, count);

    for (var i = 0; i < count; i++) {
      final isChampion = champion != null && i == 0;
      final archetypeId = isChampion
          ? champion.archetypeId
          : rng.pick(Archetype.ids);
      final archetype = Archetype.byId(archetypeId);

      final genome = Heredity.random(rng, recessiveBias: 0.08 + grade * 0.05);
      final base = Build.of(genome);

      // Rivals are tuned against the player's own rating so a season stays
      // competitive whether the stable is bred well or badly, with grade adding
      // the real difficulty on top.
      final ratingGap = (playerRating - base.rating).clamp(-60, 120);
      final staminaLift =
          (ratingGap * 0.35).round() +
          grade * 5 +
          (isChampion ? champion.staminaBonus : 0);
      final strideLift =
          archetype.strideBonus +
          (grade >= 4 ? 1 : 0) +
          (isChampion ? champion.strideBonus : 0);

      final pheno = Build(
        staminaMax: ((base.staminaMax + staminaLift) * archetype.staminaScale)
            .round()
            .clamp(24, 260),
        stride: (base.stride + strideLift).clamp(2, 12),
        effort: base.effort,
        grip: base.grip,
        control: base.control,
        recovery: base.recovery + (grade >= 6 ? 2 : 0),
        hand: base.hand,
        momentumGain: base.momentumGain,
        maneuverIds: const [],
        expressedTraits: base.expressedTraits,
        pureTraits: base.pureTraits,
        synergies: base.synergies,
      );

      out.add(
        Contender(
          id: 'rival_$i',
          name: isChampion ? champion.name : names[i % names.length],
          title: isChampion ? champion.title : archetype.name,
          phenotype: pheno,
          plume: rng.int_(16),
          lane: 0,
          isPlayer: false,
          archetypeId: archetypeId,
        ),
      );
    }
    return out;
  }
}
