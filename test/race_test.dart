import 'package:flutter_test/flutter_test.dart';
import 'package:nestline_circuit/app/dice.dart';
import 'package:nestline_circuit/blood/heredity.dart';
import 'package:nestline_circuit/heat/maneuvers.dart';
import 'package:nestline_circuit/heat/contender.dart';
import 'package:nestline_circuit/heat/engine.dart';
import 'package:nestline_circuit/heat/rival.dart';
import 'package:nestline_circuit/heat/status.dart';
import 'package:nestline_circuit/heat/track.dart';

Build pheno({
  int stamina = 60,
  int stride = 4,
  int effort = 3,
  int grip = 0,
  int control = 1,
  int recovery = 4,
  int hand = 5,
  int momentumGain = 0,
  List<String> commands = const [
    'push',
    'push',
    'steady',
    'draft',
    'hold_line',
  ],
}) => Build(
  staminaMax: stamina,
  stride: stride,
  effort: effort,
  grip: grip,
  control: control,
  recovery: recovery,
  hand: hand,
  momentumGain: momentumGain,
  maneuverIds: commands,
  expressedTraits: const [],
  pureTraits: const [],
  synergies: const [],
);

Contender player({Build? p, int lane = 1}) => Contender(
  id: 'player',
  name: 'Hen',
  phenotype: p ?? pheno(),
  plume: 0,
  lane: lane,
  isPlayer: true,
);

Contender rival({
  String id = 'rival_0',
  String archetype = 'pacer',
  Build? p,
  int lane = 0,
}) => Contender(
  id: id,
  name: 'Rival',
  phenotype: p ?? pheno(),
  plume: 1,
  lane: lane,
  isPlayer: false,
  archetypeId: archetype,
);

Track flatTrack({
  Terrain terrain = Terrain.straight,
  int segments = 4,
  int length = 12,
}) => Track(
  venue: Venue.all.first,
  segments: List.generate(segments, (_) => Segment(terrain, length)),
  laps: 1,
);

HeatEngine engineWith({
  Track? track,
  Contender? me,
  List<Contender>? rivals,
  int seed = 1,
}) => HeatEngine(
  track: track ?? flatTrack(),
  player: me ?? player(),
  rivals: rivals ?? [rival()],
  rng: Dice(seed),
);

int handIndexOf(HeatEngine e, String commandId) =>
    e.hand.indexWhere((id) => id == commandId);

/// Forces [commandId] into the player's hand so a test can play it on demand.
void stackHand(HeatEngine e, String commandId) {
  e.hand.insert(0, commandId);
}

/// The engine owns the starting grid, so tests that need a specific geometry
/// place the rival themselves once the race exists.
Contender putRival(HeatEngine e, {required int lane, required double distance}) {
  final r = e.rivals.first;
  r.lane = lane;
  r.distance = distance;
  return r;
}

