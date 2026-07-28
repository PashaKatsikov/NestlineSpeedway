import 'package:flutter/foundation.dart';

import '../audio/audio_service.dart';
import '../core/rng.dart';
import '../core/sfx.dart';
import '../genetics/genome.dart';
import '../genetics/hatchery.dart';
import '../genetics/locus.dart';
import '../genetics/racer.dart';
import '../meta/save.dart';
import '../meta/stable.dart';
import '../meta/upgrades.dart';
import '../race/command_library.dart';
import '../race/entrant.dart';
import '../race/race_engine.dart';
import '../race/rival.dart';
import '../race/track.dart';
import '../season/encounters.dart';
import '../season/items.dart';
import '../season/season_map.dart';
import '../season/season_state.dart';
import '../tutorial/lesson.dart';

/// The single source of truth the UI listens to. It owns the stable, the season
/// in progress and the live race, and it is the only place that mutates them.
class Game extends ChangeNotifier {
  Game();

  final Stable stable = Stable();
  final SaveService _save = SaveService.instance;

  SeasonState? season;
  RaceEngine? engine;

  /// Node currently being resolved, so a screen can be rebuilt after a reload.
  SeasonNode? activeNode;

  EventPayout? lastPayout;
  List<StockLine>? traderStock;
  List<TrainingOption>? trainingOffer;

  bool ready = false;
  bool sfxOn = true;
  bool musicOn = true;

  /// Set when the last action produced something worth surfacing in the UI.
  String? notice;

  // ------------------------------------------------------------------ startup

