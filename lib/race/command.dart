import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/rng.dart';
import 'entrant.dart';
import 'status.dart';
import 'track.dart';

/// What the engine exposes to a command's effect. Keeping this an interface lets
/// the command library stay pure data plus closures, with no knowledge of how
/// the engine bookkeeps a turn.
abstract class RaceApi {
  Entrant get actor;
  Track get track;
  List<Entrant> get field;
  Rng get rng;

  /// Lane the player picked for a lane-changing command, if any.
  int? get chosenLane;

  /// Performs a Move. Ground covered is stride + [bonus] + momentum + [extra],
  /// and the stamina bill is [staminaCost] after terrain and statuses.
  void move({int bonus = 0, int staminaCost = 0, int extra = 0});

  void recover(int amount);
  void spendStamina(int amount);
  void gainMomentum(int amount);
  void status(Status s, int stacks, {Entrant? on});
  void changeLane([int? lane]);
  void draw(int count);
  void gainEffort(int count);
  void clearNegative(int count);
  void log(String message);

  Entrant? get rivalAhead;
  Entrant? get rivalAdjacent;
  bool get isLeading;
  bool get isDrafting;
  int get momentum;
}

enum CommandKind { move, guard, skill, form }

extension CommandKindInfo on CommandKind {
  String get label => switch (this) {
    CommandKind.move => 'Move',
    CommandKind.guard => 'Guard',
    CommandKind.skill => 'Skill',
    CommandKind.form => 'Form',
  };

  Color get tint => switch (this) {
    CommandKind.move => Palette.ember,
    CommandKind.guard => Palette.momentum,
    CommandKind.skill => Palette.stamina,
    CommandKind.form => Palette.schoolRainbow,
  };

  IconData get icon => switch (this) {
    CommandKind.move => Icons.double_arrow,
    CommandKind.guard => Icons.shield_moon,
    CommandKind.skill => Icons.bolt,
    CommandKind.form => Icons.auto_awesome,
  };
}

/// Where a command came from. Drives the badge on the card and the Codex entry.
enum CommandOrigin { core, trait, signature, synergy, tack }

extension CommandOriginInfo on CommandOrigin {
  String get label => switch (this) {
    CommandOrigin.core => 'Core',
    CommandOrigin.trait => 'Trait',
    CommandOrigin.signature => 'Pure',
    CommandOrigin.synergy => 'Synergy',
    CommandOrigin.tack => 'Tack',
  };

  Color get tint => switch (this) {
    CommandOrigin.core => Palette.inkMute,
    CommandOrigin.trait => Palette.momentum,
    CommandOrigin.signature => Palette.amber,
    CommandOrigin.synergy => Palette.schoolRainbow,
    CommandOrigin.tack => Palette.stamina,
  };
}

@immutable
class Command {
  const Command({
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
  final CommandKind kind;
  final CommandOrigin origin;

  /// Effort cost. Stamina cost lives in the effect so it can react to terrain.
  final int effort;

  /// Rules text shown on the card.
  final String text;

  /// Sprite path for the card art.
  final String icon;

  final void Function(RaceApi api) effect;

  /// True when the player must pick a lane before this command resolves.
  final bool needsLane;

  /// Removed from the deck for the rest of the race once played.
  final bool exhaust;
}
