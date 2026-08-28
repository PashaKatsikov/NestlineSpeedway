import 'package:nestline_circuit/app/atlas.dart';

/// What a stable upgrade actually does. Keeping effects as a small enum means
/// the rest of the game asks the stable a question rather than reading flags.
enum WorkEffect {
  hatchSlot,
  reserveSlot,
  tackSlot,
  startGrain,
  startFeed,
  geneRead,
  injuryGuard,
  fatigueRecovery,
  xpBonus,
  purseBonus,
  traderDiscount,
  eggQuality,
  forecastGenotype,
  trainingBonus,
}

extension UpgradeEffectInfo on WorkEffect {
  String get label => switch (this) {
    WorkEffect.hatchSlot => 'Hatch slots',
    WorkEffect.reserveSlot => 'Reserve racers',
    WorkEffect.tackSlot => 'Tack slots',
    WorkEffect.startGrain => 'Starting grain',
    WorkEffect.startFeed => 'Starting feed',
    WorkEffect.geneRead => 'Alleles revealed at hatch',
    WorkEffect.injuryGuard => 'Injury severity reduction',
    WorkEffect.fatigueRecovery => 'Extra fatigue cleared at Rest',
    WorkEffect.xpBonus => 'Bonus experience per race',
    WorkEffect.purseBonus => 'Bonus grain per purse',
    WorkEffect.traderDiscount => 'Trader discount',
    WorkEffect.eggQuality => 'Egg tier bonus',
    WorkEffect.forecastGenotype => 'Hatchery shows full genotypes',
    WorkEffect.trainingBonus => 'Extra training value',
  };
}

class YardWork {
  const YardWork({
    required this.id,
    required this.name,
    required this.blurb,
    required this.sprite,
    required this.effect,
    required this.value,
    required this.costTier,
    required this.costCount,
    this.requires,
  });

  final String id;
  final String name;
  final String blurb;

  /// Index into the coop sprite set.
  final int sprite;

  final WorkEffect effect;
  final int value;

  /// Minimum egg tier accepted as payment, and how many eggs are needed.
  final int costTier;
  final int costCount;

  /// Upgrade that must be built first.
  final String? requires;

  String get iconPath => Atlas.stable(sprite);

  static final Map<String, YardWork> _byId = {
    for (final u in all) u.id: u,
  };
  static YardWork? byId(String id) => _byId[id];

