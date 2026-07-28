import 'dart:math';

import '../core/rng.dart';
import 'command.dart';
import 'command_library.dart';
import 'entrant.dart';
import 'rival.dart';
import 'status.dart';
import 'track.dart';

enum LogTone { neutral, good, bad, rival, terrain }

class LogLine {
  LogLine(this.text, this.tone, this.turn);
  final String text;
  final LogTone tone;
  final int turn;
}

enum RacePhase { racing, finished }

/// Result of one racer's race, handed to the season layer.
class RaceResult {
  RaceResult({
    required this.placement,
    required this.fieldSize,
    required this.turns,
    required this.finalStamina,
    required this.staminaMax,
    required this.blownTurns,
    required this.playerDistance,
    required this.trackLength,
  });

  final int placement;
  final int fieldSize;
  final int turns;
  final int finalStamina;
  final int staminaMax;

  /// Turns spent at zero stamina. Drives injury risk.
  final int blownTurns;

  final double playerDistance;
  final int trackLength;

  bool get won => placement == 1;
  bool get podium => placement <= 3;
  bool get finishedRace => playerDistance >= trackLength;
}

/// The race. Turn-based, fully deterministic given the seed, and the only place
/// in the game where commands actually execute.
class RaceEngine implements RaceApi {
  RaceEngine({
    required this.track,
    required Entrant player,
    required List<Entrant> rivals,
    required this.rng,
    this.laneCount = 3,
  }) : _player = player,
       entrants = [player, ...rivals] {
    _placeField();
    _buildDeck();
    beginTurn();
  }

  static const int maxTurns = 60;
  static const int momentumCap = 6;

  /// How close behind a rival you must be, in ground units, to draft.
  static const double draftWindow = 6;

  @override
  final Track track;

  @override
  final Rng rng;

  final int laneCount;

  final Entrant _player;
  final List<Entrant> entrants;

  int turn = 1;
  int effort = 0;
  RacePhase phase = RacePhase.racing;

  final List<String> deck = [];
  final List<String> hand = [];
  final List<String> discard = [];
  final List<String> exhausted = [];

  final List<LogLine> log_ = [];

  int _blownTurns = 0;
  int _nextPlacement = 1;

  /// Set while a command resolves so [changeLane] knows the player's pick.
  int? _pendingLane;

  Entrant get player => _player;

  List<Entrant> get rivals =>
      entrants.where((e) => !e.isPlayer).toList(growable: false);

  // ------------------------------------------------------------------- setup

  /// Lays out the starting grid. Rivals fill the remaining slots row by row, so
  /// nobody shares a square with anybody and drafting is live from turn one.
  void _placeField() {
    _player.lane = _player.lane.clamp(0, laneCount - 1);
    _player.distance = 0;

    var slot = 0;
    for (final e in rivals) {
      while (true) {
        final lane = slot % laneCount;
        final row = slot ~/ laneCount;
        slot++;
        if (lane == _player.lane && row == 0) continue;
        e.lane = lane;
        e.distance = -row * 3.0;
        break;
      }
    }
  }

  void _buildDeck() {
    deck
      ..clear()
      ..addAll(_player.phenotype.commandIds);
    rng.shuffle(deck);
  }

  // -------------------------------------------------------------- turn cycle

  void beginTurn() {
    if (phase == RacePhase.finished) return;

    effort = _player.effortMax + (_player.blown ? -1 : 0);
    if (effort < 1) effort = 1;

    final focus = _player.status(Status.focus);
    final target = _player.phenotype.hand + focus;
    _drawTo(target);
    if (focus > 0) _player.clearStatus(Status.focus);

    for (final e in rivals) {
      if (e.finished) {
        e.intent = null;
        continue;
      }
      e.intent = Archetype.byId(e.archetypeId ?? 'pacer').plan(
        RivalView(self: e, field: entrants, track: track, turn: turn, rng: rng),
      );
    }
  }

  void endTurn() {
    if (phase == RacePhase.finished) return;

    _resolveRivals();
    _applyTerrain();
    _checkFinishes();

    for (final e in entrants) {
      e.tickStatuses();
      if (e.blown) e.momentum = max(0, e.momentum - 1);
    }
    if (_player.blown) _blownTurns++;

    // Discard the rest of the hand; commands are not held between turns.
    discard.addAll(hand);
    hand.clear();

    turn++;
    if (turn > maxTurns) {
      _finish();
      return;
    }
    if (phase == RacePhase.racing) beginTurn();
  }

