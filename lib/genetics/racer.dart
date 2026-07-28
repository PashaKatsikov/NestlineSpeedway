import '../core/rng.dart';
import '../core/sprites.dart';
import 'genome.dart';
import 'locus.dart';
import 'pedigree.dart';

/// Injuries picked up on the circuit. They follow the bird home, which is what
/// makes pushing a tired racer one event further a real decision.
class Injury {
  const Injury({
    required this.id,
    required this.name,
    required this.blurb,
    required this.mods,
    required this.severity,
    required this.remedySprite,
  });

  final String id;
  final String name;
  final String blurb;
  final StatMods mods;

  /// 1 light, 2 moderate, 3 career-ending.
  final int severity;
  final int remedySprite;

  bool get careerEnding => severity >= 3;

  static const List<Injury> catalogue = [
    Injury(
      id: 'strain',
      name: 'Muscle Strain',
      blurb: 'Tight all down one side. Loses wind quickly.',
      mods: StatMods(stamina: -8),
      severity: 1,
      remedySprite: 0,
    ),
    Injury(
      id: 'sore_foot',
      name: 'Sore Foot',
      blurb: 'Landing short on every step.',
      mods: StatMods(stride: -1),
      severity: 1,
      remedySprite: 2,
    ),
    Injury(
      id: 'wing_bruise',
      name: 'Wing Bruise',
      blurb: 'Reluctant to flap. Reads the race a beat late.',
      mods: StatMods(hand: -1),
      severity: 1,
      remedySprite: 3,
    ),
    Injury(
      id: 'split_claw',
      name: 'Split Claw',
      blurb: 'No purchase on anything loose.',
      mods: StatMods(grip: -2),
      severity: 2,
      remedySprite: 4,
    ),
    Injury(
      id: 'wind_damage',
      name: 'Wind Damage',
      blurb: 'The tank never fills the same way again.',
      mods: StatMods(stamina: -16, recovery: -2),
      severity: 2,
      remedySprite: 7,
    ),
    Injury(
      id: 'tendon',
      name: 'Torn Tendon',
      blurb: 'She will walk again, but she will not race again.',
      mods: StatMods(stride: -2, stamina: -20),
      severity: 3,
      remedySprite: 8,
    ),
  ];

  static Injury byId(String id) =>
      catalogue.firstWhere((i) => i.id == id, orElse: () => catalogue.first);

  /// Rolls an injury of at most [maxSeverity].
  static Injury roll(Rng rng, int maxSeverity) {
    final pool = catalogue
        .where((i) => i.severity <= maxSeverity)
        .toList(growable: false);
    final weights = pool
        .map(
          (i) => switch (i.severity) {
            1 => 6.0,
            2 => 2.5,
            _ => 0.7,
          },
        )
        .toList(growable: false);
    return rng.weighted(pool, weights);
  }
}

/// A bird in the stable.
class Racer {
  Racer({
    required this.id,
    required this.name,
    required this.genome,
    required this.birthOrder,
    this.sireId,
    this.damId,
    this.inbreeding = 0,
    this.originTier = 0,
    this.plume = 0,
    this.races = 0,
    this.wins = 0,
    this.podiums = 0,
    this.xp = 0,
    this.fatigue = 0,
    this.retired = false,
    List<String>? injuries,
    List<String>? tack,
  }) : injuries = injuries ?? <String>[],
       tack = tack ?? <String>[];

  final String id;
  String name;
  final Genome genome;
  final int birthOrder;
  final String? sireId;
  final String? damId;

  /// Inbreeding coefficient computed at hatch and frozen, so the value shown to
  /// the player never silently shifts as the tree grows.
  final double inbreeding;

  /// Tier of the egg she came from, 0–6. Cosmetic plus a small breeding bonus.
  final int originTier;

  /// Which of the sixteen feather plates represents her silks.
  final int plume;

  int races;
  int wins;
  int podiums;
  int xp;

  /// 0–100. Accumulates across a season, drains stamina, cleared by Rest.
  int fatigue;

  bool retired;

  /// Injury ids, resolved through [Injury.byId].
  final List<String> injuries;

  /// Equipped tack ids, resolved through the tack catalogue.
  final List<String> tack;

  // ---------------------------------------------------------------- derived

  /// Experience rank, 0–5. Each rank is a small, earned stat bump, which is what
  /// makes a mediocre bird you have actually raced worth keeping.
  int get rank {
    const thresholds = [0, 40, 110, 220, 400, 650];
    var r = 0;
    for (var i = 1; i < thresholds.length; i++) {
      if (xp >= thresholds[i]) r = i;
    }
    return r;
  }

  int get xpToNextRank {
    const thresholds = [0, 40, 110, 220, 400, 650];
    if (rank >= 5) return 0;
    return thresholds[rank + 1] - xp;
  }

