import 'package:flutter/material.dart';

import '../core/palette.dart';

/// Race statuses. Everything temporary that happens to a bird during a race is
/// one of these, so the HUD only ever has one kind of thing to display.
enum Status {
  frenzy,
  ruffled,
  winded,
  composure,
  hold,
  slipstream,
  clipped,
  guard,
  focus,
  secondWind,
  flap,
}

extension StatusInfo on Status {
  String get label => switch (this) {
    Status.frenzy => 'Frenzy',
    Status.ruffled => 'Ruffled',
    Status.winded => 'Winded',
    Status.composure => 'Composure',
    Status.hold => 'Holding',
    Status.slipstream => 'Slipstream',
    Status.clipped => 'Clipped',
    Status.guard => 'Guard',
    Status.focus => 'Focus',
    Status.secondWind => 'Second Wind',
    Status.flap => 'Flap',
  };

  String get blurb => switch (this) {
    Status.frenzy => 'Each stack adds 1 ground to every Move.',
    Status.ruffled => 'Each stack removes 1 ground from every Move.',
    Status.winded => 'Moves cost 1 extra stamina per stack.',
    Status.composure => 'Absorbs 1 corner stamina burn per stack.',
    Status.hold => 'Rivals cannot pass through your lane this turn.',
    Status.slipstream => 'Next Move costs half stamina.',
    Status.clipped => 'Cannot change lane while this lasts.',
    Status.guard => 'Absorbs 1 interference effect per stack.',
    Status.focus => 'Draw 1 extra command per stack next turn.',
    Status.secondWind => 'On going Blown, restore this much stamina once.',
    Status.flap => 'Clears the next hay bales without losing ground.',
  };

  bool get isGood => switch (this) {
    Status.ruffled || Status.winded || Status.clipped => false,
    _ => true,
  };

  /// Statuses that tick down by one at the end of each turn.
  bool get decays => switch (this) {
    Status.secondWind || Status.flap || Status.slipstream => false,
    _ => true,
  };

  Color get tint => isGood ? Palette.stamina : Palette.bad;

  IconData get icon => switch (this) {
    Status.frenzy => Icons.local_fire_department,
    Status.ruffled => Icons.air,
    Status.winded => Icons.sick,
    Status.composure => Icons.self_improvement,
    Status.hold => Icons.block,
    Status.slipstream => Icons.fast_forward,
    Status.clipped => Icons.link_off,
    Status.guard => Icons.shield,
    Status.focus => Icons.visibility,
    Status.secondWind => Icons.favorite,
    Status.flap => Icons.flight_takeoff,
  };
}
