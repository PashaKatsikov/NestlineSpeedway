import '../core/sprites.dart';
import 'command.dart';
import 'status.dart';

/// Every command in the game. Ids are referenced by allele tables, synergies and
/// tack, so an id here is a contract — rename one and you break a genome.
class Commands {
  Commands._();

  static final Map<String, Command> _byId = {for (final c in all) c.id: c};

  static Command byId(String id) => _byId[id] ?? _fallback;

  static final Command _fallback = Command(
    id: 'push',
    name: 'Push',
    kind: CommandKind.move,
    origin: CommandOrigin.core,
    effort: 1,
    text: 'Move at your stride.',
    icon: Sprites.trainer(0),
    effect: (api) => api.move(staminaCost: 5),
  );

  static final List<Command> all = [
    // ------------------------------------------------------------------ core
    Command(
      id: 'push',
      name: 'Push',
      kind: CommandKind.move,
      origin: CommandOrigin.core,
      effort: 1,
      text: 'Move at your stride. Costs 5 stamina.',
      icon: Sprites.trainer(0),
      effect: (api) => api.move(staminaCost: 5),
    ),
    Command(
      id: 'steady',
      name: 'Steady',
      kind: CommandKind.skill,
      origin: CommandOrigin.core,
      effort: 1,
      text: 'Recover your recovery +2 stamina. Gain 1 Composure.',
      icon: Sprites.remedy(7),
      effect: (api) {
        api.recover(api.actor.phenotype.recovery + 2);
        api.status(Status.composure, 1);
      },
    ),
    Command(
      id: 'draft',
      name: 'Draft',
      kind: CommandKind.skill,
      origin: CommandOrigin.core,
      effort: 1,
      text:
          'Gain Slipstream. If you are already tucked in behind a rival, '
          'recover 4 stamina as well.',
      icon: Sprites.plume(3),
      effect: (api) {
        api.status(Status.slipstream, 1);
        if (api.isDrafting) {
          api.recover(4);
          api.log('${api.actor.name} sits in the slipstream.');
        }
      },
    ),
    Command(
      id: 'cut_inside',
      name: 'Cut Inside',
      kind: CommandKind.skill,
      origin: CommandOrigin.core,
      effort: 1,
      needsLane: true,
      text: 'Change lane. Gain 1 momentum if the new lane is clear.',
      icon: Sprites.tack(6),
      effect: (api) {
        api.changeLane();
        api.gainMomentum(1);
      },
    ),
    Command(
      id: 'hold_line',
      name: 'Hold Line',
      kind: CommandKind.guard,
      origin: CommandOrigin.core,
      effort: 1,
      text: 'Gain 1 Holding and 1 Guard. Rivals cannot pass through your lane.',
      icon: Sprites.tack(12),
      effect: (api) {
        api.status(Status.hold, 1);
        api.status(Status.guard, 1);
      },
    ),

    // ----------------------------------------------------------------- trait
    Command(
      id: 'stretch_out',
      name: 'Stretch Out',
      kind: CommandKind.move,
      origin: CommandOrigin.trait,
      effort: 2,
      text: 'Move at stride +3. Costs 8 stamina.',
      icon: Sprites.plume(1),
      effect: (api) => api.move(bonus: 3, staminaCost: 8),
    ),
    Command(
      id: 'tidy_feet',
      name: 'Tidy Feet',
      kind: CommandKind.move,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Move at stride +1 for only 4 stamina. Gain 1 Composure.',
      icon: Sprites.trainer(3),
      effect: (api) {
        api.move(bonus: 1, staminaCost: 4);
        api.status(Status.composure, 1);
      },
    ),
    Command(
      id: 'gather',
      name: 'Gather',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Gain 2 momentum and recover 2 stamina.',
      icon: Sprites.herb(4),
      effect: (api) {
        api.gainMomentum(2);
        api.recover(2);
      },
    ),
    Command(
      id: 'lung_up',
      name: 'Lung Up',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Recover your recovery +4 stamina.',
      icon: Sprites.remedy(4),
      effect: (api) => api.recover(api.actor.phenotype.recovery + 4),
    ),
    Command(
      id: 'settle',
      name: 'Settle',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 0,
      text: 'Free. Recover your recovery in stamina.',
      icon: Sprites.remedy(3),
      effect: (api) => api.recover(api.actor.phenotype.recovery),
    ),
    Command(
      id: 'snatch_air',
      name: 'Snatch Air',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 0,
      text: 'Free. Recover 8 stamina but gain 1 Winded.',
      icon: Sprites.remedy(5),
      effect: (api) {
        api.recover(8);
        api.status(Status.winded, 1);
      },
    ),
    Command(
      id: 'measure',
      name: 'Measure',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Gain 2 Composure and 1 Focus.',
      icon: Sprites.trainer(6),
      effect: (api) {
        api.status(Status.composure, 2);
        api.status(Status.focus, 1);
      },
    ),
    Command(
      id: 'press_on',
      name: 'Press On',
      kind: CommandKind.move,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Move at stride +2 for 6 stamina. Gain 1 Ruffled.',
      icon: Sprites.trainer(8),
      effect: (api) {
        api.move(bonus: 2, staminaCost: 6);
        api.status(Status.ruffled, 1);
      },
    ),
    Command(
      id: 'bolt',
      name: 'Bolt',
      kind: CommandKind.move,
      origin: CommandOrigin.trait,
      effort: 2,
      text: 'Move at stride +5 for 12 stamina. Gain 2 momentum and 1 Winded.',
      icon: Sprites.herb(11),
      effect: (api) {
        api.move(bonus: 5, staminaCost: 12);
        api.gainMomentum(2);
        api.status(Status.winded, 1);
      },
    ),
    Command(
      id: 'dig_in',
      name: 'Dig In',
      kind: CommandKind.guard,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Gain 2 Guard and 1 Flap.',
      icon: Sprites.tack(20),
      effect: (api) {
        api.status(Status.guard, 2);
        api.status(Status.flap, 1);
      },
    ),
    Command(
      id: 'play_crowd',
      name: 'Play the Crowd',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Gain 1 effort now and 1 Frenzy.',
      icon: Sprites.trophy(6),
      effect: (api) {
        api.gainEffort(1);
        api.status(Status.frenzy, 1);
      },
    ),
    Command(
      id: 'clean_line',
      name: 'Clean Line',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 0,
      text: 'Free. Remove one bad status and recover 4 stamina.',
      icon: Sprites.remedy(1),
      effect: (api) {
        api.clearNegative(1);
        api.recover(4);
      },
    ),
    Command(
      id: 'shimmer',
      name: 'Shimmer',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Draw 2 commands.',
      icon: Sprites.plume(2),
      effect: (api) => api.draw(2),
    ),
    Command(
      id: 'compose',
      name: 'Compose',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 0,
      text: 'Free. Gain 1 Composure and recover 3 stamina.',
      icon: Sprites.remedy(8),
      effect: (api) {
        api.status(Status.composure, 1);
        api.recover(3);
      },
    ),
    Command(
      id: 'read_race',
      name: 'Read the Race',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 0,
      text: 'Free. Draw 1 and gain 1 Focus.',
      icon: Sprites.tack(30),
      effect: (api) {
        api.draw(1);
        api.status(Status.focus, 1);
      },
    ),
    Command(
      id: 'crown_surge',
      name: 'Crown Surge',
      kind: CommandKind.move,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Move at stride +2 for 7 stamina. Gain 1 momentum.',
      icon: Sprites.tack(1),
      effect: (api) {
        api.move(bonus: 2, staminaCost: 7);
        api.gainMomentum(1);
      },
    ),
    Command(
      id: 'plant_foot',
      name: 'Plant Foot',
      kind: CommandKind.guard,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Gain 2 Guard and 1 Composure.',
      icon: Sprites.trainer(11),
      effect: (api) {
        api.status(Status.guard, 2);
        api.status(Status.composure, 1);
      },
    ),
    Command(
      id: 'find_line',
      name: 'Find the Line',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 1,
      text: 'Gain 1 Flap and 1 momentum.',
      icon: Sprites.herb(19),
      effect: (api) {
        api.status(Status.flap, 1);
        api.gainMomentum(1);
      },
    ),
    Command(
      id: 'hook_turn',
      name: 'Hook Turn',
      kind: CommandKind.skill,
      origin: CommandOrigin.trait,
      effort: 1,
      needsLane: true,
      text: 'Change lane, gain 2 momentum and cover 2 ground.',
      icon: Sprites.tack(9),
      effect: (api) {
        api.changeLane();
        api.gainMomentum(2);
        api.move(bonus: -api.actor.effectiveStride + 2, staminaCost: 0);
      },
    ),

    // ------------------------------------------------------------- signature
    Command(
      id: 'ground_eater',
      name: 'Ground Eater',
      kind: CommandKind.move,
      origin: CommandOrigin.signature,
      effort: 2,
      text: 'Move at stride +6 for 10 stamina.',
      icon: Sprites.plume(1),
      effect: (api) => api.move(bonus: 6, staminaCost: 10),
    ),
    Command(
      id: 'inside_shuffle',
      name: 'Inside Shuffle',
      kind: CommandKind.move,
      origin: CommandOrigin.signature,
      effort: 1,
      needsLane: true,
      text: 'Change lane for free, then move at stride +2 for 3 stamina.',
      icon: Sprites.tack(7),
      effect: (api) {
        api.changeLane();
        api.move(bonus: 2, staminaCost: 3);
        api.status(Status.composure, 1);
      },
    ),
    Command(
      id: 'bound',
      name: 'Bound',
      kind: CommandKind.move,
      origin: CommandOrigin.signature,
      effort: 2,
      text:
          'Move at stride plus twice your momentum, for 6 stamina. Momentum '
          'is kept.',
      icon: Sprites.herb(7),
      effect: (api) => api.move(extra: api.momentum * 2, staminaCost: 6),
    ),
    Command(
      id: 'bottomless',
      name: 'Bottomless',
      kind: CommandKind.skill,
      origin: CommandOrigin.signature,
      effort: 1,
      text: 'Recover 20 stamina and gain 2 Composure.',
      icon: Sprites.remedy(0),
      effect: (api) {
        api.recover(20);
        api.status(Status.composure, 2);
      },
    ),
    Command(
      id: 'metronome',
      name: 'Metronome',
      kind: CommandKind.form,
      origin: CommandOrigin.signature,
      effort: 1,
      text: 'Recover twice your recovery and gain 2 Composure and 1 Focus.',
      icon: Sprites.trainer(13),
      effect: (api) {
        api.recover(api.actor.phenotype.recovery * 2);
        api.status(Status.composure, 2);
        api.status(Status.focus, 1);
      },
    ),
    Command(
      id: 'second_wind',
      name: 'Second Wind',
      kind: CommandKind.skill,
      origin: CommandOrigin.signature,
      effort: 0,
      text:
          'Free. Bank three times your recovery. It pays out the moment you '
          'go Blown.',
      icon: Sprites.remedy(6),
      effect: (api) =>
          api.status(Status.secondWind, api.actor.phenotype.recovery * 3),
    ),
    Command(
      id: 'ice_line',
      name: 'Ice Line',
      kind: CommandKind.form,
      origin: CommandOrigin.signature,
      effort: 1,
      text: 'Gain 4 Composure. Corners cannot burn you while it lasts.',
      icon: Sprites.herb(23),
      effect: (api) => api.status(Status.composure, 4),
    ),
    Command(
      id: 'front_run',
      name: 'Front Run',
      kind: CommandKind.move,
      origin: CommandOrigin.signature,
      effort: 2,
      text: 'Move at stride +4 for 9 stamina. If you lead, gain 2 Frenzy.',
      icon: Sprites.trophy(9),
      effect: (api) {
        api.move(bonus: 4, staminaCost: 9);
        if (api.isLeading) api.status(Status.frenzy, 2);
      },
    ),
    Command(
      id: 'wild_kick',
      name: 'Wild Kick',
      kind: CommandKind.move,
      origin: CommandOrigin.signature,
      effort: 3,
      text: 'Move at stride +9 for 18 stamina. Gain 2 Ruffled.',
      icon: Sprites.herb(28),
      effect: (api) {
        api.move(bonus: 9, staminaCost: 18);
        api.status(Status.ruffled, 2);
      },
    ),
    Command(
      id: 'mudlark',
      name: 'Mudlark',
      kind: CommandKind.form,
      origin: CommandOrigin.signature,
      effort: 1,
      text: 'Gain 3 Guard and 2 Flap.',
      icon: Sprites.tack(24),
      effect: (api) {
        api.status(Status.guard, 3);
        api.status(Status.flap, 2);
      },
    ),
    Command(
      id: 'golden_hour',
      name: 'Golden Hour',
      kind: CommandKind.skill,
      origin: CommandOrigin.signature,
      effort: 1,
      text: 'Gain 2 Frenzy, 1 effort and recover 6 stamina.',
      icon: Sprites.trophy(16),
      effect: (api) {
        api.status(Status.frenzy, 2);
        api.gainEffort(1);
        api.recover(6);
      },
    ),
    Command(
      id: 'white_flash',
      name: 'White Flash',
      kind: CommandKind.move,
      origin: CommandOrigin.signature,
      effort: 1,
      text: 'Move at stride +3 for 5 stamina, then draw 1.',
      icon: Sprites.plume(0),
      effect: (api) {
        api.move(bonus: 3, staminaCost: 5);
        api.draw(1);
      },
    ),
    Command(
      id: 'prism_run',
      name: 'Prism Run',
      kind: CommandKind.skill,
      origin: CommandOrigin.signature,
      effort: 1,
      text: 'Draw 3 and gain 1 effort.',
      icon: Sprites.plume(2),
      effect: (api) {
        api.draw(3);
        api.gainEffort(1);
      },
    ),
    Command(
      id: 'workhorse',
      name: 'Workhorse',
      kind: CommandKind.skill,
      origin: CommandOrigin.signature,
      effort: 0,
      text: 'Free. Recover 6, gain 1 Composure and draw 1.',
      icon: Sprites.trainer(2),
      effect: (api) {
        api.recover(6);
        api.status(Status.composure, 1);
        api.draw(1);
      },
    ),
    Command(
      id: 'rose_gambit',
      name: 'Rose Gambit',
      kind: CommandKind.skill,
      origin: CommandOrigin.signature,
      effort: 0,
      text: 'Free. Draw 2 and gain 2 Focus.',
      icon: Sprites.tack(33),
      effect: (api) {
        api.draw(2);
        api.status(Status.focus, 2);
      },
    ),
    Command(
      id: 'coronation',
      name: 'Coronation',
      kind: CommandKind.skill,
      origin: CommandOrigin.signature,
      effort: 0,
      text: 'Free. Gain 3 effort but take 1 Winded.',
      icon: Sprites.tack(2),
      effect: (api) {
        api.gainEffort(3);
        api.status(Status.winded, 1);
      },
    ),
    Command(
      id: 'anchor',
      name: 'Anchor',
      kind: CommandKind.guard,
      origin: CommandOrigin.signature,
      effort: 1,
      text: 'Gain 4 Guard and 2 Holding.',
      icon: Sprites.trainer(10),
      effect: (api) {
        api.status(Status.guard, 4);
        api.status(Status.hold, 2);
      },
    ),
    Command(
      id: 'dry_line',
      name: 'Dry Line',
      kind: CommandKind.form,
      origin: CommandOrigin.signature,
      effort: 1,
      text: 'Gain 3 Flap and 2 momentum.',
      icon: Sprites.herb(14),
      effect: (api) {
        api.status(Status.flap, 3);
        api.gainMomentum(2);
      },
    ),
    Command(
      id: 'switchback',
      name: 'Switchback',
      kind: CommandKind.skill,
      origin: CommandOrigin.signature,
      effort: 1,
      needsLane: true,
      text: 'Change lane, gain 3 momentum and cover 4 ground.',
      icon: Sprites.tack(11),
      effect: (api) {
        api.changeLane();
        api.gainMomentum(3);
        api.move(bonus: -api.actor.effectiveStride + 4, staminaCost: 0);
      },
    ),

    // --------------------------------------------------------------- synergy
    Command(
      id: 'thunder_hop',
      name: 'Thunder Hop',
      kind: CommandKind.move,
      origin: CommandOrigin.synergy,
      effort: 3,
      text: 'Move at stride plus three times your momentum, for 14 stamina.',
      icon: Sprites.herb(30),
      effect: (api) => api.move(extra: api.momentum * 3, staminaCost: 14),
    ),
    Command(
      id: 'perpetual',
      name: 'Perpetual Motion',
      kind: CommandKind.skill,
      origin: CommandOrigin.synergy,
      effort: 0,
      text: 'Free. Gain 2 effort and recover 10 stamina.',
      icon: Sprites.tack(3),
      effect: (api) {
        api.gainEffort(2);
        api.recover(10);
      },
    ),
    Command(
      id: 'kaleidoscope',
      name: 'Kaleidoscope',
      kind: CommandKind.skill,
      origin: CommandOrigin.synergy,
      effort: 1,
      text: 'Draw 4 and gain 2 effort.',
      icon: Sprites.plume(2),
      effect: (api) {
        api.draw(4);
        api.gainEffort(2);
      },
    ),
    Command(
      id: 'pivot_master',
      name: 'Pivot Master',
      kind: CommandKind.move,
      origin: CommandOrigin.synergy,
      effort: 1,
      needsLane: true,
      text:
          'Change lane free, move at stride +3 for 4 stamina, gain 2 momentum.',
      icon: Sprites.tack(15),
      effect: (api) {
        api.changeLane();
        api.move(bonus: 3, staminaCost: 4);
        api.gainMomentum(2);
      },
    ),
    Command(
      id: 'diesel',
      name: 'Diesel',
      kind: CommandKind.form,
      origin: CommandOrigin.synergy,
      effort: 1,
      text: 'Gain 5 Composure and recover 15 stamina.',
      icon: Sprites.remedy(0),
      effect: (api) {
        api.status(Status.composure, 5);
        api.recover(15);
      },
    ),
    Command(
      id: 'all_weather',
      name: 'All Weather',
      kind: CommandKind.form,
      origin: CommandOrigin.synergy,
      effort: 1,
      text: 'Gain 4 Flap and 2 Guard. Terrain stops mattering for a while.',
      icon: Sprites.tack(26),
      effect: (api) {
        api.status(Status.flap, 4);
        api.status(Status.guard, 2);
      },
    ),
    Command(
      id: 'long_bomb',
      name: 'Long Bomb',
      kind: CommandKind.move,
      origin: CommandOrigin.synergy,
      effort: 3,
      text: 'Move at stride +8 for 16 stamina and gain 2 momentum.',
      icon: Sprites.plume(9),
      effect: (api) {
        api.move(bonus: 8, staminaCost: 16);
        api.gainMomentum(2);
      },
    ),
    Command(
      id: 'clockwork',
      name: 'Clockwork',
      kind: CommandKind.skill,
      origin: CommandOrigin.synergy,
      effort: 0,
      text: 'Free. Recover twice your recovery and draw 2.',
      icon: Sprites.trainer(13),
      effect: (api) {
        api.recover(api.actor.phenotype.recovery * 2);
        api.draw(2);
      },
    ),
    Command(
      id: 'sleight',
      name: 'Sleight',
      kind: CommandKind.skill,
      origin: CommandOrigin.synergy,
      effort: 0,
      needsLane: true,
      text: 'Free. Change lane, draw 2 and gain 2 momentum.',
      icon: Sprites.tack(35),
      effect: (api) {
        api.changeLane();
        api.draw(2);
        api.gainMomentum(2);
      },
    ),
    Command(
      id: 'runaway',
      name: 'Runaway',
      kind: CommandKind.move,
      origin: CommandOrigin.synergy,
      effort: 2,
      text: 'Move at stride +6 for 12 stamina and gain 3 momentum.',
      icon: Sprites.herb(25),
      effect: (api) {
        api.move(bonus: 6, staminaCost: 12);
        api.gainMomentum(3);
      },
    ),
    Command(
      id: 'showstopper',
      name: 'Showstopper',
      kind: CommandKind.skill,
      origin: CommandOrigin.synergy,
      effort: 1,
      text: 'Gain 3 Frenzy, 1 effort and recover 12 stamina.',
      icon: Sprites.trophy(13),
      effect: (api) {
        api.status(Status.frenzy, 3);
        api.gainEffort(1);
        api.recover(12);
      },
    ),
    Command(
      id: 'freight',
      name: 'Freight',
      kind: CommandKind.move,
      origin: CommandOrigin.synergy,
      effort: 2,
      text: 'Move at stride +5 for 9 stamina. Gain 3 Guard and 2 Holding.',
      icon: Sprites.trainer(9),
      effect: (api) {
        api.move(bonus: 5, staminaCost: 9);
        api.status(Status.guard, 3);
        api.status(Status.hold, 2);
      },
    ),
  ];
}
