import 'package:flutter/material.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/dice.dart';
import 'package:nestline_circuit/heat/contender.dart';
import 'package:nestline_circuit/heat/status.dart';
import 'package:nestline_circuit/heat/track.dart';

/// What the engine exposes to a command's effect. Keeping this an interface lets
/// the command library stay pure data plus closures, with no knowledge of how
/// the engine bookkeeps a turn.
abstract class HeatApi {
  Contender get actor;
  Track get track;
  List<Contender> get field;
  Dice get rng;

  /// Lane the player picked for a lane-changing command, if any.
  int? get chosenLane;

  /// Performs a Move. Ground covered is stride + [bonus] + momentum + [extra],
  /// and the stamina bill is [staminaCost] after terrain and statuses.
  void move({int bonus = 0, int staminaCost = 0, int extra = 0});

  void recover(int amount);
  void spendStamina(int amount);
  void gainMomentum(int amount);
  void status(Status s, int stacks, {Contender? on});
  void changeLane([int? lane]);
  void draw(int count);
  void gainEffort(int count);
  void clearNegative(int count);
  void log(String message);

  Contender? get rivalAhead;
  Contender? get rivalAdjacent;
  bool get isLeading;
  bool get isDrafting;
  int get momentum;
}

enum ManeuverKind { move, guard, skill, form }

extension CommandKindInfo on ManeuverKind {
  String get label => switch (this) {
    ManeuverKind.move => 'Move',
    ManeuverKind.guard => 'Guard',
    ManeuverKind.skill => 'Skill',
    ManeuverKind.form => 'Form',
  };

  Color get tint => switch (this) {
    ManeuverKind.move => Pigment.ember,
    ManeuverKind.guard => Pigment.momentum,
    ManeuverKind.skill => Pigment.stamina,
    ManeuverKind.form => Pigment.schoolRainbow,
  };

  IconData get icon => switch (this) {
    ManeuverKind.move => Icons.double_arrow,
    ManeuverKind.guard => Icons.shield_moon,
    ManeuverKind.skill => Icons.bolt,
    ManeuverKind.form => Icons.auto_awesome,
  };
}

/// Where a command came from. Drives the badge on the card and the Ledger entry.
enum ManeuverOrigin { core, trait, signature, synergy, tack }

extension CommandOriginInfo on ManeuverOrigin {
  String get label => switch (this) {
    ManeuverOrigin.core => 'Core',
    ManeuverOrigin.trait => 'Trait',
    ManeuverOrigin.signature => 'Pure',
    ManeuverOrigin.synergy => 'Pairing',
    ManeuverOrigin.tack => 'Tack',
  };

  Color get tint => switch (this) {
    ManeuverOrigin.core => Pigment.inkMute,
    ManeuverOrigin.trait => Pigment.momentum,
    ManeuverOrigin.signature => Pigment.amber,
    ManeuverOrigin.synergy => Pigment.schoolRainbow,
    ManeuverOrigin.tack => Pigment.stamina,
  };
}

@immutable
class Maneuver {
  const Maneuver({
    required this.id,
    required this.name,
    required this.kind,
    required this.origin,
    required this.effort,
    required this.text,
    required this.icon,
    required this.effect,
    this.needsLane = false,
    this.exhaust = false,
  });

  final String id;
  final String name;
  final ManeuverKind kind;
  final ManeuverOrigin origin;

  /// Effort cost. Stamina cost lives in the effect so it can react to terrain.
  final int effort;

  /// Rules text shown on the card.
  final String text;

  /// Sprite path for the card art.
  final String icon;

  final void Function(HeatApi api) effect;

  /// True when the player must pick a lane before this command resolves.
  final bool needsLane;

  /// Removed from the deck for the rest of the race once played.
  final bool exhaust;
}