  static const List<YardWork> all = [
    // Brooder capacity.
    YardWork(
      id: 'incubator_1',
      name: 'Incubator',
      blurb: 'A second egg can sit under lamps at once.',
      sprite: 0,
      effect: WorkEffect.hatchSlot,
      value: 1,
      costTier: 0,
      costCount: 3,
    ),
    YardWork(
      id: 'incubator_2',
      name: 'Twin Incubator',
      blurb: 'Two pairings on the go. The programme moves twice as fast.',
      sprite: 1,
      effect: WorkEffect.hatchSlot,
      value: 1,
      costTier: 1,
      costCount: 4,
      requires: 'incubator_1',
    ),
    YardWork(
      id: 'incubator_3',
      name: 'Hatch Hall',
      blurb: 'Industrial. Slightly alarming. Very effective.',
      sprite: 2,
      effect: WorkEffect.hatchSlot,
      value: 2,
      costTier: 3,
      costCount: 3,
      requires: 'incubator_2',
    ),

    // Roster capacity.
    YardWork(
      id: 'paddock_1',
      name: 'Paddock',
      blurb: 'Room for one more bird on the road.',
      sprite: 3,
      effect: WorkEffect.reserveSlot,
      value: 1,
      costTier: 0,
      costCount: 4,
    ),
    YardWork(
      id: 'paddock_2',
      name: 'Travelling Coop',
      blurb: 'Take a fourth bird to every season.',
      sprite: 4,
      effect: WorkEffect.reserveSlot,
      value: 1,
      costTier: 2,
      costCount: 3,
      requires: 'paddock_1',
    ),

    // Tack capacity.
    YardWork(
      id: 'tack_room',
      name: 'Tack Room',
      blurb: 'A fourth piece of gear can be fitted.',
      sprite: 5,
      effect: WorkEffect.tackSlot,
      value: 1,
      costTier: 1,
      costCount: 5,
    ),
    YardWork(
      id: 'tack_wall',
      name: 'Tack Wall',
      blurb: 'Five pieces. Now it is a build.',
      sprite: 6,
      effect: WorkEffect.tackSlot,
      value: 1,
      costTier: 3,
      costCount: 4,
      requires: 'tack_room',
    ),

    // Season economy.
    YardWork(
      id: 'feed_silo_1',
      name: 'Feed Silo',
      blurb: 'Start every season with 120 grain.',
      sprite: 7,
      effect: WorkEffect.startGrain,
      value: 120,
      costTier: 0,
      costCount: 5,
    ),
    YardWork(
      id: 'feed_silo_2',
      name: 'Grain Store',
      blurb: 'Another 180 grain in the account.',
      sprite: 8,
      effect: WorkEffect.startGrain,
      value: 180,
      costTier: 2,
      costCount: 4,
      requires: 'feed_silo_1',
    ),
    YardWork(
      id: 'kitchen',
      name: 'Feed Kitchen',
      blurb: 'Two bags of feed packed before you leave.',
      sprite: 9,
      effect: WorkEffect.startFeed,
      value: 2,
      costTier: 1,
      costCount: 4,
    ),
    YardWork(
      id: 'sponsor_board',
      name: 'Sponsor Board',
      blurb: 'Every purse pays 20% more.',
      sprite: 10,
      effect: WorkEffect.purseBonus,
      value: 20,
      costTier: 2,
      costCount: 5,
    ),
    YardWork(
      id: 'sponsor_banner',
      name: 'Sponsor Banner',
      blurb: 'Another 25% on top. The bunting pays for itself.',
      sprite: 11,
      effect: WorkEffect.purseBonus,
      value: 25,
      costTier: 4,
      costCount: 3,
      requires: 'sponsor_board',
    ),
    YardWork(
      id: 'traders_favour',
      name: "Trader's Favour",
      blurb: 'Everything on the circuit costs 15% less.',
      sprite: 12,
      effect: WorkEffect.traderDiscount,
      value: 15,
      costTier: 1,
      costCount: 6,
    ),
    YardWork(
      id: 'traders_ledger',
      name: "Trader's Ledger",
      blurb: 'A further 15% off. They know your name now.',
      sprite: 13,
      effect: WorkEffect.traderDiscount,
      value: 15,
      costTier: 3,
      costCount: 5,
      requires: 'traders_favour',
    ),

    // Genetics tooling — the upgrades that change how the meta game is played.
    YardWork(
      id: 'gene_lab_1',
      name: 'Gene Lab',
      blurb: 'One hidden allele is revealed on every hatch.',
      sprite: 14,
      effect: WorkEffect.geneRead,
      value: 1,
      costTier: 2,
      costCount: 4,
    ),
    YardWork(
      id: 'gene_lab_2',
      name: 'Sequencer',
      blurb: 'Two alleles revealed per hatch.',
      sprite: 15,
      effect: WorkEffect.geneRead,
      value: 1,
      costTier: 3,
      costCount: 5,
      requires: 'gene_lab_1',
    ),
    YardWork(
      id: 'pedigree_office',
      name: 'Pedigree Office',
      blurb: 'The Hatchery shows full genotypes instead of phenotypes.',
      sprite: 16,
      effect: WorkEffect.forecastGenotype,
      value: 1,
      costTier: 4,
      costCount: 4,
      requires: 'gene_lab_2',
    ),
    YardWork(
      id: 'nest_boxes',
      name: 'Lined Nest Boxes',
      blurb: 'Placements pay out one egg tier higher.',
      sprite: 17,
      effect: WorkEffect.eggQuality,
      value: 1,
      costTier: 2,
      costCount: 6,
    ),
    YardWork(
      id: 'warm_lamps',
      name: 'Warm Lamps',
      blurb: 'Another tier on every egg you win.',
      sprite: 18,
      effect: WorkEffect.eggQuality,
      value: 1,
      costTier: 4,
      costCount: 5,
      requires: 'nest_boxes',
    ),

    // Welfare — the upgrades that keep a lineage alive.
    YardWork(
      id: 'track_wall',
      name: 'Track Wall',
      blurb: 'Injuries come back one severity lighter.',
      sprite: 19,
      effect: WorkEffect.injuryGuard,
      value: 1,
      costTier: 1,
      costCount: 6,
    ),
    YardWork(
      id: 'vet_shed',
      name: 'Vet Shed',
      blurb: 'Another severity shaved off. Careers get longer.',
      sprite: 20,
      effect: WorkEffect.injuryGuard,
      value: 1,
      costTier: 4,
      costCount: 4,
      requires: 'track_wall',
    ),
    YardWork(
      id: 'water_trough',
      name: 'Fresh Trough',
      blurb: 'Rest days clear 25 more fatigue.',
      sprite: 21,
      effect: WorkEffect.fatigueRecovery,
      value: 25,
      costTier: 0,
      costCount: 6,
    ),
    YardWork(
      id: 'shade_awning',
      name: 'Shade Awning',
      blurb: 'Another 25 fatigue off a rest day.',
      sprite: 22,
      effect: WorkEffect.fatigueRecovery,
      value: 25,
      costTier: 2,
      costCount: 5,
      requires: 'water_trough',
    ),
    YardWork(
      id: 'straw_bedding',
      name: 'Deep Bedding',
      blurb: 'Another 30 fatigue. She sleeps properly.',
      sprite: 23,
      effect: WorkEffect.fatigueRecovery,
      value: 30,
      costTier: 3,
      costCount: 5,
      requires: 'shade_awning',
    ),

    // Development.
    YardWork(
      id: 'training_ring',
      name: 'Training Ring',
      blurb: 'Every race teaches 25% more.',
      sprite: 24,
      effect: WorkEffect.xpBonus,
      value: 25,
      costTier: 1,
      costCount: 5,
    ),
    YardWork(
      id: 'gallops',
      name: 'The Gallops',
      blurb: 'Another 30% experience per race.',
      sprite: 25,
      effect: WorkEffect.xpBonus,
      value: 30,
      costTier: 3,
      costCount: 5,
      requires: 'training_ring',
    ),
    YardWork(
      id: 'sand_school',
      name: 'Sand School',
      blurb: 'Training days are worth considerably more.',
      sprite: 26,
      effect: WorkEffect.trainingBonus,
      value: 1,
      costTier: 2,
      costCount: 5,
    ),
    YardWork(
      id: 'hill_circuit',
      name: 'Hill Circuit',
      blurb: 'Training days again as valuable.',
      sprite: 27,
      effect: WorkEffect.trainingBonus,
      value: 1,
      costTier: 4,
      costCount: 4,
      requires: 'sand_school',
    ),

    // Prestige tail.
    YardWork(
      id: 'trophy_case',
      name: 'Trophy Case',
      blurb: 'Purses pay another 25%. Mostly it just looks good.',
      sprite: 28,
      effect: WorkEffect.purseBonus,
      value: 25,
      costTier: 5,
      costCount: 3,
      requires: 'sponsor_banner',
    ),
    YardWork(
      id: 'winners_gate',
      name: "Winners' Gate",
      blurb: 'A fifth bird can travel with the string.',
      sprite: 29,
      effect: WorkEffect.reserveSlot,
      value: 1,
      costTier: 5,
      costCount: 3,
      requires: 'paddock_2',
    ),
    YardWork(
      id: 'grand_stable',
      name: 'Grand Stable',
      blurb: 'A sixth piece of tack, and the respect of the circuit.',
      sprite: 30,
      effect: WorkEffect.tackSlot,
      value: 1,
      costTier: 5,
      costCount: 4,
      requires: 'tack_wall',
    ),
    YardWork(
      id: 'heirloom_nest',
      name: 'Heirloom Nest',
      blurb: 'One more tier on every egg. The best shells come home.',
      sprite: 31,
      effect: WorkEffect.eggQuality,
      value: 1,
      costTier: 6,
      costCount: 2,
      requires: 'warm_lamps',
    ),
    YardWork(
      id: 'clock_tower',
      name: 'Clock Tower',
      blurb: 'Three alleles read at every hatch. Nothing stays hidden.',
      sprite: 32,
      effect: WorkEffect.geneRead,
      value: 1,
      costTier: 6,
      costCount: 2,
      requires: 'pedigree_office',
    ),
  ];
}
