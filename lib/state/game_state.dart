import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/sfx.dart';
import '../data/catalog.dart';
import '../data/items.dart';
import '../data/progress_defs.dart';
import '../services/audio_service.dart';

/// The single source of truth for the whole game. Persists to SharedPreferences
/// and runs a lightweight simulation loop (stat decay + egg production) that
/// also catches up on elapsed time when the app was closed (offline progress).
class GameState extends ChangeNotifier {
  static const String _key = 'nestline_save_v1';
  static const int nestCapacity = 8;
  static const int basketCapacity = 999;

  final _rng = Random();
  SharedPreferences? _prefs;
  Timer? _loop;
  bool _dirty = false;

  // ---- Persisted fields ----------------------------------------------------
  String petName = 'Clucky';
  int coins = 100;
  int level = 1;
  int xp = 0;

  final Map<Stat, double> stats = {
    Stat.hunger: 70,
    Stat.mood: 70,
    Stat.health: 80,
    Stat.energy: 75,
    Stat.trust: 30,
  };

  final Set<String> ownedAccessories = {};
  final Map<Slot, String?> equipped = {
    Slot.head: null,
    Slot.eyes: null,
    Slot.neck: null,
    Slot.aura: null,
  };

  final Set<String> ownedSkins = {'skin_white'};
  String equippedSkin = 'skin_white';

  final Set<String> ownedToys = {};

  final Set<String> ownedCoop = {'coop_0'};
  final Set<String> ownedDecor = {};
  final Set<int> unlockedBg = {0};
  int selectedBg = 0;

  final List<int> nest = []; // rarity indices waiting in the nest
  final Map<int, int> basket = {}; // rarity -> count ready to sell
  final Map<int, int> collectionSeen = {}; // rarity -> lifetime collected

  final Map<String, int> counters = {};
  final Set<String> claimedAchievements = {};

  String dayKey = '';
  List<String> dailyQuests = [];
  final Map<String, int> dayCounters = {};
  final Set<String> claimedQuests = {};

  bool sfxOn = true;
  bool hapticsOn = true;

  double _eggProgress = 0;
  DateTime _lastActive = DateTime.now();

  // ---- Derived -------------------------------------------------------------
  double get happiness {
    final s = stats;
    return (s[Stat.hunger]! * 0.24 +
            s[Stat.mood]! * 0.30 +
            s[Stat.health]! * 0.20 +
            s[Stat.energy]! * 0.14 +
            s[Stat.trust]! * 0.12)
        .clamp(0, 100);
  }

  /// Chicken sprite index that best reflects the current state.
  int get moodSprite {
    if (stats[Stat.health]! < 24) return 6; // dirty / unwell
    if (stats[Stat.energy]! < 16) return 3; // sleepy
    if (stats[Stat.mood]! < 26 || stats[Stat.hunger]! < 16) return 5; // sad
    final h = happiness;
    if (h > 85) return 2; // excited
    if (h > 72) return 9; // joyful
    if (h > 58) return 1; // happy
    if (h > 42) return 8; // content
    return 0; // idle
  }

  int get comfort {
    int c = 0;
    for (final id in ownedCoop) {
      c += Catalog.coop.firstWhere((e) => e.id == id).comfort;
    }
    for (final id in ownedDecor) {
      final i = int.tryParse(id.split('_').last) ?? 0;
      c += Catalog.decor[i].comfort;
    }
    return c;
  }

  int get xpForNext => 90 + (level - 1) * 75;
  double get eggFill => _eggProgress.clamp(0, 1);
  bool get nestFull => nest.length >= nestCapacity;
  int get basketTotal => basket.values.fold(0, (a, b) => a + b);

  int counter(String k) => counters[k] ?? 0;

  bool isFoodUnlocked(FoodItem f) => level >= f.unlockLevel;
  bool isCareUnlocked(CareItem c) => level >= c.unlockLevel;

