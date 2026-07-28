import '../core/rng.dart';
import '../genetics/hatchery.dart';
import '../genetics/pedigree.dart';
import '../genetics/racer.dart';
import 'codex.dart';
import 'upgrades.dart';

/// Everything that survives a season: the birds, the family tree, the egg bank,
/// the built upgrades and the Codex.
class Stable {
  Stable();

  String name = 'Nestline Stable';

  final List<Racer> racers = [];
  final Pedigree pedigree = Pedigree();
  final Codex codex = Codex();

  /// Egg counts by tier, seven entries.
  final List<int> eggs = List<int>.filled(7, 0);

  final Set<String> built = {};

  /// Whether the illustrated opening has been read.
  bool introSeen = false;

  /// Walkthroughs already shown, by [Lesson] name. Stored by name so that
  /// reordering the enum cannot re-arm a lesson the player has finished.
  final Set<String> lessonsSeen = {};

  int seasonsRun = 0;
  int seasonsWon = 0;
  int grade = 0;
  int highestGrade = 0;
  int totalRaces = 0;
  int totalWins = 0;

  // ------------------------------------------------------------------ limits

  int effect(UpgradeEffect e) {
    var total = 0;
    for (final id in built) {
      final u = StableUpgrade.byId(id);
      if (u != null && u.effect == e) total += u.value;
    }
    return total;
  }

  bool has(UpgradeEffect e) => effect(e) > 0;

  int get hatchSlots => 1 + effect(UpgradeEffect.hatchSlot);
  int get rosterSlots => 3 + effect(UpgradeEffect.reserveSlot);
  int get tackSlots => 3 + effect(UpgradeEffect.tackSlot);
  int get startingGrain => 150 + effect(UpgradeEffect.startGrain);
  int get startingFeed => effect(UpgradeEffect.startFeed);
  int get geneReadsPerHatch => effect(UpgradeEffect.geneRead);
  int get injuryGuard => effect(UpgradeEffect.injuryGuard);
  int get restBonus => effect(UpgradeEffect.fatigueRecovery);
  int get eggTierBonus => effect(UpgradeEffect.eggQuality);
  bool get showsGenotypes => has(UpgradeEffect.forecastGenotype);
  int get trainingBonus => effect(UpgradeEffect.trainingBonus);

  double get purseMultiplier => 1 + effect(UpgradeEffect.purseBonus) / 100;
  double get traderMultiplier =>
      (1 - effect(UpgradeEffect.traderDiscount) / 100).clamp(0.3, 1.0);
  double get xpMultiplier => 1 + effect(UpgradeEffect.xpBonus) / 100;

  // ------------------------------------------------------------------- birds

  List<Racer> get active =>
      racers.where((r) => !r.careerOver).toList(growable: false);

  List<Racer> get retiredBirds =>
      racers.where((r) => r.careerOver).toList(growable: false);

  Racer? byId(String? id) {
    if (id == null) return null;
    for (final r in racers) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// True when the stable can no longer field a breeding pair and needs a claim
  /// clutch. Checked after every season.
  bool get needsClaimClutch => active.length < 2;

  void add(Racer racer) {
    racers.add(racer);
    codex.observe(racer.genome);
  }

  void retire(Racer racer) {
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

  bool canBuild(StableUpgrade u) {
    if (built.contains(u.id)) return false;
    if (u.requires != null && !built.contains(u.requires)) return false;
    return canSpendEggs(u.costTier, u.costCount);
  }

  bool build(StableUpgrade u) {
    if (!canBuild(u)) return false;
    if (!spendEggs(u.costTier, u.costCount)) return false;
    built.add(u.id);
    return true;
  }

  List<StableUpgrade> get availableUpgrades => StableUpgrade.all
      .where(
        (u) =>
            !built.contains(u.id) &&
            (u.requires == null || built.contains(u.requires)),
      )
      .toList(growable: false);

  // -------------------------------------------------------------- lifecycle

  void bootstrap(Rng rng) {
    if (racers.isNotEmpty) return;
    for (final r in Hatchery.founders(rng, pedigree)) {
      add(r);
    }
    // A small opening bank so the first Hatchery visit is not a dead end.
    eggs[0] = 4;
    eggs[1] = 1;
  }

  void grantClaimClutch(Rng rng) {
    for (final r in Hatchery.claimClutch(
      rng,
      pedigree,
      taken: racers.map((e) => e.name),
    )) {
      add(r);
    }
  }

  /// Breeds a pair, honouring hatch slots and the egg bank.
  Racer? breed(Racer sire, Racer dam, EggTier tier, Rng rng) {
    if (sire.id == dam.id) return null;
    if (!spendEggs(tier.index, 1)) return null;

    final chick = Hatchery.breed(
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
    'lessonsSeen': lessonsSeen.toList(),
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
          (e) => Racer.fromJson(Map<String, dynamic>.from(e as Map)),
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
    lessonsSeen
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
