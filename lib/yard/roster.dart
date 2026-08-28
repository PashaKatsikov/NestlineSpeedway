import 'package:nestline_circuit/app/dice.dart';
import 'package:nestline_circuit/blood/brooder.dart';
import 'package:nestline_circuit/blood/bloodline.dart';
import 'package:nestline_circuit/blood/runner.dart';
import 'package:nestline_circuit/yard/ledger.dart';
import 'package:nestline_circuit/yard/works.dart';

/// Everything that survives a season: the birds, the family tree, the egg bank,
/// the built upgrades and the Ledger.
class Yard {
  Yard();

  String name = 'Nestline Stable';

  final List<Runner> racers = [];
  final Bloodline pedigree = Bloodline();
  final Ledger codex = Ledger();

  /// Egg counts by tier, seven entries.
  final List<int> eggs = List<int>.filled(7, 0);

  final Set<String> built = {};

  /// Whether the illustrated opening has been read.
  bool introSeen = false;

  /// Walkthroughs already shown, by [Guide] name. Stored by name so that
  /// reordering the enum cannot re-arm a lesson the player has finished.
  final Set<String> guidesSeen = {};

  int seasonsRun = 0;
  int seasonsWon = 0;
  int grade = 0;
  int highestGrade = 0;
  int totalRaces = 0;
  int totalWins = 0;

  // ------------------------------------------------------------------ limits

  int effect(WorkEffect e) {
    var total = 0;
    for (final id in built) {
      final u = YardWork.byId(id);
      if (u != null && u.effect == e) total += u.value;
    }
    return total;
  }

  bool has(WorkEffect e) => effect(e) > 0;

  int get hatchSlots => 1 + effect(WorkEffect.hatchSlot);
  int get rosterSlots => 3 + effect(WorkEffect.reserveSlot);
  int get tackSlots => 3 + effect(WorkEffect.tackSlot);
  int get startingGrain => 150 + effect(WorkEffect.startGrain);
  int get startingFeed => effect(WorkEffect.startFeed);
  int get geneReadsPerHatch => effect(WorkEffect.geneRead);
  int get injuryGuard => effect(WorkEffect.injuryGuard);
  int get restBonus => effect(WorkEffect.fatigueRecovery);
  int get eggTierBonus => effect(WorkEffect.eggQuality);
  bool get showsGenotypes => has(WorkEffect.forecastGenotype);
  int get trainingBonus => effect(WorkEffect.trainingBonus);

  double get purseMultiplier => 1 + effect(WorkEffect.purseBonus) / 100;
  double get traderMultiplier =>
      (1 - effect(WorkEffect.traderDiscount) / 100).clamp(0.3, 1.0);
  double get xpMultiplier => 1 + effect(WorkEffect.xpBonus) / 100;

  // ------------------------------------------------------------------- birds

  List<Runner> get active =>
      racers.where((r) => !r.careerOver).toList(growable: false);

  List<Runner> get retiredBirds =>
      racers.where((r) => r.careerOver).toList(growable: false);

