import '../genetics/locus.dart';
import '../race/status.dart';
import 'items.dart';
import 'season_map.dart';

/// A season in progress. Everything here is discarded when the season ends,
/// except the eggs banked in [eggsWon] and whatever happened to the birds.
class SeasonState {
  SeasonState({
    required this.seed,
    required this.grade,
    required this.map,
    required this.rosterIds,
    required this.activeId,
    required this.grain,
  });

  final int seed;
  final int grade;
  final SeasonMap map;

  /// Stable ids of the birds travelling this season.
  final List<String> rosterIds;

  /// Whichever bird is entered in the next event.
  String activeId;

  int grain;

  /// Tack picked up this season, and what is fitted to whom.
  final List<String> tackOwned = [];
  final Map<String, List<String>> equipped = {};

  /// Consumable id to count.
  final Map<String, int> bag = {};

  /// Feed and supplements queued for the next race only.
  final List<String> primed = [];

  final Set<int> cleared = {};
  final List<int> path = [];

  /// Eggs won this season, by tier, banked when the season closes.
  final List<int> eggsWon = List<int>.filled(7, 0);

  bool over = false;
  bool won = false;

  /// Set when a node has been chosen but not yet resolved.
  int? pendingNodeId;

  int racesRun = 0;
  int racesWon = 0;

  // ---------------------------------------------------------------- schedule

  SeasonNode? get lastNode => path.isEmpty ? null : map.byId(path.last);

  /// Nodes the player may travel to next.
  List<SeasonNode> get available {
    if (path.isEmpty) return map.starts;
    final last = map.byId(path.last);
    return last.next.map(map.byId).toList(growable: false);
  }

  int get row => path.isEmpty ? 0 : map.byId(path.last).row + 1;

  double get progress => (row / map.rows).clamp(0.0, 1.0);

  void arriveAt(SeasonNode node) {
    path.add(node.id);
    cleared.add(node.id);
    pendingNodeId = node.id;
  }

  void resolvePending() => pendingNodeId = null;

  // -------------------------------------------------------------- inventory

  int countOf(String consumableId) => bag[consumableId] ?? 0;

  void addConsumable(String id, [int count = 1]) {
    bag[id] = countOf(id) + count;
  }

  bool takeConsumable(String id) {
    final have = countOf(id);
    if (have <= 0) return false;
    if (have == 1) {
      bag.remove(id);
    } else {
      bag[id] = have - 1;
    }
    return true;
  }

  List<Consumable> get bagContents {
    final out = <Consumable>[];
    for (final entry in bag.entries) {
      final c = Consumable.byId(entry.key);
      if (c != null) out.add(c);
    }
    out.sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return out;
  }

  List<String> equippedOn(String racerId) => equipped[racerId] ?? const [];

  bool equip(String racerId, String tackId, int slots) {
    final list = equipped.putIfAbsent(racerId, () => <String>[]);
    if (list.contains(tackId)) return false;
    if (list.length >= slots) return false;
    if (!tackOwned.contains(tackId)) return false;
    list.add(tackId);
    return true;
  }

  void unequip(String racerId, String tackId) {
    equipped[racerId]?.remove(tackId);
  }

  /// Combined stat bonus from fitted tack plus anything primed for this race.
  StatMods bonusFor(String racerId) {
    var mods = const StatMods();
    for (final id in equippedOn(racerId)) {
      final t = Tack.byId(id);
      if (t != null) mods = mods + t.mods;
    }
    for (final id in primed) {
      final c = Consumable.byId(id);
      if (c != null) mods = mods + c.raceMods;
    }
    return mods;
  }

  /// Statuses applied at the drop of the flag.
  Map<Status, int> startingStatuses(String racerId) {
    final out = <Status, int>{};
    void merge(Map<Status, int> src) {
      for (final e in src.entries) {
        out[e.key] = (out[e.key] ?? 0) + e.value;
      }
    }

    for (final id in equippedOn(racerId)) {
      final t = Tack.byId(id);
      if (t != null) merge(t.startStatuses);
    }
    for (final id in primed) {
      final c = Consumable.byId(id);
      if (c != null) merge(c.startStatuses);
    }
    return out;
  }