  List<Injury> get injuryList =>
      injuries.map(Injury.byId).toList(growable: false);

  bool get careerOver => retired || injuryList.any((i) => i.careerEnding);

  InbreedingPenalty get inbreedingPenalty =>
      InbreedingPenalty.forCoefficient(inbreeding);

  /// The genome's raw expression, before condition and equipment.
  Phenotype get basePhenotype => Phenotype.of(genome);

  /// What the bird actually takes to the line: genome, rank, injuries,
  /// inbreeding and fatigue, all folded together.
  Phenotype phenotype({StatMods extra = const StatMods()}) {
    final base = Phenotype.of(genome);

    var mods = StatMods(
      stamina: base.staminaMax,
      stride: base.stride,
      effort: base.effort,
      grip: base.grip,
      control: base.control,
      recovery: base.recovery,
      hand: base.hand,
      momentumGain: base.momentumGain,
    );

    // Rank: every other rank widens the tank, odd ranks sharpen the legs.
    mods =
        mods +
        StatMods(
          stamina: rank * 3,
          stride: rank >= 3 ? 1 : 0,
          recovery: rank >= 5 ? 1 : 0,
        );

    for (final injury in injuryList) {
      mods = mods + injury.mods;
    }
    mods = mods + extra;

    // Inbreeding eats the stamina pool proportionally, after flat modifiers.
    final penalty = inbreedingPenalty;
    var stamina = mods.stamina;
    if (penalty.staminaPenalty > 0) {
      stamina = (stamina * (1 - penalty.staminaPenalty)).round();
    }
    // Fatigue is a proportional cut too, so a tired bird is never simply a
    // slower bird — she is a bird who cannot afford her own commands.
    stamina = (stamina * (1 - fatigue / 160)).round();

    var commands = List<String>.of(base.commandIds);
    if (penalty.commandLoss > 0) {
      // Drop the weakest non-core commands first.
      final core = Phenotype.coreCommands.toSet();
      for (var i = 0; i < penalty.commandLoss; i++) {
        final idx = commands.lastIndexWhere((c) => !core.contains(c));
        if (idx >= 0) commands.removeAt(idx);
      }
    }

    return Phenotype(
      staminaMax: stamina.clamp(10, 240),
      stride: mods.stride.clamp(1, 12),
      effort: mods.effort.clamp(1, 8),
      grip: mods.grip.clamp(0, 8),
      control: mods.control.clamp(-3, 8),
      recovery: mods.recovery.clamp(1, 20),
      hand: mods.hand.clamp(3, 8),
      momentumGain: mods.momentumGain,
      commandIds: commands,
      expressedTraits: base.expressedTraits,
      pureTraits: base.pureTraits,
      synergies: base.synergies,
    );
  }

  /// Pose used for portraits: reflects condition rather than mood.
  int get portraitPose {
    if (careerOver) return Sprites.poseSpent;
    if (injuries.isNotEmpty) return Sprites.poseHurt;
    if (fatigue > 60) return Sprites.poseCalm;
    if (wins > 0) return Sprites.poseStrut;
    return Sprites.poseReady;
  }

  String get lineageLabel {
    if (sireId == null || damId == null) return 'Foundation stock';
    return 'Generation ${birthOrder > 0 ? birthOrder : 1}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'g': genome.toJson(),
    'n': birthOrder,
    if (sireId != null) 'sire': sireId,
    if (damId != null) 'dam': damId,
    'f': inbreeding,
    'tier': originTier,
    'plume': plume,
    'races': races,
    'wins': wins,
    'podiums': podiums,
    'xp': xp,
    'fatigue': fatigue,
    'retired': retired,
    'inj': injuries,
    'tack': tack,
  };

  static Racer fromJson(Map<String, dynamic> j) => Racer(
    id: j['id'] as String,
    name: j['name'] as String,
    genome: Genome.fromJson(j['g'] as List<dynamic>),
    birthOrder: j['n'] as int? ?? 0,
    sireId: j['sire'] as String?,
    damId: j['dam'] as String?,
    inbreeding: (j['f'] as num?)?.toDouble() ?? 0,
    originTier: j['tier'] as int? ?? 0,
    plume: j['plume'] as int? ?? 0,
    races: j['races'] as int? ?? 0,
    wins: j['wins'] as int? ?? 0,
    podiums: j['podiums'] as int? ?? 0,
    xp: j['xp'] as int? ?? 0,
    fatigue: j['fatigue'] as int? ?? 0,
    retired: j['retired'] as bool? ?? false,
    injuries: (j['inj'] as List<dynamic>?)?.cast<String>().toList(),
    tack: (j['tack'] as List<dynamic>?)?.cast<String>().toList(),
  );
}