  Runner? byId(String? id) {
    if (id == null) return null;
    for (final r in racers) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// True when the stable can no longer field a breeding pair and needs a claim
  /// clutch. Checked after every season.
  bool get needsClaimClutch => active.length < 2;

  void add(Runner racer) {
    racers.add(racer);
    codex.observe(racer.genome);
  }

  void retire(Runner racer) {
    racer.retired = true;
  }

  // -------------------------------------------------------------------- eggs

  int get eggTotal => eggs.fold(0, (a, b) => a + b);

  void addEgg(int tier, [int count = 1]) {
    final t = (tier + eggTierBonus).clamp(0, eggs.length - 1);
    eggs[t] += count;
  }

  /// Whether the bank holds [count] eggs of at least [minTier].
  bool canSpendEggs(int minTier, int count) {
    var available = 0;
    for (var t = minTier; t < eggs.length; t++) {
      available += eggs[t];
    }
    return available >= count;
  }

  /// Spends from the lowest acceptable tier upward so premium shells are kept
  /// for the things that need them.
  bool spendEggs(int minTier, int count) {
    if (!canSpendEggs(minTier, count)) return false;
    var left = count;
    for (var t = minTier; t < eggs.length && left > 0; t++) {
      final take = eggs[t] < left ? eggs[t] : left;
      eggs[t] -= take;
      left -= take;
    }
    return true;
  }

  /// Highest tier with at least one egg in the bank, or -1 when empty.
  int get bestEggTier {
    for (var t = eggs.length - 1; t >= 0; t--) {
      if (eggs[t] > 0) return t;
    }
    return -1;
  }

  // ---------------------------------------------------------------- upgrades

  bool isBuilt(String id) => built.contains(id);

  bool canBuild(YardWork u) {
    if (built.contains(u.id)) return false;
    if (u.requires != null && !built.contains(u.requires)) return false;
    return canSpendEggs(u.costTier, u.costCount);
  }

  bool build(YardWork u) {
    if (!canBuild(u)) return false;
    if (!spendEggs(u.costTier, u.costCount)) return false;
    built.add(u.id);
    return true;
  }

  List<YardWork> get availableUpgrades => YardWork.all
      .where(
        (u) =>
            !built.contains(u.id) &&
            (u.requires == null || built.contains(u.requires)),
      )
      .toList(growable: false);

  // -------------------------------------------------------------- lifecycle

  void bootstrap(Dice rng) {
    if (racers.isNotEmpty) return;
    for (final r in Brooder.founders(rng, pedigree)) {
      add(r);
    }
    // A small opening bank so the first Brooder visit is not a dead end.
    eggs[0] = 4;
    eggs[1] = 1;
  }

  void grantClaimClutch(Dice rng) {
    for (final r in Brooder.claimClutch(
      rng,
      pedigree,
      taken: racers.map((e) => e.name),
    )) {
      add(r);
    }
  }

  /// Breeds a pair, honouring hatch slots and the egg bank.
  Runner? breed(Runner sire, Runner dam, ShellTier tier, Dice rng) {
    if (sire.id == dam.id) return null;
    if (!spendEggs(tier.index, 1)) return null;

    final chick = Brooder.breed(
      sire: sire,
      dam: dam,
      tier: tier,
      rng: rng,
      pedigree: pedigree,
      taken: racers.map((e) => e.name),
    );
    add(chick);

    // A homozygous locus proves both copies, so those are always learned.
    for (final l in chick.genome.pureLoci) {
      codex.discoverAllele(l, chick.genome.first(l));
    }

    // Gene Lab reads open up carried alleles the phenotype hides.
    var reads = geneReadsPerHatch;
    for (final l in chick.genome.hiddenLoci) {
      if (reads <= 0) break;
      if (codex.reveal(chick.genome, l) != null) reads--;
    }
    return chick;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'racers': racers.map((r) => r.toJson()).toList(),
    'pedigree': pedigree.toJson(),
    'codex': codex.toJson(),
    'eggs': eggs,
    'built': built.toList(),
    'introSeen': introSeen,
    'lessonsSeen': guidesSeen.toList(),
    'seasonsRun': seasonsRun,
    'seasonsWon': seasonsWon,
    'grade': grade,
    'highestGrade': highestGrade,
    'totalRaces': totalRaces,
    'totalWins': totalWins,
  };

  void loadJson(Map<String, dynamic> j) {
    name = j['name'] as String? ?? name;
    racers
      ..clear()
      ..addAll(
        (j['racers'] as List<dynamic>? ?? const []).map(
          (e) => Runner.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
    pedigree.loadJson(j['pedigree'] as List<dynamic>? ?? const []);
    codex.loadJson(
      Map<String, dynamic>.from(
        (j['codex'] as Map?) ?? const <String, dynamic>{},
      ),
    );
    final rawEggs = (j['eggs'] as List<dynamic>? ?? const []).cast<int>();
    for (var i = 0; i < eggs.length; i++) {
      eggs[i] = i < rawEggs.length ? rawEggs[i] : 0;
    }
    built
      ..clear()
      ..addAll((j['built'] as List<dynamic>? ?? const []).cast<String>());
    introSeen = j['introSeen'] as bool? ?? false;
    guidesSeen
      ..clear()
      ..addAll((j['lessonsSeen'] as List<dynamic>? ?? const []).cast<String>());
    seasonsRun = j['seasonsRun'] as int? ?? 0;
    seasonsWon = j['seasonsWon'] as int? ?? 0;
    grade = j['grade'] as int? ?? 0;
    highestGrade = j['highestGrade'] as int? ?? 0;
    totalRaces = j['totalRaces'] as int? ?? 0;
    totalWins = j['totalWins'] as int? ?? 0;
  }
}