  // ------------------------------------------------------------ player input

  /// Whether the player can currently afford and legally play [handIndex].
  bool canPlay(int handIndex) {
    if (phase != RacePhase.racing) return false;
    if (handIndex < 0 || handIndex >= hand.length) return false;
    return Commands.byId(hand[handIndex]).effort <= effort;
  }

  /// Plays a command from the hand. [lane] is required for lane-changing
  /// commands and ignored otherwise.
  bool play(int handIndex, {int? lane}) {
    if (!canPlay(handIndex)) return false;
    final id = hand[handIndex];
    final command = Commands.byId(id);

    effort -= command.effort;
    hand.removeAt(handIndex);
    if (command.exhaust) {
      exhausted.add(id);
    } else {
      discard.add(id);
    }

    _pendingLane = lane;
    _log('${_player.name}: ${command.name}', LogTone.neutral);
    command.effect(this);
    _pendingLane = null;

    _checkFinishes();
    return true;
  }

  // ----------------------------------------------------------------- RaceApi

  @override
  Entrant get actor => _player;

  @override
  List<Entrant> get field => entrants;

  @override
  int? get chosenLane => _pendingLane;

  @override
  int get momentum => _player.momentum;

  @override
  bool get isLeading => leader.id == _player.id;

  @override
  bool get isDrafting => _drafteeFor(_player) != null;

  @override
  Entrant? get rivalAhead => _drafteeFor(_player);

  @override
  Entrant? get rivalAdjacent {
    Entrant? best;
    for (final e in rivals) {
      if (e.finished) continue;
      final gap = (e.distance - _player.distance).abs();
      if (gap > 8) continue;
      if (best == null || gap < (best.distance - _player.distance).abs()) {
        best = e;
      }
    }
    return best;
  }

  @override
  void move({int bonus = 0, int staminaCost = 0, int extra = 0}) {
    final e = _player;
    var ground = e.effectiveStride + bonus + extra + e.momentum;
    if (ground < 0) ground = 0;

    var cost = staminaCost;
    if (cost > 0) {
      cost += e.status(Status.winded);
      cost += _terrainStaminaSurcharge(e);
      if (e.status(Status.slipstream) > 0) {
        cost = (cost / 2).ceil();
        e.spendStatus(Status.slipstream);
      } else if (isDrafting) {
        final saving = track.terrainAt(e.distance) == Terrain.straight ? 2 : 1;
        cost = max(1, cost - (cost ~/ 3) - saving);
      }
      if (cost < 1) cost = 1;
    }

    if (e.blown) ground = (ground / 2).floor();

    _advance(e, ground.toDouble());
    if (cost > 0) e.spendStamina(cost);
    e.momentum = min(momentumCap, e.momentum + 1 + e.phenotype.momentumGain);

    if (e.blown && cost > 0) {
      _log('${e.name} is out of wind.', LogTone.bad);
    }
  }

  @override
  void recover(int amount) {
    if (amount <= 0) return;
    _player.recover(amount);
  }

  @override
  void spendStamina(int amount) => _player.spendStamina(amount);

  @override
  void gainMomentum(int amount) {
    _player.momentum = min(momentumCap, _player.momentum + amount);
  }

  @override
  void status(Status s, int stacks, {Entrant? on}) =>
      (on ?? _player).addStatus(s, stacks);

  @override
  void changeLane([int? lane]) {
    final e = _player;
    if (e.status(Status.clipped) > 0) {
      _log('${e.name} is clipped and cannot switch lanes.', LogTone.bad);
      return;
    }
    var target = lane ?? _pendingLane;
    target ??= _freeLaneNear(e);
    if (target == null || target == e.lane) return;
    target = target.clamp(0, laneCount - 1);
    if (_laneBlocked(e, target)) {
      _log('Lane ${target + 1} is occupied.', LogTone.bad);
      return;
    }
    e.lane = target;
    _log('${e.name} moves to lane ${target + 1}.', LogTone.neutral);
  }

  @override
  void draw(int count) => _drawTo(hand.length + count);

  @override
  void gainEffort(int count) => effort += count;

  @override
  void clearNegative(int count) {
    var left = count;
    for (final s in _player.statuses.keys.toList()) {
      if (left <= 0) break;
      if (s.isGood) continue;
      _player.clearStatus(s);
      left--;
    }
  }

  @override
  void log(String message) => _log(message, LogTone.neutral);

  // ----------------------------------------------------------------- helpers

