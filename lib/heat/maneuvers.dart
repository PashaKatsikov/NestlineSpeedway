import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/heat/maneuver.dart';
import 'package:nestline_circuit/heat/status.dart';

/// Every command in the game. Ids are referenced by allele tables, synergies and
/// tack, so an id here is a contract — rename one and you break a genome.
class Maneuvers {
  Maneuvers._();

  static final Map<String, Maneuver> _byId = {for (final c in all) c.id: c};

  static Maneuver byId(String id) => _byId[id] ?? _fallback;

  static final Maneuver _fallback = Maneuver(
    id: 'push',
    name: 'Push',
    kind: ManeuverKind.move,
    origin: ManeuverOrigin.core,
    effort: 1,
    text: 'Move at your stride.',
    icon: Atlas.trainer(0),
    effect: (api) => api.move(staminaCost: 5),
  );

  static final List<Maneuver> all = [
    // ------------------------------------------------------------------ core
    Maneuver(
      id: 'push',
      name: 'Push',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.core,
      effort: 1,
      text: 'Move at your stride. Costs 5 stamina.',
      icon: Atlas.trainer(0),
      effect: (api) => api.move(staminaCost: 5),
    ),
    Maneuver(
      id: 'steady',
      name: 'Steady',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.core,
      effort: 1,
      text: 'Recover your recovery +2 stamina. Gain 1 Composure.',
      icon: Atlas.remedy(7),
      effect: (api) {
        api.recover(api.actor.phenotype.recovery + 2);
        api.status(Status.composure, 1);
      },
    ),
    Maneuver(
      id: 'draft',
      name: 'Draft',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.core,
      effort: 1,
      text:
          'Gain Slipstream. If you are already tucked in behind a rival, '
          'recover 4 stamina as well.',
      icon: Atlas.plume(3),
      effect: (api) {
        api.status(Status.slipstream, 1);
        if (api.isDrafting) {
          api.recover(4);
          api.log('${api.actor.name} sits in the slipstream.');
        }
      },
    ),
    Maneuver(
      id: 'cut_inside',
      name: 'Cut Inside',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.core,
      effort: 1,
      needsLane: true,
      text: 'Change lane. Gain 1 momentum if the new lane is clear.',
      icon: Atlas.tack(6),
      effect: (api) {
        api.changeLane();
        api.gainMomentum(1);
      },
    ),
    Maneuver(
      id: 'hold_line',
      name: 'Hold Line',
      kind: ManeuverKind.guard,
      origin: ManeuverOrigin.core,
      effort: 1,
      text: 'Gain 1 Holding and 1 Guard. Rivals cannot pass through your lane.',
      icon: Atlas.tack(12),
      effect: (api) {
        api.status(Status.hold, 1);
        api.status(Status.guard, 1);
      },
    ),

    // ----------------------------------------------------------------- trait
    Maneuver(
      id: 'stretch_out',
      name: 'Stretch Out',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.trait,
      effort: 2,
      text: 'Move at stride +3. Costs 8 stamina.',
      icon: Atlas.plume(1),
      effect: (api) => api.move(bonus: 3, staminaCost: 8),
    ),
    Maneuver(
      id: 'tidy_feet',
      name: 'Tidy Feet',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Move at stride +1 for only 4 stamina. Gain 1 Composure.',
      icon: Atlas.trainer(3),
      effect: (api) {
        api.move(bonus: 1, staminaCost: 4);
        api.status(Status.composure, 1);
      },
    ),
    Maneuver(
      id: 'gather',
      name: 'Gather',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Gain 2 momentum and recover 2 stamina.',
      icon: Atlas.herb(4),
      effect: (api) {
        api.gainMomentum(2);
        api.recover(2);
      },
    ),
    Maneuver(
      id: 'lung_up',
      name: 'Lung Up',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Recover your recovery +4 stamina.',
      icon: Atlas.remedy(4),
      effect: (api) => api.recover(api.actor.phenotype.recovery + 4),
    ),
    Maneuver(
      id: 'settle',
      name: 'Settle',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 0,
      text: 'Free. Recover your recovery in stamina.',
      icon: Atlas.remedy(3),
      effect: (api) => api.recover(api.actor.phenotype.recovery),
    ),
    Maneuver(
      id: 'snatch_air',
      name: 'Snatch Air',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 0,
      text: 'Free. Recover 8 stamina but gain 1 Winded.',
      icon: Atlas.remedy(5),
      effect: (api) {
        api.recover(8);
        api.status(Status.winded, 1);
      },
    ),
    Maneuver(
      id: 'measure',
      name: 'Measure',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Gain 2 Composure and 1 Focus.',
      icon: Atlas.trainer(6),
      effect: (api) {
        api.status(Status.composure, 2);
        api.status(Status.focus, 1);
      },
    ),
    Maneuver(
      id: 'press_on',
      name: 'Press On',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Move at stride +2 for 6 stamina. Gain 1 Ruffled.',
      icon: Atlas.trainer(8),
      effect: (api) {
        api.move(bonus: 2, staminaCost: 6);
        api.status(Status.ruffled, 1);
      },
    ),
    Maneuver(
      id: 'bolt',
      name: 'Bolt',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.trait,
      effort: 2,
      text: 'Move at stride +5 for 12 stamina. Gain 2 momentum and 1 Winded.',
      icon: Atlas.herb(11),
      effect: (api) {
        api.move(bonus: 5, staminaCost: 12);
        api.gainMomentum(2);
        api.status(Status.winded, 1);
      },
    ),
    Maneuver(
      id: 'dig_in',
      name: 'Dig In',
      kind: ManeuverKind.guard,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Gain 2 Guard and 1 Flap.',
      icon: Atlas.tack(20),
      effect: (api) {
        api.status(Status.guard, 2);
        api.status(Status.flap, 1);
      },
    ),
    Maneuver(
      id: 'play_crowd',
      name: 'Play the Crowd',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Gain 1 effort now and 1 Frenzy.',
      icon: Atlas.trophy(6),
      effect: (api) {
        api.gainEffort(1);
        api.status(Status.frenzy, 1);
      },
    ),
    Maneuver(
      id: 'clean_line',
      name: 'Clean Line',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 0,
      text: 'Free. Remove one bad status and recover 4 stamina.',
      icon: Atlas.remedy(1),
      effect: (api) {
        api.clearNegative(1);
        api.recover(4);
      },
    ),
    Maneuver(
      id: 'shimmer',
      name: 'Shimmer',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Draw 2 commands.',
      icon: Atlas.plume(2),
      effect: (api) => api.draw(2),
    ),
    Maneuver(
      id: 'compose',
      name: 'Compose',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 0,
      text: 'Free. Gain 1 Composure and recover 3 stamina.',
      icon: Atlas.remedy(8),
      effect: (api) {
        api.status(Status.composure, 1);
        api.recover(3);
      },
    ),
    Maneuver(
      id: 'read_race',
      name: 'Read the Race',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 0,
      text: 'Free. Draw 1 and gain 1 Focus.',
      icon: Atlas.tack(30),
      effect: (api) {
        api.draw(1);
        api.status(Status.focus, 1);
      },
    ),
    Maneuver(
      id: 'crown_surge',
      name: 'Crown Surge',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Move at stride +2 for 7 stamina. Gain 1 momentum.',
      icon: Atlas.tack(1),
      effect: (api) {
        api.move(bonus: 2, staminaCost: 7);
        api.gainMomentum(1);
      },
    ),
    Maneuver(
      id: 'plant_foot',
      name: 'Plant Foot',
      kind: ManeuverKind.guard,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Gain 2 Guard and 1 Composure.',
      icon: Atlas.trainer(11),
      effect: (api) {
        api.status(Status.guard, 2);
        api.status(Status.composure, 1);
      },
    ),
    Maneuver(
      id: 'find_line',
      name: 'Find the Line',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 1,
      text: 'Gain 1 Flap and 1 momentum.',
      icon: Atlas.herb(19),
      effect: (api) {
        api.status(Status.flap, 1);
        api.gainMomentum(1);
      },
    ),
    Maneuver(
      id: 'hook_turn',
      name: 'Hook Turn',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.trait,
      effort: 1,
      needsLane: true,
      text: 'Change lane, gain 2 momentum and cover 2 ground.',
      icon: Atlas.tack(9),
      effect: (api) {
        api.changeLane();
        api.gainMomentum(2);
        api.move(bonus: -api.actor.effectiveStride + 2, staminaCost: 0);
      },
    ),

    // ------------------------------------------------------------- signature
    Maneuver(
      id: 'ground_eater',
      name: 'Ground Eater',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.signature,
      effort: 2,
      text: 'Move at stride +6 for 10 stamina.',
      icon: Atlas.plume(1),
      effect: (api) => api.move(bonus: 6, staminaCost: 10),
    ),
    Maneuver(
      id: 'inside_shuffle',
      name: 'Inside Shuffle',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.signature,
      effort: 1,
      needsLane: true,
      text: 'Change lane for free, then move at stride +2 for 3 stamina.',
      icon: Atlas.tack(7),
      effect: (api) {
        api.changeLane();
        api.move(bonus: 2, staminaCost: 3);
        api.status(Status.composure, 1);
      },
    ),
    Maneuver(
      id: 'bound',
      name: 'Bound',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.signature,
      effort: 2,
      text:
          'Move at stride plus twice your momentum, for 6 stamina. Momentum '
          'is kept.',
      icon: Atlas.herb(7),
      effect: (api) => api.move(extra: api.momentum * 2, staminaCost: 6),
    ),
    Maneuver(
      id: 'bottomless',
      name: 'Bottomless',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.signature,
      effort: 1,
      text: 'Recover 20 stamina and gain 2 Composure.',
      icon: Atlas.remedy(0),
      effect: (api) {
        api.recover(20);
        api.status(Status.composure, 2);
      },
    ),
    Maneuver(
      id: 'metronome',
      name: 'Metronome',
      kind: ManeuverKind.form,
      origin: ManeuverOrigin.signature,
      effort: 1,
      text: 'Recover twice your recovery and gain 2 Composure and 1 Focus.',
      icon: Atlas.trainer(13),
      effect: (api) {
        api.recover(api.actor.phenotype.recovery * 2);
        api.status(Status.composure, 2);
        api.status(Status.focus, 1);
      },
    ),
    Maneuver(
      id: 'second_wind',
      name: 'Second Wind',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.signature,
      effort: 0,
      text:
          'Free. Bank three times your recovery. It pays out the moment you '
          'go Blown.',
      icon: Atlas.remedy(6),
      effect: (api) =>
          api.status(Status.secondWind, api.actor.phenotype.recovery * 3),
    ),
    Maneuver(
      id: 'ice_line',
      name: 'Ice Line',
      kind: ManeuverKind.form,
      origin: ManeuverOrigin.signature,
      effort: 1,
      text: 'Gain 4 Composure. Corners cannot burn you while it lasts.',
      icon: Atlas.herb(23),
      effect: (api) => api.status(Status.composure, 4),
    ),
    Maneuver(
      id: 'front_run',
      name: 'Front Run',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.signature,
      effort: 2,
      text: 'Move at stride +4 for 9 stamina. If you lead, gain 2 Frenzy.',
      icon: Atlas.trophy(9),
      effect: (api) {
        api.move(bonus: 4, staminaCost: 9);
        if (api.isLeading) api.status(Status.frenzy, 2);
      },
    ),
    Maneuver(
      id: 'wild_kick',
      name: 'Wild Kick',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.signature,
      effort: 3,
      text: 'Move at stride +9 for 18 stamina. Gain 2 Ruffled.',
      icon: Atlas.herb(28),
      effect: (api) {
        api.move(bonus: 9, staminaCost: 18);
        api.status(Status.ruffled, 2);
      },
    ),
    Maneuver(
      id: 'mudlark',
      name: 'Mudlark',
      kind: ManeuverKind.form,
      origin: ManeuverOrigin.signature,
      effort: 1,
      text: 'Gain 3 Guard and 2 Flap.',
      icon: Atlas.tack(24),
      effect: (api) {
        api.status(Status.guard, 3);
        api.status(Status.flap, 2);
      },
    ),
    Maneuver(
      id: 'golden_hour',
      name: 'Golden Hour',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.signature,
      effort: 1,
      text: 'Gain 2 Frenzy, 1 effort and recover 6 stamina.',
      icon: Atlas.trophy(16),
      effect: (api) {
        api.status(Status.frenzy, 2);
        api.gainEffort(1);
        api.recover(6);
      },
    ),
    Maneuver(
      id: 'white_flash',
      name: 'White Flash',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.signature,
      effort: 1,
      text: 'Move at stride +3 for 5 stamina, then draw 1.',
      icon: Atlas.plume(0),
      effect: (api) {
        api.move(bonus: 3, staminaCost: 5);
        api.draw(1);
      },
    ),
    Maneuver(
      id: 'prism_run',
      name: 'Prism Run',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.signature,
      effort: 1,
      text: 'Draw 3 and gain 1 effort.',
      icon: Atlas.plume(2),
      effect: (api) {
        api.draw(3);
        api.gainEffort(1);
      },
    ),
    Maneuver(
      id: 'workhorse',
      name: 'Workhorse',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.signature,
      effort: 0,
      text: 'Free. Recover 6, gain 1 Composure and draw 1.',
      icon: Atlas.trainer(2),
      effect: (api) {
        api.recover(6);
        api.status(Status.composure, 1);
        api.draw(1);
      },
    ),
    Maneuver(
      id: 'rose_gambit',
      name: 'Rose Gambit',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.signature,
      effort: 0,
      text: 'Free. Draw 2 and gain 2 Focus.',
      icon: Atlas.tack(33),
      effect: (api) {
        api.draw(2);
        api.status(Status.focus, 2);
      },
    ),
    Maneuver(
      id: 'coronation',
      name: 'Coronation',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.signature,
      effort: 0,
      text: 'Free. Gain 3 effort but take 1 Winded.',
      icon: Atlas.tack(2),
      effect: (api) {
        api.gainEffort(3);
        api.status(Status.winded, 1);
      },
    ),
    Maneuver(
      id: 'anchor',
      name: 'Anchor',
      kind: ManeuverKind.guard,
      origin: ManeuverOrigin.signature,
      effort: 1,
      text: 'Gain 4 Guard and 2 Holding.',
      icon: Atlas.trainer(10),
      effect: (api) {
        api.status(Status.guard, 4);
        api.status(Status.hold, 2);
      },
    ),
    Maneuver(
      id: 'dry_line',
      name: 'Dry Line',
      kind: ManeuverKind.form,
      origin: ManeuverOrigin.signature,
      effort: 1,
      text: 'Gain 3 Flap and 2 momentum.',
      icon: Atlas.herb(14),
      effect: (api) {
        api.status(Status.flap, 3);
        api.gainMomentum(2);
      },
    ),
    Maneuver(
      id: 'switchback',
      name: 'Switchback',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.signature,
      effort: 1,
      needsLane: true,
      text: 'Change lane, gain 3 momentum and cover 4 ground.',
      icon: Atlas.tack(11),
      effect: (api) {
        api.changeLane();
        api.gainMomentum(3);
        api.move(bonus: -api.actor.effectiveStride + 4, staminaCost: 0);
      },
    ),

    // --------------------------------------------------------------- synergy
    Maneuver(
      id: 'thunder_hop',
      name: 'Thunder Hop',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.synergy,
      effort: 3,
      text: 'Move at stride plus three times your momentum, for 14 stamina.',
      icon: Atlas.herb(30),
      effect: (api) => api.move(extra: api.momentum * 3, staminaCost: 14),
    ),
    Maneuver(
      id: 'perpetual',
      name: 'Perpetual Motion',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.synergy,
      effort: 0,
      text: 'Free. Gain 2 effort and recover 10 stamina.',
      icon: Atlas.tack(3),
      effect: (api) {
        api.gainEffort(2);
        api.recover(10);
      },
    ),
    Maneuver(
      id: 'kaleidoscope',
      name: 'Kaleidoscope',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.synergy,
      effort: 1,
      text: 'Draw 4 and gain 2 effort.',
      icon: Atlas.plume(2),
      effect: (api) {
        api.draw(4);
        api.gainEffort(2);
      },
    ),
    Maneuver(
      id: 'pivot_master',
      name: 'Pivot Master',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.synergy,
      effort: 1,
      needsLane: true,
      text:
          'Change lane free, move at stride +3 for 4 stamina, gain 2 momentum.',
      icon: Atlas.tack(15),
      effect: (api) {
        api.changeLane();
        api.move(bonus: 3, staminaCost: 4);
        api.gainMomentum(2);
      },
    ),
    Maneuver(
      id: 'diesel',
      name: 'Diesel',
      kind: ManeuverKind.form,
      origin: ManeuverOrigin.synergy,
      effort: 1,
      text: 'Gain 5 Composure and recover 15 stamina.',
      icon: Atlas.remedy(0),
      effect: (api) {
        api.status(Status.composure, 5);
        api.recover(15);
      },
    ),
    Maneuver(
      id: 'all_weather',
      name: 'All Weather',
      kind: ManeuverKind.form,
      origin: ManeuverOrigin.synergy,
      effort: 1,
      text: 'Gain 4 Flap and 2 Guard. Terrain stops mattering for a while.',
      icon: Atlas.tack(26),
      effect: (api) {
        api.status(Status.flap, 4);
        api.status(Status.guard, 2);
      },
    ),
    Maneuver(
      id: 'long_bomb',
      name: 'Long Bomb',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.synergy,
      effort: 3,
      text: 'Move at stride +8 for 16 stamina and gain 2 momentum.',
      icon: Atlas.plume(9),
      effect: (api) {
        api.move(bonus: 8, staminaCost: 16);
        api.gainMomentum(2);
      },
    ),
    Maneuver(
      id: 'clockwork',
      name: 'Clockwork',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.synergy,
      effort: 0,
      text: 'Free. Recover twice your recovery and draw 2.',
      icon: Atlas.trainer(13),
      effect: (api) {
        api.recover(api.actor.phenotype.recovery * 2);
        api.draw(2);
      },
    ),
    Maneuver(
      id: 'sleight',
      name: 'Sleight',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.synergy,
      effort: 0,
      needsLane: true,
      text: 'Free. Change lane, draw 2 and gain 2 momentum.',
      icon: Atlas.tack(35),
      effect: (api) {
        api.changeLane();
        api.draw(2);
        api.gainMomentum(2);
      },
    ),
    Maneuver(
      id: 'runaway',
      name: 'Runaway',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.synergy,
      effort: 2,
      text: 'Move at stride +6 for 12 stamina and gain 3 momentum.',
      icon: Atlas.herb(25),
      effect: (api) {
        api.move(bonus: 6, staminaCost: 12);
        api.gainMomentum(3);
      },
    ),
    Maneuver(
      id: 'showstopper',
      name: 'Showstopper',
      kind: ManeuverKind.skill,
      origin: ManeuverOrigin.synergy,
      effort: 1,
      text: 'Gain 3 Frenzy, 1 effort and recover 12 stamina.',
      icon: Atlas.trophy(13),
      effect: (api) {
        api.status(Status.frenzy, 3);
        api.gainEffort(1);
        api.recover(12);
      },
    ),
    Maneuver(
      id: 'freight',
      name: 'Freight',
      kind: ManeuverKind.move,
      origin: ManeuverOrigin.synergy,
      effort: 2,
      text: 'Move at stride +5 for 9 stamina. Gain 3 Guard and 2 Holding.',
      icon: Atlas.trainer(9),
      effect: (api) {
        api.move(bonus: 5, staminaCost: 9);
        api.status(Status.guard, 3);
        api.status(Status.hold, 2);
      },
    ),
  ];
}