  Future<void> boot() async {
    sfxOn = await _save.readBool('sfx', true);
    musicOn = await _save.readBool('music', true);
    AudioService.instance.enabled = sfxOn;

    final data = await _save.read();
    if (data != null) {
      stable.loadJson(Map<String, dynamic>.from(data['stable'] as Map));
      final rawSeason = data['season'];
      if (rawSeason is Map) {
        season = SeasonState.fromJson(Map<String, dynamic>.from(rawSeason));
        final pending = season!.pendingNodeId;
        if (pending != null) activeNode = season!.map.byId(pending);
      }
    }
    if (stable.racers.isEmpty) {
      stable.bootstrap(Rng(Rng.newSeed()));
    }
    ready = true;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() => _save.write({
    'stable': stable.toJson(),
    if (season != null && !season!.over) 'season': season!.toJson(),
  });

  void _sfx(String asset, {double volume = 1}) {
    if (!sfxOn) return;
    AudioService.instance.play(asset, volume: volume);
  }

  void setSfx(bool value) {
    sfxOn = value;
    AudioService.instance.enabled = value;
    _save.writeBool('sfx', value);
    notifyListeners();
  }

  void setMusic(bool value) {
    musicOn = value;
    _save.writeBool('music', value);
    if (value) {
      AudioService.instance.resumeMusic();
    } else {
      AudioService.instance.pauseMusic();
    }
    notifyListeners();
  }

  void clearNotice() {
    if (notice == null) return;
    notice = null;
    notifyListeners();
  }

  // ----------------------------------------------------------------- tutorial

  bool get needsIntro => !stable.introSeen;

  void completeIntro() {
    if (stable.introSeen) return;
    stable.introSeen = true;
    notifyListeners();
    _persist();
  }

  bool needsLesson(Lesson lesson) => !stable.lessonsSeen.contains(lesson.name);

  /// Marks [lesson] as taught.
  ///
  /// Deliberately does not notify: the overlay dismisses itself, and rebuilding
  /// the screen underneath it mid-animation only causes a flicker. The flag is
  /// read again the next time the screen is built.
  void completeLesson(Lesson lesson) {
    if (!stable.lessonsSeen.add(lesson.name)) return;
    _persist();
  }

  /// Re-arms the opening and every coach mark, offered in Settings.
  void replayTutorial() {
    stable.introSeen = false;
    stable.lessonsSeen.clear();
    notifyListeners();
    _persist();
  }

  // ------------------------------------------------------------------- season

  bool get seasonActive => season != null && !season!.over;

  Racer? get activeRacer => stable.byId(season?.activeId);

  List<Racer> get roster {
    final s = season;
    if (s == null) return const [];
    return s.rosterIds
        .map(stable.byId)
        .whereType<Racer>()
        .toList(growable: false);
  }

  List<Racer> get availableRoster =>
      roster.where((r) => !r.careerOver).toList(growable: false);

  bool canStartSeason(List<String> ids) =>
      ids.isNotEmpty && ids.length <= stable.rosterSlots;

  void startSeason(List<String> racerIds) {
    if (!canStartSeason(racerIds)) return;
    final seed = Rng.newSeed();
    final rng = Rng(seed);
    final map = SeasonMap.generate(rng, rows: 12, grade: stable.grade);

    final state = SeasonState(
      seed: seed,
      grade: stable.grade,
      map: map,
      rosterIds: List<String>.of(racerIds),
      activeId: racerIds.first,
      grain: stable.startingGrain,
    );

    // The Feed Kitchen packs a couple of bags before you leave.
    final feeds = Consumable.ofKind(ConsumableKind.feed);
    for (var i = 0; i < stable.startingFeed; i++) {
      state.addConsumable(feeds[i % feeds.length].id);
    }

    season = state;
    activeNode = null;
    lastPayout = null;
    engine = null;
    stable.seasonsRun++;
    _sfx(Sfx.objective);
    notifyListeners();
    _persist();
  }

  void setActiveRacer(String id) {
    final s = season;
    if (s == null || !s.rosterIds.contains(id)) return;
    final racer = stable.byId(id);
    if (racer == null || racer.careerOver) return;
    s.activeId = id;
    _sfx(Sfx.tap, volume: 0.6);
    notifyListeners();
    _persist();
  }

  /// Moves to [node] and prepares whatever that node needs.
  void travelTo(SeasonNode node) {
    final s = season;
    if (s == null || s.over) return;
    if (!s.available.any((n) => n.id == node.id)) return;

    s.arriveAt(node);
    activeNode = node;
    lastPayout = null;
    traderStock = null;
    trainingOffer = null;

    switch (node.kind) {
      case NodeKind.trader:
        traderStock = Trader.stock(
          seed: s.seed ^ (node.id * 7919),
          grade: s.grade,
          priceMultiplier: stable.traderMultiplier,
        );
      case NodeKind.training:
        trainingOffer = TrainingOption.offer(
          seed: s.seed ^ (node.id * 104729),
          bonus: stable.trainingBonus,
        );
      case NodeKind.rest:
        break;
      default:
        break;
    }

    stable.codex.venues.add(node.venueId);
    _sfx(Sfx.tap, volume: 0.7);
    notifyListeners();
    _persist();
  }

  // --------------------------------------------------------------------- race

  /// Builds the race for [node] and hands control to the race screen.
  void startRace(SeasonNode node) {
    final s = season;
    final racer = activeRacer;
    if (s == null || racer == null || racer.careerOver) return;

    final rng = Rng(s.seed ^ (node.id * 31337) ^ (s.racesRun * 17));
    final track = Track.generate(
      node.venue,
      rng,
      laps: node.kind.laps,
      grade: s.grade,
    );

    final bonus = s.bonusFor(racer.id);
    final pheno = racer.phenotype(extra: bonus);
    final tackCommands = s.tackCommands(racer.id);
    final commands = <String>[...pheno.commandIds, ...tackCommands];

    final player = Entrant(
      id: racer.id,
      name: racer.name,
      phenotype: Phenotype(
        staminaMax: pheno.staminaMax + s.startingStaminaBonus(),
        stride: pheno.stride,
        effort: pheno.effort,
        grip: pheno.grip,
        control: pheno.control,
        recovery: pheno.recovery,
        hand: pheno.hand,
        momentumGain: pheno.momentumGain,
        commandIds: commands,
        expressedTraits: pheno.expressedTraits,
        pureTraits: pheno.pureTraits,
        synergies: pheno.synergies,
      ),
      plume: racer.plume,
      lane: 1,
      isPlayer: true,
    );

    for (final entry in s.startingStatuses(racer.id).entries) {
      player.addStatus(entry.key, entry.value);
    }

    final isDuel = node.kind == NodeKind.duel;
    final isFinale = node.kind == NodeKind.grandPrix;
    final fieldSize = isDuel ? 1 : node.venue.fieldSize - 1;

    final rivals = RivalFactory.field(
      count: fieldSize.clamp(1, 6),
      grade: s.grade,
      playerRating: pheno.rating,
      rng: rng,
      champion: isFinale ? Champion.forVenue(node.venueId) : null,
    );

    for (final command in commands) {
      stable.codex.commands.add(command);
    }
    for (final rival in rivals) {
      if (rival.archetypeId != null) {
        stable.codex.rivals.add(rival.archetypeId!);
      }
    }

    engine = RaceEngine(track: track, player: player, rivals: rivals, rng: rng);
    activeNode = node;
    notifyListeners();
  }

  bool playCommand(int handIndex, {int? lane}) {
    final e = engine;
    if (e == null) return false;
    final id = handIndex < e.hand.length ? e.hand[handIndex] : null;
    final ok = e.play(handIndex, lane: lane);
    if (!ok) {
      _sfx(Sfx.denied, volume: 0.6);
    } else {
      final command = id == null ? null : Commands.byId(id);
      _sfx(
        command != null && command.kind.name == 'move' ? Sfx.surge : Sfx.tap,
        volume: 0.7,
      );
      if (e.player.blown) _sfx(Sfx.blown, volume: 0.5);
    }
    notifyListeners();
    return ok;
  }

  void endTurn() {
    final e = engine;
    if (e == null) return;
    e.endTurn();
    if (e.phase == RacePhase.finished) {
      _settleRace();
    }
    notifyListeners();
  }

  /// Applies the race result to the bird, the purse and the egg bank.
  void _settleRace() {
    final e = engine;
    final s = season;
    final node = activeNode;
    final racer = activeRacer;
    if (e == null || s == null || node == null || racer == null) return;

    final result = e.result;
    final rng = Rng(s.seed ^ (node.id * 613) ^ result.turns);

    // Purse scales with placement, event type, grade and sponsors.
    final placementFactor = switch (result.placement) {
      1 => 1.0,
      2 => 0.6,
      3 => 0.4,
      _ => 0.2,
    };
    final grain =
        (node.kind.purse *
                placementFactor *
                (1 + s.grade * 0.12) *
                stable.purseMultiplier)
            .round();
    s.earn(grain);

    // Eggs: winning pays a better shell, and the finale pays best of all.
    var eggTier = -1;
    if (result.placement <= 3) {
      final base = switch (result.placement) {
        1 => 2,
        2 => 1,
        _ => 0,
      };
      final finaleBonus = node.kind == NodeKind.grandPrix ? 2 : 0;
      eggTier = (base + finaleBonus + (s.grade ~/ 3)).clamp(0, 6);
      s.bankEgg(eggTier);
    }

    // Experience, weighted by how hard the event was rather than the result.
    final baseXp = switch (node.kind) {
      NodeKind.sprint => 30,
      NodeKind.endurance => 55,
      NodeKind.steeplechase => 50,
      NodeKind.duel => 70,
      NodeKind.grandPrix => 110,
      _ => 20,
    };
    final xp =
        (baseXp *
                (result.placement == 1
                    ? 1.4
                    : result.podium
                    ? 1.15
                    : 0.9) *
                stable.xpMultiplier)
            .round();
    final rankBefore = racer.rank;
    racer.xp += xp;
    if (racer.rank > rankBefore) _sfx(Sfx.rankUp);

    // Fatigue from distance and from running on empty.
    final fatigue = (10 + result.turns ~/ 3 + result.blownTurns * 4).clamp(
      5,
      60,
    );
    racer.fatigue = (racer.fatigue + fatigue).clamp(0, 100);

    racer.races++;
    stable.totalRaces++;
    if (result.won) {
      racer.wins++;
      stable.totalWins++;
      s.racesWon++;
    }
    if (result.podium) racer.podiums++;
    s.racesRun++;

    // Injury risk: running blown is what actually hurts a bird.
    String? injuryId;
    final risk =
        0.04 +
        result.blownTurns * 0.035 +
        (racer.fatigue > 70 ? 0.12 : 0) +
        s.grade * 0.01;
    if (rng.chance(risk.clamp(0, 0.6))) {
      var severity = result.blownTurns > 4
          ? 3
          : (result.blownTurns > 1 ? 2 : 1);
      severity = (severity - stable.injuryGuard).clamp(1, 3);
      final injury = Injury.roll(rng, severity);
      racer.injuries.add(injury.id);
      injuryId = injury.id;
      _sfx(Sfx.hurt, volume: 0.7);
    }

    // Duels and the finale hand over tack.
    String? tackId;
    if (result.podium &&
        (node.kind == NodeKind.duel || node.kind == NodeKind.grandPrix)) {
      final grade = node.kind == NodeKind.grandPrix ? 2 : 1;
      final pool = Tack.ofGrade(
        grade,
      ).where((t) => !s.tackOwned.contains(t.id)).toList(growable: false);
      if (pool.isNotEmpty) {
        final pick = rng.pick(pool);
        s.tackOwned.add(pick.id);
        stable.codex.tack.add(pick.id);
        tackId = pick.id;
      }
    }

    if (node.kind == NodeKind.grandPrix) {
      final champion = Champion.forVenue(node.venueId);
      if (result.won) {
        stable.codex.champions.add(champion.id);
        stable.seasonsWon++;
        s.won = true;
        _sfx(Sfx.victory);
      }
      s.over = true;
    }

    s.clearPrimed();
    s.resolvePending();

    lastPayout = EventPayout(
      placement: result.placement,
      fieldSize: result.fieldSize,
      grain: grain,
      eggTier: eggTier,
      xp: xp,
      fatigue: fatigue,
      tackId: tackId,
      injuryId: injuryId,
    );

    if (racer.careerOver) {
      notice = '${racer.name} is retired by injury.';
    }
    if (availableRoster.isEmpty) {
      s.over = true;
    }

    _persist();
  }

  /// Leaves the results screen. Closes the season when it is done.
  void acknowledgeResult() {
    engine = null;
    lastPayout = null;
    final s = season;
    if (s != null && s.over) {
      closeSeason();
    } else {
      notifyListeners();
      _persist();
    }
  }

  void abandonRace() {
    engine = null;
    notifyListeners();
  }

  // ---------------------------------------------------------- season closing

  void closeSeason() {
    final s = season;
    if (s == null) return;
    for (var tier = 0; tier < s.eggsWon.length; tier++) {
      if (s.eggsWon[tier] > 0) stable.addEgg(tier, s.eggsWon[tier]);
    }
    if (s.won && stable.grade == s.grade) {
      stable.grade = (s.grade + 1).clamp(0, 10);
      if (stable.grade > stable.highestGrade) {
        stable.highestGrade = stable.grade;
      }
    }
    // Birds recover between seasons, but not completely.
    for (final racer in stable.racers) {
      racer.fatigue = (racer.fatigue - 45).clamp(0, 100);
    }
    if (stable.needsClaimClutch) {
      stable.grantClaimClutch(Rng(Rng.newSeed()));
      notice = 'Nestline grants a claim clutch to keep the stable running.';
    }
    season = null;
    activeNode = null;
    engine = null;
    lastPayout = null;
    _sfx(Sfx.egg);
    notifyListeners();
    _persist();
  }

  void retireSeasonEarly() {
    final s = season;
    if (s == null) return;
    s.over = true;
    closeSeason();
  }

  // ------------------------------------------------------------------ trader

  bool buy(StockLine line) {
    final s = season;
    if (s == null || line.sold) return false;
    if (!s.spend(line.price)) {
      _sfx(Sfx.denied, volume: 0.6);
      notice = 'Not enough grain.';
      notifyListeners();
      return false;
    }

    switch (line.kind) {
      case StockKind.tack:
        final id = line.tackId!;
        s.tackOwned.add(id);
        stable.codex.tack.add(id);
      case StockKind.consumable:
        s.addConsumable(line.consumableId!);
      case StockKind.geneRead:
        final racer = activeRacer;
        final locus = line.locus;
        if (racer != null && locus != null) {
          final learned = stable.codex.reveal(racer.genome, locus);
          notice = learned == null
              ? '${racer.name} carries nothing hidden at ${locus.label}.'
              : '${racer.name} carries $learned at ${locus.label}.';
        }
    }
    line.sold = true;
    _sfx(Sfx.trade);
    notifyListeners();
    _persist();
    return true;
  }

  // ---------------------------------------------------------------- training

  void train(TrainingOption option) {
    final s = season;
    final racer = activeRacer;
    if (s == null || racer == null) return;

    racer.xp += (option.xp * stable.xpMultiplier).round();
    racer.fatigue = (racer.fatigue + option.fatigue - option.fatigueRelief)
        .clamp(0, 100);

    if (option.kind == TrainingKind.geneRead && option.locus != null) {
      final learned = stable.codex.reveal(racer.genome, option.locus!);
      notice = learned == null
          ? '${racer.name} carries nothing hidden at ${option.locus!.label}.'
          : '${racer.name} carries $learned at ${option.locus!.label}.';
    }

    trainingOffer = null;
    s.resolvePending();
    _sfx(Sfx.objective);
    notifyListeners();
    _persist();
  }

  // -------------------------------------------------------------------- rest

  void rest({String? healInjuryId}) {
    final s = season;
    final racer = activeRacer;
    if (s == null || racer == null) return;

    racer.fatigue = (racer.fatigue - (55 + stable.restBonus)).clamp(0, 100);
    if (healInjuryId != null) {
      final injury = Injury.byId(healInjuryId);
      if (!injury.careerEnding) racer.injuries.remove(healInjuryId);
    }
    s.resolvePending();
    _sfx(Sfx.soothe);
    notifyListeners();
    _persist();
  }

  // --------------------------------------------------------------- inventory

  void useConsumable(String id) {
    final s = season;
    final racer = activeRacer;
    if (s == null || racer == null) return;
    final item = Consumable.byId(id);
    if (item == null || !s.takeConsumable(id)) return;

    if (item.kind == ConsumableKind.feed ||
        item.startStatuses.isNotEmpty ||
        item.raceMods.describe() != '—') {
      s.primed.add(id);
    }
    if (item.fatigueRelief > 0) {
      racer.fatigue = (racer.fatigue - item.fatigueRelief).clamp(0, 100);
    }
    if (item.xpGain > 0) racer.xp += item.xpGain;
    if (item.grainGain > 0) s.earn(item.grainGain);
    if (item.healSeverity > 0) {
      final target = racer.injuryList
          .where((i) => i.severity <= item.healSeverity && !i.careerEnding)
          .toList(growable: false);
      if (target.isNotEmpty) racer.injuries.remove(target.first.id);
    }
    _sfx(item.kind == ConsumableKind.feed ? Sfx.feed : Sfx.cleanse);
    notifyListeners();
    _persist();
  }

  void toggleTack(String racerId, String tackId) {
    final s = season;
    if (s == null) return;
    if (s.equippedOn(racerId).contains(tackId)) {
      s.unequip(racerId, tackId);
    } else if (!s.equip(racerId, tackId, stable.tackSlots)) {
      _sfx(Sfx.denied, volume: 0.6);
      notice = 'No free tack slot.';
    }
    _sfx(Sfx.tap, volume: 0.6);
    notifyListeners();
    _persist();
  }

  // ----------------------------------------------------------------- hatchery

  Racer? breed(Racer sire, Racer dam, EggTier tier) {
    if (stable.racers.length >= 12 + stable.hatchSlots * 2) {
      notice = 'The stable is full. Retire a bird first.';
      notifyListeners();
      return null;
    }
    final chick = stable.breed(sire, dam, tier, Rng(Rng.newSeed()));
    if (chick == null) {
      _sfx(Sfx.denied, volume: 0.6);
      notice = 'You need a ${tier.name} egg for that pairing.';
      notifyListeners();
      return null;
    }
    _sfx(chick.genome.pureLoci.length >= 2 ? Sfx.rareHatch : Sfx.hatch);
    notice = '${chick.name} has hatched.';
    notifyListeners();
    _persist();
    return chick;
  }

  bool buildUpgrade(StableUpgrade upgrade) {
    final ok = stable.build(upgrade);
    _sfx(ok ? Sfx.build : Sfx.denied, volume: ok ? 1 : 0.6);
    if (!ok) {
      notice =
          'You need ${upgrade.costCount} '
          '${EggTier.at(upgrade.costTier).name} eggs or better.';
    }
    notifyListeners();
    _persist();
    return ok;
  }

  void renameRacer(Racer racer, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    racer.name = trimmed.length > 18 ? trimmed.substring(0, 18) : trimmed;
    notifyListeners();
    _persist();
  }

  void retireRacer(Racer racer) {
    stable.retire(racer);
    if (stable.needsClaimClutch) {
      stable.grantClaimClutch(Rng(Rng.newSeed()));
    }
    _sfx(Sfx.tap, volume: 0.6);
    notifyListeners();
    _persist();
  }

  /// Full wipe, offered in Settings.
  Future<void> resetEverything() async {
    await _save.wipe();
    season = null;
    engine = null;
    activeNode = null;
    lastPayout = null;
    stable.loadJson(const {});
    stable.racers.clear();
    stable.bootstrap(Rng(Rng.newSeed()));
    notice = 'A new stable has been founded.';
    notifyListeners();
    _persist();
  }

  // ------------------------------------------------------------------ helpers

  /// Phenotype the active racer would take to the line right now.
  Phenotype? get activePhenotype {
    final racer = activeRacer;
    final s = season;
    if (racer == null) return null;
    return racer.phenotype(extra: s?.bonusFor(racer.id) ?? const StatMods());
  }

  /// Whether the player knows the hidden allele at [l] for [racer].
  bool knowsHidden(Racer racer, Locus l) {
    final hidden = racer.genome.hidden(l);
    if (hidden == null) return true;
    return stable.codex.knowsAllele(l, hidden.index);
  }
}