  Entrant get leader =>
      entrants.reduce((a, b) => a.distance >= b.distance ? a : b);

  /// Ordering used everywhere in the UI: furthest along first.
  List<Entrant> get standings {
    final sorted = List<Entrant>.of(entrants);
    sorted.sort((a, b) {
      if (a.finished && b.finished) return a.placement.compareTo(b.placement);
      if (a.finished) return -1;
      if (b.finished) return 1;
      return b.distance.compareTo(a.distance);
    });
    return sorted;
  }

  int get playerPosition => standings.indexWhere((e) => e.id == _player.id) + 1;

  Entrant? _drafteeFor(Entrant e) {
    Entrant? best;
    for (final other in entrants) {
      if (other.id == e.id || other.lane != e.lane) continue;
      if (other.distance <= e.distance) continue;
      if (best == null || other.distance < best.distance) best = other;
    }
    if (best == null) return null;
    return (best.distance - e.distance) <= draftWindow ? best : null;
  }

  bool _laneBlocked(Entrant e, int lane) {
    for (final other in entrants) {
      if (other.id == e.id || other.finished) continue;
      if (other.lane != lane) continue;
      if ((other.distance - e.distance).abs() <= 2.5) return true;
    }
    return false;
  }

  int? _freeLaneNear(Entrant e) {
    for (final delta in [-1, 1, -2, 2]) {
      final lane = e.lane + delta;
      if (lane < 0 || lane >= laneCount) continue;
      if (!_laneBlocked(e, lane)) return lane;
    }
    return null;
  }

  int _terrainStaminaSurcharge(Entrant e) {
    final terrain = track.terrainAt(e.distance);
    if (terrain == Terrain.mud) return max(0, 2 - e.grip);
    return 0;
  }

  /// Moves [e] forward, respecting anyone holding the line in the same lane.
  void _advance(Entrant e, double ground) {
    if (ground <= 0) {
      e.lastGain = 0;
      return;
    }
    var target = e.distance + ground;

    for (final other in entrants) {
      if (other.id == e.id || other.finished) continue;
      if (other.lane != e.lane) continue;
      if (other.status(Status.hold) <= 0) continue;
      if (other.distance <= e.distance) continue;
      if (target > other.distance - 1) {
        target = other.distance - 1;
        _log('${other.name} holds the line against ${e.name}.', LogTone.rival);
      }
    }

    if (target < e.distance) target = e.distance;
    e.lastGain = target - e.distance;
    e.distance = target;
  }

  void _drawTo(int target) {
    while (hand.length < target) {
      if (deck.isEmpty) {
        if (discard.isEmpty) return;
        deck.addAll(discard);
        discard.clear();
        rng.shuffle(deck);
      }
      hand.add(deck.removeLast());
    }
  }

  // ------------------------------------------------------------ rival phase

  void _resolveRivals() {
    final order = List<Entrant>.of(rivals)
      ..sort((a, b) => b.distance.compareTo(a.distance));

    for (final e in order) {
      if (e.finished) continue;
      final intent = e.intent;
      if (intent == null) continue;

      switch (intent.kind) {
        case IntentKind.surge:
          _rivalMove(e, intent.magnitude, 6 + intent.magnitude);
        case IntentKind.cruise:
          _rivalMove(e, intent.magnitude, 3 + intent.magnitude);
        case IntentKind.draft:
          final ahead = _drafteeFor(e);
          _rivalMove(e, 0, ahead != null ? 2 : 4);
          e.recover(3);
        case IntentKind.steady:
          e.recover(e.phenotype.recovery + 2);
          e.momentum = max(0, e.momentum - 1);
          e.addStatus(Status.composure, 1);
        case IntentKind.block:
          e.addStatus(Status.hold, 1);
          _rivalMove(e, 0, 3);
        case IntentKind.cut:
          _rivalChangeLane(e, intent.targetLane);
          _rivalMove(e, 0, 3);
        case IntentKind.clip:
          _rivalClip(e);
          _rivalMove(e, 0, 3);
      }
    }
  }

  void _rivalMove(Entrant e, int bonus, int staminaCost) {
    var ground = e.effectiveStride + bonus + e.momentum;
    if (e.blown) ground = (ground / 2).floor();

    var cost = staminaCost + e.status(Status.winded);
    if (track.terrainAt(e.distance) == Terrain.mud) {
      cost += max(0, 2 - e.grip);
    }
    if (_drafteeFor(e) != null) {
      cost = max(1, cost - (cost ~/ 3) - 1);
    }

    _advance(e, ground.toDouble());
    e.spendStamina(cost);
    e.momentum = min(momentumCap, e.momentum + 1 + e.phenotype.momentumGain);
  }