  // ---- Lifecycle -----------------------------------------------------------
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    AudioService.instance.enabled = sfxOn;
    _applyOfflineProgress();
    _rollDailyIfNeeded();
    _loop = Timer.periodic(const Duration(milliseconds: 1500), (_) => _tick());
  }

  @override
  void dispose() {
    _loop?.cancel();
    flush();
    super.dispose();
  }

  void _tick() {
    _simulate(1.5);
    if (_dirty) {
      _dirty = false;
      notifyListeners();
    }
    _save();
  }

  /// Advance the simulation by [seconds] of real time.
  void _simulate(double seconds) {
    final m = seconds / 60.0;
    _decay(Stat.hunger, 0.9 * m);
    _decay(Stat.energy, 0.6 * m);
    _decay(Stat.mood, 0.5 * m);
    _decay(Stat.health, 0.3 * m);
    _decay(Stat.trust, 0.12 * m);

    // Starvation / exhaustion penalties.
    if (stats[Stat.hunger]! < 20) _decay(Stat.mood, 0.6 * m);
    if (stats[Stat.hunger]! < 10) _decay(Stat.health, 0.5 * m);
    if (stats[Stat.energy]! < 15) _decay(Stat.mood, 0.4 * m);

    // Egg production (slow drip so eggs feel earned, not handed out).
    final rate = (happiness / 100.0) * (1 + comfort / 150.0) / 110.0; // eggs/sec
    if (!nestFull && happiness > 28) {
      _eggProgress += rate * seconds;
      while (_eggProgress >= 1 && !nestFull) {
        _eggProgress -= 1;
        _spawnEgg();
      }
      _dirty = true;
    } else if (_eggProgress != 0) {
      _dirty = true;
    }
    _dirty = true;
  }

  void _decay(Stat s, double amount) {
    final v = (stats[s]! - amount).clamp(0, 100).toDouble();
    if (v != stats[s]) {
      stats[s] = v;
      _dirty = true;
    }
  }

  void _applyOfflineProgress() {
    final now = DateTime.now();
    var elapsed = now.difference(_lastActive).inSeconds;
    if (elapsed <= 0) return;
    elapsed = min(elapsed, 12 * 3600); // forgiving 12h cap
    _simulate(elapsed.toDouble());
    _lastActive = now;
  }

  void _spawnEgg() {
    final rarity = _rollRarity();
    nest.add(rarity);
    if (rarity >= 4) {
      counters['legendaryEggs'] = counter('legendaryEggs') + 1;
    }
  }

  int _rollRarity() {
    final h = happiness;
    final boost = 1 + h / 90.0 + comfort / 120.0;
    final weights = <double>[];
    double total = 0;
    for (final e in Catalog.eggs) {
      final w = e.weight * pow(boost, e.index * 0.9);
      weights.add(w);
      total += w;
    }
    var r = _rng.nextDouble() * total;
    for (int i = 0; i < weights.length; i++) {
      if (r < weights[i]) return i;
      r -= weights[i];
    }
    return 0;
  }

  // ---- Player actions ------------------------------------------------------
  void _bump(String metric, [int by = 1]) {
    counters[metric] = counter(metric) + by;
    dayCounters[metric] = (dayCounters[metric] ?? 0) + by;
    _checkAchievements();
  }

  bool feed(FoodItem f) {
    if (!isFoodUnlocked(f)) return false;
    if (coins < f.price) {
      _sfx(Sfx.errorBuy);
      return false;
    }
    coins -= f.price;
    _applyEffects(f.effects);
    _bump('fed');
    _addXp(3);
    _sfx(Sfx.feeding);
    _save();
    notifyListeners();
    return true;
  }

  bool useCare(CareItem c) {
    if (!isCareUnlocked(c)) return false;
    if (coins < c.price) {
      _sfx(Sfx.errorBuy);
      return false;
    }
    coins -= c.price;
    _applyEffects(c.effects);
    if (c.effects.containsKey(Stat.health)) _bump('bathed');
    if (c.verb == 'Groom' || c.verb == 'Comb' || c.verb == 'Tickle') {
      _bump('groomed');
    }
    _addXp(3);
    _sfx(c.verb == 'Rest' ? Sfx.sleep : Sfx.washing);
    _save();
    notifyListeners();
    return true;
  }

  void pet() {
    _applyEffects({Stat.mood: 8, Stat.trust: 5});
    _bump('pet');
    _addXp(2);
    _sfx(Sfx.petting);
    _save();
    notifyListeners();
  }

  bool buyToy(ToyItem t) {
    if (ownedToys.contains(t.id)) return true;
    if (level < t.unlockLevel || coins < t.price) {
      _sfx(Sfx.errorBuy);
      return false;
    }
    coins -= t.price;
    ownedToys.add(t.id);
    _sfx(Sfx.unlock);
    _save();
    notifyListeners();
    return true;
  }

  void playToy(ToyItem t) {
    if (!ownedToys.contains(t.id)) return;
    if (stats[Stat.energy]! < 8) {
      _sfx(Sfx.sad);
      return;
    }
    _applyEffects({
      Stat.mood: t.moodGain,
      Stat.energy: -6,
      Stat.trust: 3,
    });
    _bump('toyPlayed');
    _addXp(3);
    _sfx(Sfx.happy);
    _save();
    notifyListeners();
  }

  void _applyEffects(Map<Stat, int> effects) {
    effects.forEach((s, v) {
      stats[s] = (stats[s]! + v).clamp(0, 100).toDouble();
    });
  }

  // ---- Eggs ----------------------------------------------------------------
  void collectAllEggs() {
    if (nest.isEmpty) return;
    for (final r in nest) {
      basket[r] = (basket[r] ?? 0) + 1;
      collectionSeen[r] = (collectionSeen[r] ?? 0) + 1;
      _bump('eggsCollected');
      _addXp(1);
    }
    _sfx(nest.any((r) => r >= 4) ? Sfx.rareEgg : Sfx.eggCollect);
    nest.clear();
    _save();
    notifyListeners();
  }

  int sellAllEggs() {
    int total = 0;
    basket.forEach((rarity, count) {
      total += Catalog.eggs[rarity].value * count;
    });
    if (total <= 0) return 0;
    final sold = basketTotal;
    basket.clear();
    _earn(total);
    _bump('eggsSold', sold);
    _sfx(Sfx.sell);
    _save();
    notifyListeners();
    return total;
  }

  int sellRarity(int rarity) {
    final count = basket[rarity] ?? 0;
    if (count == 0) return 0;
    final total = Catalog.eggs[rarity].value * count;
    basket.remove(rarity);
    _earn(total);
    _bump('eggsSold', count);
    _sfx(Sfx.sell);
    _save();
    notifyListeners();
    return total;
  }

  // ---- Economy & XP --------------------------------------------------------
  void _earn(int amount) {
    coins += amount;
    counters['coinsEarned'] = counter('coinsEarned') + amount;
    dayCounters['coinsEarnedToday'] =
        (dayCounters['coinsEarnedToday'] ?? 0) + amount;
    _checkAchievements();
  }

  void addCoins(int amount) {
    _earn(amount);
    _save();
    notifyListeners();
  }

  void _addXp(int amount) {
    xp += amount;
    while (xp >= xpForNext) {
      xp -= xpForNext;
      level++;
      final reward = level * 10;
      coins += reward;
      counters['level'] = level;
      _sfx(Sfx.levelUp);
      _checkAchievements();
    }
  }

  // ---- Shop / purchases ----------------------------------------------------
  bool buyAccessory(Accessory a) {
    if (ownedAccessories.contains(a.id)) return true;
    if (level < a.unlockLevel || coins < a.price) {
      _sfx(Sfx.errorBuy);
      return false;
    }
    coins -= a.price;
    ownedAccessories.add(a.id);
    counters['accessoriesOwned'] = ownedAccessories.length;
    _checkAchievements();
    _sfx(Sfx.unlock);
    _save();
    notifyListeners();
    return true;
  }

  void equip(Accessory a) {
    if (!ownedAccessories.contains(a.id)) return;
    equipped[a.slot] = equipped[a.slot] == a.id ? null : a.id;
    _sfx(Sfx.click);
    _save();
    notifyListeners();
  }

  bool buySkin(FeatherSkin s) {
    if (ownedSkins.contains(s.id)) return true;
    if (coins < s.price) {
      _sfx(Sfx.errorBuy);
      return false;
    }
    coins -= s.price;
    ownedSkins.add(s.id);
    counters['skinsOwned'] = ownedSkins.length;
    _checkAchievements();
    _sfx(Sfx.unlock);
    _save();
    notifyListeners();
    return true;
  }

  void equipSkin(FeatherSkin s) {
    if (!ownedSkins.contains(s.id)) return;
    equippedSkin = s.id;
    _sfx(Sfx.click);
    _save();
    notifyListeners();
  }

  bool buyCoop(CoopItem c, {bool decor = false}) {
    final set = decor ? ownedDecor : ownedCoop;
    if (set.contains(c.id)) return true;
    if (level < c.unlockLevel || coins < c.price) {
      _sfx(Sfx.errorBuy);
      return false;
    }
    coins -= c.price;
    set.add(c.id);
    counters['coopOwned'] = ownedCoop.length + ownedDecor.length;
    _checkAchievements();
    _sfx(Sfx.purchaseUpgrade);
    _save();
    notifyListeners();
    return true;
  }

  bool unlockBackground(int index, int price) {
    if (unlockedBg.contains(index)) {
      selectedBg = index;
      _sfx(Sfx.click);
      _save();
      notifyListeners();
      return true;
    }
    if (coins < price) {
      _sfx(Sfx.errorBuy);
      return false;
    }
    coins -= price;
    unlockedBg.add(index);
    selectedBg = index;
    counters['bgUnlocked'] = unlockedBg.length;
    _checkAchievements();
    _sfx(Sfx.unlock);
    _save();
    notifyListeners();
    return true;
  }

  void selectBackground(int index) {
    if (!unlockedBg.contains(index)) return;
    selectedBg = index;
    _sfx(Sfx.click);
    _save();
    notifyListeners();
  }

  // ---- Mini-games ----------------------------------------------------------
  void finishMiniGame(int coinsWon, int moodGain) {
    _earn(coinsWon);
    _applyEffects({Stat.mood: moodGain, Stat.energy: -4});
    _bump('gamesPlayed');
    _addXp(4);
    _sfx(Sfx.happy);
    _save();
    notifyListeners();
  }

  // ---- Achievements & quests ----------------------------------------------
  final List<String> pendingCelebrations = [];

  void _checkAchievements() {
    counters['level'] = level;
    for (final a in ProgressDefs.achievements) {
      if (claimedAchievements.contains(a.id)) continue;
      if (counter(a.metric) >= a.goal) {
        // auto-complete but require manual claim in UI; mark ready via pending
      }
    }
  }

  bool achievementReady(Achievement a) =>
      !claimedAchievements.contains(a.id) && counter(a.metric) >= a.goal;

  bool claimAchievement(Achievement a) {
    if (!achievementReady(a)) return false;
    claimedAchievements.add(a.id);
    coins += a.reward;
    _sfx(Sfx.award);
    _save();
    notifyListeners();
    return true;
  }

  void _rollDailyIfNeeded() {
    final now = DateTime.now();
    final key =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (dayKey == key && dailyQuests.length == 3) return;
    dayKey = key;
    dayCounters.clear();
    claimedQuests.clear();
    final pool = [...ProgressDefs.questPool]..shuffle(_rng);
    dailyQuests = pool.take(3).map((q) => q.id).toList();
    _save();
  }

  QuestTemplate questById(String id) =>
      ProgressDefs.questPool.firstWhere((q) => q.id == id);

  int questProgress(QuestTemplate q) =>
      (dayCounters[q.metric] ?? 0).clamp(0, q.goal);

  bool questReady(QuestTemplate q) =>
      !claimedQuests.contains(q.id) && (dayCounters[q.metric] ?? 0) >= q.goal;

  bool claimQuest(QuestTemplate q) {
    if (!questReady(q)) return false;
    claimedQuests.add(q.id);
    _earn(q.coinReward);
    _addXp(q.xpReward);
    _bump('questsDone');
    _sfx(Sfx.questComplete);
    _save();
    notifyListeners();
    return true;
  }

  // ---- Settings ------------------------------------------------------------
  void setSfx(bool v) {
    sfxOn = v;
    AudioService.instance.enabled = v;
    _save();
    notifyListeners();
  }

  void setHaptics(bool v) {
    hapticsOn = v;
    _save();
    notifyListeners();
  }

  void setName(String v) {
    petName = v.trim().isEmpty ? 'Clucky' : v.trim();
    _save();
    notifyListeners();
  }

  void resetProgress() {
    _prefs?.remove(_key);
    coins = 100;
    level = 1;
    xp = 0;
    stats
      ..[Stat.hunger] = 70
      ..[Stat.mood] = 70
      ..[Stat.health] = 80
      ..[Stat.energy] = 75
      ..[Stat.trust] = 30;
    ownedAccessories.clear();
    equipped.updateAll((_, _) => null);
    ownedSkins
      ..clear()
      ..add('skin_white');
    equippedSkin = 'skin_white';
    ownedToys.clear();
    ownedCoop
      ..clear()
      ..add('coop_0');
    ownedDecor.clear();
    unlockedBg
      ..clear()
      ..add(0);
    selectedBg = 0;
    nest.clear();
    basket.clear();
    collectionSeen.clear();
    counters.clear();
    claimedAchievements.clear();
    _rollDailyIfNeeded();
    _save();
    notifyListeners();
  }

  void _sfx(String path) {
    if (sfxOn) AudioService.instance.play(path);
  }

  // ---- Persistence ---------------------------------------------------------
  void _save() {
    _lastActive = DateTime.now();
    _prefs?.setString(_key, jsonEncode(_toJson()));
  }

  void flush() => _save();

  Map<String, dynamic> _toJson() => {
        'petName': petName,
        'coins': coins,
        'level': level,
        'xp': xp,
        'stats': stats.map((k, v) => MapEntry(k.name, v)),
        'ownedAccessories': ownedAccessories.toList(),
        'equipped': equipped.map((k, v) => MapEntry(k.name, v)),
        'ownedSkins': ownedSkins.toList(),
        'equippedSkin': equippedSkin,
        'ownedToys': ownedToys.toList(),
        'ownedCoop': ownedCoop.toList(),
        'ownedDecor': ownedDecor.toList(),
        'unlockedBg': unlockedBg.toList(),
        'selectedBg': selectedBg,
        'nest': nest,
        'basket': basket.map((k, v) => MapEntry('$k', v)),
        'collectionSeen': collectionSeen.map((k, v) => MapEntry('$k', v)),
        'counters': counters,
        'claimedAchievements': claimedAchievements.toList(),
        'dayKey': dayKey,
        'dailyQuests': dailyQuests,
        'dayCounters': dayCounters,
        'claimedQuests': claimedQuests.toList(),
        'sfxOn': sfxOn,
        'hapticsOn': hapticsOn,
        'eggProgress': _eggProgress,
        'lastActive': _lastActive.toIso8601String(),
      };

  void _fromJson(Map<String, dynamic> j) {
    petName = j['petName'] ?? petName;
    coins = j['coins'] ?? coins;
    level = j['level'] ?? level;
    xp = j['xp'] ?? xp;
    final s = (j['stats'] as Map?) ?? {};
    for (final st in Stat.values) {
      if (s[st.name] != null) stats[st] = (s[st.name] as num).toDouble();
    }
    ownedAccessories
      ..clear()
      ..addAll(List<String>.from(j['ownedAccessories'] ?? []));
    final eq = (j['equipped'] as Map?) ?? {};
    for (final slot in Slot.values) {
      equipped[slot] = eq[slot.name] as String?;
    }
    ownedSkins
      ..clear()
      ..addAll(List<String>.from(j['ownedSkins'] ?? ['skin_white']));
    if (ownedSkins.isEmpty) ownedSkins.add('skin_white');
    equippedSkin = j['equippedSkin'] ?? 'skin_white';
    ownedToys
      ..clear()
      ..addAll(List<String>.from(j['ownedToys'] ?? []));
    ownedCoop
      ..clear()
      ..addAll(List<String>.from(j['ownedCoop'] ?? ['coop_0']));
    ownedDecor
      ..clear()
      ..addAll(List<String>.from(j['ownedDecor'] ?? []));
    unlockedBg
      ..clear()
      ..addAll(List<int>.from(j['unlockedBg'] ?? [0]));
    selectedBg = j['selectedBg'] ?? 0;
    nest
      ..clear()
      ..addAll(List<int>.from(j['nest'] ?? []));
    basket.clear();
    (j['basket'] as Map?)?.forEach((k, v) => basket[int.parse(k)] = v as int);
    collectionSeen.clear();
    (j['collectionSeen'] as Map?)
        ?.forEach((k, v) => collectionSeen[int.parse(k)] = v as int);
    counters
      ..clear()
      ..addAll(Map<String, int>.from(j['counters'] ?? {}));
    claimedAchievements
      ..clear()
      ..addAll(List<String>.from(j['claimedAchievements'] ?? []));
    dayKey = j['dayKey'] ?? '';
    dailyQuests = List<String>.from(j['dailyQuests'] ?? []);
    dayCounters
      ..clear()
      ..addAll(Map<String, int>.from(j['dayCounters'] ?? {}));
    claimedQuests
      ..clear()
      ..addAll(List<String>.from(j['claimedQuests'] ?? []));
    sfxOn = j['sfxOn'] ?? true;
    hapticsOn = j['hapticsOn'] ?? true;
    _eggProgress = (j['eggProgress'] as num?)?.toDouble() ?? 0;
    _lastActive =
        DateTime.tryParse(j['lastActive'] ?? '') ?? DateTime.now();
  }
}