void main() {
  group('setup', () {
    test('the field is spread across lanes and the player starts inside', () {
      final e = engineWith(
        rivals: [
          rival(id: 'r0'),
          rival(id: 'r1'),
          rival(id: 'r2'),
        ],
      );
      expect(e.entrants.length, 4);
      expect(e.player.lane, 1);
      expect(e.player.distance, 0);
    });

    test('the hand is dealt to the phenotype hand size', () {
      final e = engineWith(
        me: player(p: pheno(hand: 4, commands: List.filled(10, 'push'))),
      );
      expect(e.hand.length, 4);
      expect(e.effort, 3);
    });

    test('the deck reshuffles from the discard rather than running dry', () {
      final e = engineWith(
        me: player(p: pheno(hand: 2, commands: ['push', 'push', 'steady'])),
      );
      for (var turn = 0; turn < 12; turn++) {
        if (e.phase == HeatPhase.finished) break;
        expect(e.hand, isNotEmpty, reason: 'ran out of cards on turn $turn');
        e.endTurn();
      }
    });
  });

  group('movement', () {
    test('a Push covers stride and bills stamina', () {
      final e = engineWith(me: player(p: pheno(stride: 5)));
      stackHand(e, 'push');
      final before = e.player.stamina;
      e.play(0);
      expect(e.player.distance, 5);
      expect(e.player.stamina, before - 5);
    });

    test('momentum adds free ground on the following move', () {
      final e = engineWith(me: player(p: pheno(stride: 4, effort: 4)));
      stackHand(e, 'push');
      e.play(0);
      final afterFirst = e.player.distance;
      expect(e.player.momentum, 1);
      stackHand(e, 'push');
      e.play(0);
      // Second push covers stride plus the momentum built by the first.
      expect(e.player.distance - afterFirst, 5);
    });

    test('momentum is capped', () {
      final e = engineWith(
        me: player(p: pheno(stamina: 400, effort: 40, momentumGain: 3)),
      );
      for (var i = 0; i < 10; i++) {
        stackHand(e, 'push');
        if (e.phase == HeatPhase.finished) break;
        e.play(0);
      }
      expect(e.player.momentum, lessThanOrEqualTo(HeatEngine.momentumCap));
    });

    test('a blown bird covers half the ground', () {
      final e = engineWith(me: player(p: pheno(stamina: 4, stride: 6)));
      stackHand(e, 'push');
      e.play(0);
      expect(e.player.blown, isTrue);
      final atZero = e.player.distance;
      stackHand(e, 'push');
      e.play(0);
      // Stride 6 plus 1 momentum, halved.
      expect(e.player.distance - atZero, 3);
    });

    test('Second Wind pays out instead of letting the bird blow up', () {
      // Stamina 4 against a 5-stamina Push, so the bird would otherwise blow.
      final e = engineWith(me: player(p: pheno(stamina: 4)));
      e.player.addStatus(Status.secondWind, 15);
      stackHand(e, 'push');
      e.play(0);
      expect(e.player.blown, isFalse);
      expect(e.player.stamina, 15);
      expect(e.player.status(Status.secondWind), 0);
    });
  });

  group('drafting', () {
    test('sitting behind a rival in the same lane makes moving cheaper', () {
      final tucked = engineWith(
        me: player(lane: 0),
        rivals: [rival(id: 'ahead')],
      );
      putRival(tucked, lane: tucked.player.lane, distance: 3);
      expect(tucked.isDrafting, isTrue);
      stackHand(tucked, 'push');
      final beforeTucked = tucked.player.stamina;
      tucked.play(0);
      final draftCost = beforeTucked - tucked.player.stamina;

      final alone = engineWith(
        me: player(lane: 2),
        rivals: [rival(id: 'far')],
      );
      putRival(alone, lane: 0, distance: 3);
      expect(alone.isDrafting, isFalse);
      stackHand(alone, 'push');
      final beforeAlone = alone.player.stamina;
      alone.play(0);
      final soloCost = beforeAlone - alone.player.stamina;

      expect(draftCost, lessThan(soloCost));
    });

    test('a rival too far ahead cannot be drafted', () {
      final e = engineWith(
        me: player(lane: 0),
        rivals: [rival(id: 'ahead')],
      );
      putRival(e, lane: e.player.lane, distance: HeatEngine.draftWindow + 5);
      expect(e.isDrafting, isFalse);
    });

    test('Slipstream halves the bill once and is then spent', () {
      final e = engineWith(me: player(p: pheno(effort: 6)));
      e.player.addStatus(Status.slipstream, 1);
      stackHand(e, 'push');
      final before = e.player.stamina;
      e.play(0);
      expect(before - e.player.stamina, 3);
      expect(e.player.status(Status.slipstream), 0);
    });
  });

  group('terrain', () {
    test('a corner burns the momentum you cannot control', () {
      final e = engineWith(
        track: flatTrack(terrain: Terrain.corner, length: 40),
        me: player(p: pheno(control: 1, effort: 6, stamina: 200)),
      );
      for (var i = 0; i < 4; i++) {
        stackHand(e, 'push');
        e.play(0);
      }
      final momentum = e.player.momentum;
      final control = e.player.control;
      final before = e.player.stamina;
      e.endTurn();
      expect(momentum, greaterThan(control));
      expect(e.player.stamina, lessThan(before));
      expect(e.player.momentum, lessThanOrEqualTo(control));
    });

    test('Composure absorbs corner burn', () {
      final soft = engineWith(
        track: flatTrack(terrain: Terrain.corner, length: 40),
        me: player(p: pheno(control: 0, effort: 6, stamina: 200)),
      );
      final hard = engineWith(
        track: flatTrack(terrain: Terrain.corner, length: 40),
        me: player(p: pheno(control: 0, effort: 6, stamina: 200)),
      );
      hard.player.addStatus(Status.composure, 6);

      for (final e in [soft, hard]) {
        for (var i = 0; i < 3; i++) {
          stackHand(e, 'push');
          e.play(0);
        }
      }
      final softBefore = soft.player.stamina;
      final hardBefore = hard.player.stamina;
      soft.endTurn();
      hard.endTurn();
      expect(
        softBefore - soft.player.stamina,
        greaterThan(hardBefore - hard.player.stamina),
      );
    });

    test('mud surcharges every move, and grip pays it down', () {
      final slick = engineWith(
        track: flatTrack(terrain: Terrain.mud, length: 40),
        me: player(p: pheno(grip: 0), lane: 2),
      );
      final gripped = engineWith(
        track: flatTrack(terrain: Terrain.mud, length: 40),
        me: player(p: pheno(grip: 2), lane: 2),
      );
      stackHand(slick, 'push');
      stackHand(gripped, 'push');
      final a = slick.player.stamina;
      final b = gripped.player.stamina;
      slick.play(0);
      gripped.play(0);
      expect(a - slick.player.stamina, greaterThan(b - gripped.player.stamina));
    });

    test('hay bales cost ground without grip and Flap prevents it', () {
      final bare = engineWith(
        track: flatTrack(terrain: Terrain.hay, length: 40),
        me: player(p: pheno(grip: 0), lane: 2),
      );
      final flapping = engineWith(
        track: flatTrack(terrain: Terrain.hay, length: 40),
        me: player(p: pheno(grip: 0), lane: 2),
      );
      flapping.player.addStatus(Status.flap, 1);

      stackHand(bare, 'push');
      stackHand(flapping, 'push');
      bare.play(0);
      flapping.play(0);
      final bareBefore = bare.player.distance;
      final flapBefore = flapping.player.distance;
      bare.endTurn();
      flapping.endTurn();

      expect(bare.player.distance, lessThan(bareBefore));
      expect(flapping.player.distance, greaterThanOrEqualTo(flapBefore));
    });

    test('a downhill hands out free ground', () {
      final e = engineWith(
        track: flatTrack(terrain: Terrain.downhill, length: 40),
        me: player(lane: 2),
      );
      final before = e.player.distance;
      e.endTurn();
      expect(e.player.distance, greaterThan(before));
    });
  });

  group('interference', () {
    test('a held line stops you passing through it', () {
      final e = engineWith(
        me: player(p: pheno(stride: 12, effort: 5), lane: 0),
        rivals: [rival(id: 'wall')],
      );
      final wall = putRival(e, lane: e.player.lane, distance: 6);
      wall.addStatus(Status.hold, 1);

      stackHand(e, 'push');
      e.play(0);
      expect(e.player.distance, lessThan(wall.distance));
    });

    test('a lane change into an occupied lane is refused', () {
      final e = engineWith(
        me: player(lane: 0),
        rivals: [rival(id: 'blocker')],
      );
      putRival(e, lane: 1, distance: e.player.distance);
      stackHand(e, 'cut_inside');
      e.play(0, lane: 1);
      expect(e.player.lane, 0);
    });

    test('Clipped locks a bird into her lane', () {
      final e = engineWith(me: player(lane: 0));
      e.player.addStatus(Status.clipped, 1);
      stackHand(e, 'cut_inside');
      e.play(0, lane: 2);
      expect(e.player.lane, 0);
    });

    test('Guard eats a Bruiser clip', () {
      final e = engineWith(
        me: player(lane: 0),
        rivals: [rival(id: 'bruiser_0', archetype: 'bruiser')],
      );
      e.player.addStatus(Status.guard, 1);
      putRival(e, lane: e.player.lane, distance: 1).intent = const Telegraph(
        TelegraphKind.clip,
      );
      e.endTurn();
      expect(e.player.status(Status.ruffled), 0);
    });

    test('an unguarded clip ruffles and strips momentum', () {
      final e = engineWith(
        me: player(lane: 0),
        rivals: [rival(id: 'bruiser_0', archetype: 'bruiser')],
      );
      e.player.momentum = 3;
      putRival(e, lane: e.player.lane, distance: 1).intent = const Telegraph(
        TelegraphKind.clip,
      );
      e.endTurn();
      expect(e.player.momentum, lessThan(3));
    });
  });

  group('effort', () {
    test('a command cannot be played without the effort for it', () {
      final e = engineWith(me: player(p: pheno(effort: 1)));
      stackHand(e, 'wild_kick');
      expect(e.canPlay(0), isFalse);
      expect(e.play(0), isFalse);
    });

    test('effort refreshes each turn and is reduced while blown', () {
      final e = engineWith(me: player(p: pheno(stamina: 3, effort: 3)));
      stackHand(e, 'push');
      e.play(0);
      expect(e.player.blown, isTrue);
      e.endTurn();
      expect(e.effort, 2);
    });

    test('Coronation trades wind for effort', () {
      final e = engineWith();
      stackHand(e, 'coronation');
      final before = e.effort;
      e.play(0);
      expect(e.effort, before + 3);
      expect(e.player.status(Status.winded), 1);
    });
  });

  group('finishing', () {
    test('crossing the line ends the race and assigns unique placements', () {
      final e = engineWith(
        track: flatTrack(segments: 1, length: 6),
        me: player(p: pheno(stride: 8)),
      );
      stackHand(e, 'push');
      e.play(0);
      expect(e.phase, HeatPhase.finished);
      final places = e.entrants.map((x) => x.placement).toList();
      expect(places.toSet().length, places.length);
      expect(e.result.placement, 1);
      expect(e.result.won, isTrue);
    });

    test('a race always terminates within the turn cap', () {
      for (var seed = 0; seed < 25; seed++) {
        final rng = Dice(seed);
        final venue = Venue.all[seed % Venue.all.length];
        final e = HeatEngine(
          track: Track.generate(venue, rng, laps: 2),
          player: player(
            p: Build.of(Heredity.random(rng, recessiveBias: 0.2)),
          ),
          rivals: FieldFactory.field(
            count: 4,
            grade: seed % 8,
            playerRating: 120,
            rng: rng,
          ),
          rng: rng,
        );
        var guard = 0;
        while (e.phase == HeatPhase.racing && guard < 200) {
          // Play whatever is affordable, then pass the turn.
          for (var i = e.hand.length - 1; i >= 0; i--) {
            if (e.canPlay(i)) e.play(i);
          }
          e.endTurn();
          guard++;
        }
        expect(e.phase, HeatPhase.finished, reason: 'seed $seed hung');
        expect(e.entrants.every((x) => x.placement > 0), isTrue);
      }
    });

    test('every rival archetype produces a legal intent every turn', () {
      for (final archetype in Archetype.ids) {
        final e = engineWith(
          track: flatTrack(segments: 3, length: 14),
          rivals: [rival(id: 'r', archetype: archetype)],
        );
        var guard = 0;
        while (e.phase == HeatPhase.racing && guard < 80) {
          for (final r in e.rivals) {
            if (!r.finished) expect(r.intent, isNotNull);
          }
          e.endTurn();
          guard++;
        }
        expect(e.phase, HeatPhase.finished, reason: '$archetype hung');
      }
    });
  });

  group('command library', () {
    test('every referenced command id resolves to a real command', () {
      for (final command in Maneuvers.all) {
        expect(Maneuvers.byId(command.id).id, command.id);
      }
    });

    test('every command in the library can resolve without throwing', () {
      for (final command in Maneuvers.all) {
        final e = engineWith(
          me: player(p: pheno(stamina: 200, effort: 12, hand: 5)),
          rivals: [rival(id: 'x', lane: 0)],
        );
        stackHand(e, command.id);
        expect(
          () => e.play(0, lane: 2),
          returnsNormally,
          reason: 'command ${command.id} threw',
        );
      }
    });

    test('no command leaves stamina or momentum out of range', () {
      for (final command in Maneuvers.all) {
        final e = engineWith(
          me: player(p: pheno(stamina: 90, effort: 12)),
          rivals: [rival(id: 'x', lane: 0)],
        );
        stackHand(e, command.id);
        e.play(0, lane: 0);
        expect(e.player.stamina, inInclusiveRange(0, e.player.staminaMax));
        expect(e.player.momentum, inInclusiveRange(0, HeatEngine.momentumCap));
      }
    });
  });
}