  void _rivalChangeLane(Entrant e, int? lane) {
    if (e.status(Status.clipped) > 0) return;
    final target = (lane ?? _freeLaneNear(e))?.clamp(0, laneCount - 1);
    if (target == null || target == e.lane) return;
    if (_laneBlocked(e, target)) return;
    e.lane = target;
  }

  void _rivalClip(Entrant e) {
    final target = _player;
    if (target.finished) return;
    if (target.status(Status.guard) > 0) {
      target.spendStatus(Status.guard);
      _log(
        '${e.name} tries to clip ${target.name}, guard holds.',
        LogTone.good,
      );
      return;
    }
    target.addStatus(Status.ruffled, 1);
    target.momentum = max(0, target.momentum - 2);
    _log('${e.name} clips ${target.name}.', LogTone.bad);
  }

  // ---------------------------------------------------------- terrain phase

  void _applyTerrain() {
    for (final e in entrants) {
      if (e.finished) continue;
      final terrain = track.terrainAt(e.distance);

      switch (terrain) {
        case Terrain.corner:
          final slack = e.control + e.status(Status.composure);
          final burn = e.momentum - slack;
          if (burn > 0) {
            e.spendStamina(burn);
            e.momentum = max(0, slack);
            if (e.isPlayer) {
              _log('The corner burns $burn stamina.', LogTone.terrain);
            }
          }
          if (e.status(Status.composure) > 0) e.spendStatus(Status.composure);
        case Terrain.puddle:
          if (e.grip < 2 && !_consumeFlap(e)) {
            if (e.momentum > 0 && e.isPlayer) {
              _log('The puddle kills your momentum.', LogTone.terrain);
            }
            e.momentum = 0;
          }
        case Terrain.hay:
          if (!_consumeFlap(e) && e.grip < 1) {
            e.distance = max(e.distance - 2, 0);
            if (e.isPlayer) {
              _log('Hay bales cost you 2 ground.', LogTone.terrain);
            }
          }
        case Terrain.gravel:
          if (e.grip < 2 && !_consumeFlap(e)) {
            e.addStatus(Status.ruffled, 1);
          }
        case Terrain.downhill:
          e.distance += 2;
          e.momentum = min(momentumCap, e.momentum + 1);
        case Terrain.crowd:
          if (leader.id == e.id && e.isPlayer) {
            effort += 1;
            _log('The crowd carries you: +1 effort.', LogTone.good);
          } else if (leader.id == e.id) {
            e.recover(2);
          }
        case Terrain.straight:
        case Terrain.mud:
          break;
      }
    }
  }

  bool _consumeFlap(Entrant e) {
    if (e.status(Status.flap) <= 0) return false;
    e.spendStatus(Status.flap);
    return true;
  }

  // -------------------------------------------------------------- finishing

  void _checkFinishes() {
    for (final e in standings) {
      if (e.finished) continue;
      if (e.distance >= track.totalLength) {
        e.finished = true;
        e.placement = _nextPlacement++;
        _log(
          '${e.name} crosses the line in ${_ordinal(e.placement)}.',
          e.isPlayer ? LogTone.good : LogTone.rival,
        );
      }
    }
    if (_player.finished || rivals.every((r) => r.finished)) _finish();
  }

  void _finish() {
    if (phase == RacePhase.finished) return;
    phase = RacePhase.finished;

    // Anyone still running is ranked by ground covered.
    final remaining = entrants.where((e) => !e.finished).toList()
      ..sort((a, b) => b.distance.compareTo(a.distance));
    for (final e in remaining) {
      e.finished = true;
      e.placement = _nextPlacement++;
    }
  }

  RaceResult get result => RaceResult(
    placement: _player.placement == 0 ? entrants.length : _player.placement,
    fieldSize: entrants.length,
    turns: turn,
    finalStamina: _player.stamina,
    staminaMax: _player.staminaMax,
    blownTurns: _blownTurns,
    playerDistance: _player.distance,
    trackLength: track.totalLength,
  );

  void _log(String text, LogTone tone) {
    log_.add(LogLine(text, tone, turn));
    if (log_.length > 120) log_.removeRange(0, log_.length - 120);
  }

  static String _ordinal(int n) => switch (n) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    _ => '${n}th',
  };
}