  int startingStaminaBonus() {
    var total = 0;
    for (final id in primed) {
      total += Consumable.byId(id)?.staminaBonus ?? 0;
    }
    return total;
  }

  /// Commands added by fitted tack.
  List<String> tackCommands(String racerId) {
    final out = <String>[];
    for (final id in equippedOn(racerId)) {
      final granted = Tack.byId(id)?.grantsCommand;
      if (granted != null) out.add(granted);
    }
    return out;
  }

  void clearPrimed() => primed.clear();

  // ------------------------------------------------------------------- money

  bool spend(int amount) {
    if (grain < amount) return false;
    grain -= amount;
    return true;
  }

  void earn(int amount) => grain += amount;

  void bankEgg(int tier) {
    eggsWon[tier.clamp(0, eggsWon.length - 1)]++;
  }

  // -------------------------------------------------------------- serialising

  Map<String, dynamic> toJson() => {
    'seed': seed,
    'grade': grade,
    'map': map.toJson(),
    'roster': rosterIds,
    'active': activeId,
    'grain': grain,
    'tack': tackOwned,
    'equipped': equipped,
    'bag': bag,
    'primed': primed,
    'cleared': cleared.toList(),
    'path': path,
    'eggsWon': eggsWon,
    'over': over,
    'won': won,
    'pending': pendingNodeId,
    'racesRun': racesRun,
    'racesWon': racesWon,
  };

  static SeasonState fromJson(Map<String, dynamic> j) {
    final state = SeasonState(
      seed: j['seed'] as int,
      grade: j['grade'] as int? ?? 0,
      map: SeasonMap.fromJson(Map<String, dynamic>.from(j['map'] as Map)),
      rosterIds: (j['roster'] as List<dynamic>).cast<String>().toList(),
      activeId: j['active'] as String,
      grain: j['grain'] as int? ?? 0,
    );
    state.tackOwned.addAll(
      (j['tack'] as List<dynamic>? ?? const []).cast<String>(),
    );
    final eq = Map<String, dynamic>.from((j['equipped'] as Map?) ?? const {});
    for (final entry in eq.entries) {
      state.equipped[entry.key] = (entry.value as List<dynamic>)
          .cast<String>()
          .toList();
    }
    final bag = Map<String, dynamic>.from((j['bag'] as Map?) ?? const {});
    for (final entry in bag.entries) {
      state.bag[entry.key] = entry.value as int;
    }
    state.primed.addAll(
      (j['primed'] as List<dynamic>? ?? const []).cast<String>(),
    );
    state.cleared.addAll(
      (j['cleared'] as List<dynamic>? ?? const []).cast<int>(),
    );
    state.path.addAll((j['path'] as List<dynamic>? ?? const []).cast<int>());
    final eggs = (j['eggsWon'] as List<dynamic>? ?? const []).cast<int>();
    for (var i = 0; i < state.eggsWon.length && i < eggs.length; i++) {
      state.eggsWon[i] = eggs[i];
    }
    state.over = j['over'] as bool? ?? false;
    state.won = j['won'] as bool? ?? false;
    state.pendingNodeId = j['pending'] as int?;
    state.racesRun = j['racesRun'] as int? ?? 0;
    state.racesWon = j['racesWon'] as int? ?? 0;
    return state;
  }
}

/// What a finished event paid out. Built by the controller and shown on the
/// results screen.
class EventPayout {
  EventPayout({
    required this.placement,
    required this.fieldSize,
    required this.grain,
    required this.eggTier,
    required this.xp,
    required this.fatigue,
    this.tackId,
    this.injuryId,
    this.learned = const [],
  });

  final int placement;
  final int fieldSize;
  final int grain;

  /// -1 when the placement earned no egg.
  final int eggTier;

  final int xp;
  final int fatigue;
  final String? tackId;
  final String? injuryId;

  /// Alleles the Codex learned from this event.
  final List<String> learned;
}
