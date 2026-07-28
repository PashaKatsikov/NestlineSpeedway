import '../core/sprites.dart';
import '../genetics/genome.dart';
import 'status.dart';

/// What a rival is about to do. Always shown to the player one turn ahead, so a
/// race is a readable puzzle rather than a dice roll.
enum IntentKind { surge, cruise, draft, steady, block, cut, clip }

extension IntentInfo on IntentKind {
  String get label => switch (this) {
    IntentKind.surge => 'Surge',
    IntentKind.cruise => 'Cruise',
    IntentKind.draft => 'Draft',
    IntentKind.steady => 'Steady',
    IntentKind.block => 'Block',
    IntentKind.cut => 'Cut',
    IntentKind.clip => 'Clip',
  };
}

class Intent {
  const Intent(this.kind, {this.magnitude = 0, this.targetLane});

  final IntentKind kind;
  final int magnitude;
  final int? targetLane;

  String describe() => switch (kind) {
    IntentKind.surge => 'Surge $magnitude',
    IntentKind.cruise => 'Cruise $magnitude',
    IntentKind.draft => 'Draft',
    IntentKind.steady => 'Recover',
    IntentKind.block => 'Hold line',
    IntentKind.cut => 'Cut to lane ${(targetLane ?? 0) + 1}',
    IntentKind.clip => 'Clip you',
  };
}

/// A bird on the track. Covers the player's racer and every rival — the engine
/// treats them identically, only the decision source differs.
class Entrant {
  Entrant({
    required this.id,
    required this.name,
    required this.phenotype,
    required this.plume,
    required this.lane,
    required this.isPlayer,
    this.archetypeId,
    this.title,
  }) : staminaMax = phenotype.staminaMax,
       stamina = phenotype.staminaMax,
       effortMax = phenotype.effort;

  final String id;
  final String name;
  final Phenotype phenotype;
  final int plume;
  final bool isPlayer;

  /// Rival archetype id, null for the player.
  final String? archetypeId;

  /// Champion title shown under the name, if any.
  final String? title;

  int lane;
  double distance = 0;

  int stamina;
  final int staminaMax;
  int momentum = 0;

  int effort = 0;
  final int effortMax;

  final Map<Status, int> statuses = {};

  Intent? intent;

  bool finished = false;
  int placement = 0;

  /// Ground covered last turn, used for the trail effect in the HUD.
  double lastGain = 0;

  bool get blown => stamina <= 0;

  int status(Status s) => statuses[s] ?? 0;

  void addStatus(Status s, int stacks) {
    if (stacks <= 0) return;
    statuses[s] = status(s) + stacks;
  }

  void clearStatus(Status s) => statuses.remove(s);

  void spendStatus(Status s, [int amount = 1]) {
    final cur = status(s);
    if (cur <= amount) {
      statuses.remove(s);
    } else {
      statuses[s] = cur - amount;
    }
  }

  void tickStatuses() {
    for (final s in statuses.keys.toList()) {
      if (!s.decays) continue;
      final v = statuses[s]! - 1;
      if (v <= 0) {
        statuses.remove(s);
      } else {
        statuses[s] = v;
      }
    }
  }

  /// Stride after statuses. Momentum and terrain are applied by the engine.
  int get effectiveStride {
    final base =
        phenotype.stride + status(Status.frenzy) - status(Status.ruffled);
    return base.clamp(0, 20);
  }

  int get control => phenotype.control;
  int get grip => phenotype.grip;

  void spendStamina(int amount) {
    if (amount <= 0) {
      stamina = (stamina - amount).clamp(0, staminaMax);
      return;
    }
    stamina -= amount;
    if (stamina <= 0) {
      final wind = status(Status.secondWind);
      if (wind > 0) {
        clearStatus(Status.secondWind);
        stamina = wind;
      } else {
        stamina = 0;
      }
    }
  }

  void recover(int amount) {
    stamina = (stamina + amount).clamp(0, staminaMax);
  }

  /// Portrait pose driven by race condition.
  int get pose {
    if (finished) return placement == 1 ? Sprites.poseWin : Sprites.poseCheer;
    if (blown) return Sprites.poseSpent;
    if (status(Status.ruffled) > 0) return Sprites.poseHurt;
    if (momentum >= 3) return Sprites.poseSprint;
    return Sprites.poseIdle;
  }
}
