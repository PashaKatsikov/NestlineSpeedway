import '../core/sprites.dart';
import '../genetics/locus.dart';
import '../race/status.dart';

/// Persistent race gear. A bird can carry three pieces, so tack is a real build
/// decision rather than a pile of passive bonuses.
class Tack {
  const Tack({
    required this.id,
    required this.name,
    required this.blurb,
    required this.sprite,
    required this.grade,
    required this.price,
    this.mods = const StatMods(),
    this.grantsCommand,
    this.startStatuses = const {},
  });

  final String id;
  final String name;
  final String blurb;

  /// Index into the accessory sprite set.
  final int sprite;

  /// 0 common, 1 fine, 2 champion.
  final int grade;
  final int price;

  final StatMods mods;

  /// Adds a command to the deck for as long as the tack is equipped.
  final String? grantsCommand;

  /// Statuses applied at the start of every race.
  final Map<Status, int> startStatuses;

  String get iconPath => Sprites.tack(sprite);

  static final Map<String, Tack> _byId = {for (final t in all) t.id: t};
  static Tack? byId(String id) => _byId[id];

  static final List<Tack> all = [
    // ---------------------------------------------------------- common gear
    const Tack(
      id: 'leather_band',
      name: 'Leather Band',
      blurb: 'Plain strapping. Keeps her together over rough ground.',
      sprite: 0,
      grade: 0,
      price: 40,
      mods: StatMods(stamina: 8),
    ),
    const Tack(
      id: 'straw_hat',
      name: 'Straw Hat',
      blurb: 'Shade on a long afternoon.',
      sprite: 1,
      grade: 0,
      price: 45,
      mods: StatMods(recovery: 2),
    ),
    const Tack(
      id: 'wool_scarf',
      name: 'Wool Scarf',
      blurb: 'Warm lungs run longer.',
      sprite: 2,
      grade: 0,
      price: 50,
      mods: StatMods(stamina: 12),
    ),
    const Tack(
      id: 'brass_bell',
      name: 'Brass Bell',
      blurb: 'Rivals hear you coming, and hate it.',
      sprite: 3,
      grade: 0,
      price: 55,
      startStatuses: {Status.frenzy: 1},
    ),
    const Tack(
      id: 'grip_socks',
      name: 'Grip Socks',
      blurb: 'Unfashionable. Extremely effective in mud.',
      sprite: 4,
      grade: 0,
      price: 60,
      mods: StatMods(grip: 1),
    ),
    const Tack(
      id: 'rope_harness',
      name: 'Rope Harness',
      blurb: 'Holds her line when someone leans on her.',
      sprite: 5,
      grade: 0,
      price: 55,
      startStatuses: {Status.guard: 2},
    ),
    const Tack(
      id: 'linen_wraps',
      name: 'Linen Wraps',
      blurb: 'Supports the tendon. Steadier through corners.',
      sprite: 6,
      grade: 0,
      price: 50,
      mods: StatMods(control: 1),
    ),
    const Tack(
      id: 'tin_goggles',
      name: 'Tin Goggles',
      blurb: 'Keeps grit out of her eyes on a gravel lap.',
      sprite: 7,
      grade: 0,
      price: 60,
      mods: StatMods(grip: 1, control: 1),
    ),
    const Tack(
      id: 'clay_beads',
      name: 'Clay Beads',
      blurb: 'Something to rattle when the nerves come.',
      sprite: 8,
      grade: 0,
      price: 45,
      mods: StatMods(hand: 1),
    ),
    const Tack(
      id: 'field_ribbon',
      name: 'Field Ribbon',
      blurb: 'Won at a village meet. She remembers.',
      sprite: 9,
      grade: 0,
      price: 50,
      mods: StatMods(stride: 1),
    ),
    const Tack(
      id: 'canvas_bib',
      name: 'Canvas Bib',
      blurb: 'Number on the front, weight off the mind.',
      sprite: 10,
      grade: 0,
      price: 65,
      mods: StatMods(stamina: 6, recovery: 1),
    ),
    const Tack(
      id: 'cork_shoes',
      name: 'Cork Shoes',
      blurb: 'Light enough to lengthen the stride a touch.',
      sprite: 11,
      grade: 0,
      price: 70,
      mods: StatMods(stride: 1, control: -1),
    ),
    const Tack(
      id: 'twine_collar',
      name: 'Twine Collar',
      blurb: 'Cheap, honest, and it never breaks.',
      sprite: 12,
      grade: 0,
      price: 35,
      mods: StatMods(stamina: 5, control: 1),
    ),
    const Tack(
      id: 'dust_veil',
      name: 'Dust Veil',
      blurb: 'Breathes clean air behind the leaders.',
      sprite: 13,
      grade: 0,
      price: 60,
      startStatuses: {Status.slipstream: 1},
    ),

    // ------------------------------------------------------------ fine gear
    Tack(
      id: 'silk_silks',
      name: 'Silk Silks',
      blurb: 'Proper racing colours. The crowd pays attention.',
      sprite: 14,
      grade: 1,
      price: 120,
      mods: const StatMods(stamina: 10, recovery: 2),
      startStatuses: const {Status.frenzy: 1},
    ),
    const Tack(
      id: 'weighted_anklets',
      name: 'Weighted Anklets',
      blurb: 'Trained in them, races without them. Momentum builds fast.',
      sprite: 15,
      grade: 1,
      price: 130,
      mods: StatMods(momentumGain: 1),
    ),
    const Tack(
      id: 'copper_spurs',
      name: 'Copper Spurs',
      blurb: 'Bites into the dirt on the drive out of a corner.',
      sprite: 16,
      grade: 1,
      price: 140,
      mods: StatMods(stride: 1, grip: 1),
    ),
    const Tack(
      id: 'lamp_charm',
      name: 'Lamp Charm',
      blurb: 'Reads the track a half-second early.',
      sprite: 17,
      grade: 1,
      price: 135,
      mods: StatMods(hand: 1),
      startStatuses: {Status.focus: 1},
    ),
    const Tack(
      id: 'racing_visor',
      name: 'Racing Visor',
      blurb: 'Nothing gets in. Nothing distracts.',
      sprite: 18,
      grade: 1,
      price: 150,
      mods: StatMods(grip: 2),
    ),
    const Tack(
      id: 'quilted_vest',
      name: 'Quilted Vest',
      blurb: 'Soaks up a shoulder from a Bruiser.',
      sprite: 19,
      grade: 1,
      price: 145,
      mods: StatMods(stamina: 14),
      startStatuses: {Status.guard: 3},
    ),
    const Tack(
      id: 'polished_bit',
      name: 'Polished Bit',
      blurb: 'She listens. Corners stop being a problem.',
      sprite: 20,
      grade: 1,
      price: 155,
      mods: StatMods(control: 2),
    ),
    const Tack(
      id: 'feather_crest',
      name: 'Feather Crest',
      blurb: 'Vain, and worth it.',
      sprite: 21,
      grade: 1,
      price: 160,
      mods: StatMods(stamina: 8, stride: 1),
    ),
    const Tack(
      id: 'flint_charm',
      name: 'Flint Charm',
      blurb: 'One sharp effort held in reserve.',
      sprite: 22,
      grade: 1,
      price: 150,
      grantsCommand: 'press_on',
    ),
    const Tack(
      id: 'oiled_wraps',
      name: 'Oiled Wraps',
      blurb: 'Sheds mud and water alike.',
      sprite: 23,
      grade: 1,
      price: 140,
      startStatuses: {Status.flap: 2},
    ),
    const Tack(
      id: 'bronze_medal',
      name: 'Bronze Medal',
      blurb: 'Third at Meadowgate, and never letting it happen again.',
      sprite: 24,
      grade: 1,
      price: 125,
      mods: StatMods(recovery: 3),
    ),
    const Tack(
      id: 'lead_pace_tag',
      name: 'Pace Tag',
      blurb: 'She knows exactly how much is left.',
      sprite: 25,
      grade: 1,
      price: 165,
      grantsCommand: 'settle',
      mods: StatMods(recovery: 1),
    ),
    const Tack(
      id: 'thorn_ring',
      name: 'Thorn Ring',
      blurb: 'Runs angry. Runs fast.',
      sprite: 26,
      grade: 1,
      price: 170,
      mods: StatMods(stride: 2, stamina: -6),
    ),
    const Tack(
      id: 'sun_amulet',
      name: 'Sun Amulet',
      blurb: 'Thrives in the heat of a long straight.',
      sprite: 27,
      grade: 1,
      price: 150,
      startStatuses: {Status.composure: 2},
      mods: StatMods(stamina: 6),
    ),

    // ------------------------------------------------------- champion gear
    const Tack(
      id: 'gilded_harness',
      name: 'Gilded Harness',
      blurb: 'Made for a bird expected to win.',
      sprite: 28,
      grade: 2,
      price: 300,
      mods: StatMods(stamina: 20, stride: 1, recovery: 2),
    ),
    const Tack(
      id: 'storm_crest',
      name: 'Storm Crest',
      blurb: 'Worn by Nightjar the year nobody finished within nine strides.',
      sprite: 29,
      grade: 2,
      price: 340,
      mods: StatMods(stride: 2, momentumGain: 1),
      grantsCommand: 'front_run',
    ),
    const Tack(
      id: 'iron_shoes',
      name: 'Iron Shoes',
      blurb: 'Grip like a fence post. Nothing shifts her.',
      sprite: 30,
      grade: 2,
      price: 320,
      mods: StatMods(grip: 3, control: 1),
      startStatuses: {Status.hold: 1},
    ),
    const Tack(
      id: 'oracle_pin',
      name: 'Oracle Pin',
      blurb: 'She sees the whole race before the flag drops.',
      sprite: 31,
      grade: 2,
      price: 350,
      mods: StatMods(hand: 2),
      startStatuses: {Status.focus: 2},
    ),
    const Tack(
      id: 'deep_lung_tonic_rig',
      name: 'Tonic Rig',
      blurb: 'A little apparatus of dubious legality.',
      sprite: 32,
      grade: 2,
      price: 330,
      mods: StatMods(stamina: 28, recovery: 3),
    ),
    const Tack(
      id: 'crown_plate',
      name: 'Crown Plate',
      blurb: 'Weight of expectation, in brass.',
      sprite: 33,
      grade: 2,
      price: 360,
      mods: StatMods(effort: 1, stamina: -8),
    ),
    const Tack(
      id: 'ghost_ribbon',
      name: 'Ghost Ribbon',
      blurb: 'Nobody can hold a line against her.',
      sprite: 34,
      grade: 2,
      price: 310,
      grantsCommand: 'switchback',
      mods: StatMods(momentumGain: 1),
    ),
    const Tack(
      id: 'kings_comb',
      name: "King's Comb",
      blurb: 'Ornamental, ridiculous, and it works.',
      sprite: 35,
      grade: 2,
      price: 380,
      mods: StatMods(effort: 1, hand: 1),
    ),
    const Tack(
      id: 'ember_wraps',
      name: 'Ember Wraps',
      blurb: 'Starts every race already wound up.',
      sprite: 36,
      grade: 2,
      price: 300,
      startStatuses: {Status.frenzy: 3},
    ),
    const Tack(
      id: 'lucky_horseshoe',
      name: 'Lucky Horseshoe',
      blurb: 'A gift from a farrier who never raced a day.',
      sprite: 37,
      grade: 2,
      price: 290,
      startStatuses: {Status.secondWind: 14},
    ),
    const Tack(
      id: 'stone_talisman',
      name: 'Stone Talisman',
      blurb: 'Corners simply stop mattering.',
      sprite: 38,
      grade: 2,
      price: 320,
      mods: StatMods(control: 3),
      startStatuses: {Status.composure: 3},
    ),
    const Tack(
      id: 'prism_pendant',
      name: 'Prism Pendant',
      blurb: 'Every option, all at once.',
      sprite: 39,
      grade: 2,
      price: 370,
      grantsCommand: 'prism_run',
      mods: StatMods(hand: 1),
    ),
    const Tack(
      id: 'champion_sash',
      name: 'Champion Sash',
      blurb: 'Only ever worn once, by whoever won.',
      sprite: 40,
      grade: 2,
      price: 400,
      mods: StatMods(stamina: 16, stride: 1, control: 1, recovery: 2),
    ),
    const Tack(
      id: 'night_lantern',
      name: 'Night Lantern',
      blurb: 'Lights the Oval. Nothing surprises her.',
      sprite: 41,
      grade: 2,
      price: 340,
      mods: StatMods(hand: 1, grip: 1),
      grantsCommand: 'read_race',
    ),
  ];

  static List<Tack> ofGrade(int grade) =>
      all.where((t) => t.grade == grade).toList(growable: false);
}

enum ConsumableKind { feed, remedy, supplement }

extension ConsumableKindInfo on ConsumableKind {
  String get label => switch (this) {
    ConsumableKind.feed => 'Feed',
    ConsumableKind.remedy => 'Remedy',
    ConsumableKind.supplement => 'Supplement',
  };
}

/// Single-use items. Feed is eaten before a race, remedies fix a bird between
/// events, supplements are odds and ends found on the circuit.
class Consumable {
  const Consumable({
    required this.id,
    required this.name,
    required this.blurb,
    required this.kind,
    required this.sprite,
    required this.price,
    this.startStatuses = const {},
    this.staminaBonus = 0,
    this.raceMods = const StatMods(),
    this.healSeverity = 0,
    this.fatigueRelief = 0,
    this.xpGain = 0,
    this.grainGain = 0,
  });

  final String id;
  final String name;
  final String blurb;
  final ConsumableKind kind;
  final int sprite;
  final int price;

  final Map<Status, int> startStatuses;
  final int staminaBonus;
  final StatMods raceMods;

  /// Highest injury severity this item can clear. 0 means it heals nothing.
  final int healSeverity;

  final int fatigueRelief;
  final int xpGain;
  final int grainGain;

  String get iconPath => switch (kind) {
    ConsumableKind.feed => Sprites.feed(sprite),
    ConsumableKind.remedy => Sprites.remedy(sprite),
    ConsumableKind.supplement => Sprites.herb(sprite),
  };

  static final Map<String, Consumable> _byId = {for (final c in all) c.id: c};
  static Consumable? byId(String id) => _byId[id];

  static final List<Consumable> all = [
    // ----------------------------------------------------------------- feed
    const Consumable(
      id: 'cracked_corn',
      name: 'Cracked Corn',
      blurb: 'Ordinary fuel. Starts her with a fuller tank.',
      kind: ConsumableKind.feed,
      sprite: 0,
      price: 30,
      staminaBonus: 12,
    ),
    const Consumable(
      id: 'mixed_grain',
      name: 'Mixed Grain',
      blurb: 'Balanced. Slightly longer stride all race.',
      kind: ConsumableKind.feed,
      sprite: 1,
      price: 45,
      raceMods: StatMods(stride: 1),
    ),
    const Consumable(
      id: 'greens_bowl',
      name: 'Greens Bowl',
      blurb: 'Light on the stomach. Recovers faster.',
      kind: ConsumableKind.feed,
      sprite: 2,
      price: 40,
      raceMods: StatMods(recovery: 3),
    ),
    const Consumable(
      id: 'protein_pellets',
      name: 'Protein Pellets',
      blurb: 'Race-day standard on the Nestline circuit.',
      kind: ConsumableKind.feed,
      sprite: 3,
      price: 55,
      staminaBonus: 10,
      raceMods: StatMods(stamina: 8),
    ),
    const Consumable(
      id: 'golden_maize',
      name: 'Golden Maize',
      blurb: 'She runs wound up on this.',
      kind: ConsumableKind.feed,
      sprite: 4,
      price: 60,
      startStatuses: {Status.frenzy: 2},
    ),
    const Consumable(
      id: 'wheat_sheaf',
      name: 'Wheat Sheaf',
      blurb: 'Slow-burning. Composure for the corners.',
      kind: ConsumableKind.feed,
      sprite: 5,
      price: 50,
      startStatuses: {Status.composure: 3},
    ),
    const Consumable(
      id: 'harvest_mash',
      name: 'Harvest Mash',
      blurb: 'Everything at once. Expensive and worth it.',
      kind: ConsumableKind.feed,
      sprite: 6,
      price: 90,
      staminaBonus: 16,
      raceMods: StatMods(stride: 1, recovery: 2),
    ),
    const Consumable(
      id: 'spiced_scratch',
      name: 'Spiced Scratch',
      blurb: 'Sharpens her read of the race.',
      kind: ConsumableKind.feed,
      sprite: 7,
      price: 70,
      startStatuses: {Status.focus: 2},
      raceMods: StatMods(hand: 1),
    ),

    // -------------------------------------------------------------- remedy
    const Consumable(
      id: 'cool_bath',
      name: 'Cool Bath',
      blurb: 'Takes 40 fatigue off a tired bird.',
      kind: ConsumableKind.remedy,
      sprite: 0,
      price: 45,
      fatigueRelief: 40,
    ),
    const Consumable(
      id: 'sponge_down',
      name: 'Sponge Down',
      blurb: 'Quick freshen up. 20 fatigue.',
      kind: ConsumableKind.remedy,
      sprite: 1,
      price: 25,
      fatigueRelief: 20,
    ),
    const Consumable(
      id: 'stiff_brush',
      name: 'Stiff Brush',
      blurb: 'Clears a light knock.',
      kind: ConsumableKind.remedy,
      sprite: 2,
      price: 60,
      healSeverity: 1,
    ),
    const Consumable(
      id: 'warm_towel',
      name: 'Warm Towel',
      blurb: 'Loosens a strain and eases the legs.',
      kind: ConsumableKind.remedy,
      sprite: 3,
      price: 80,
      healSeverity: 1,
      fatigueRelief: 20,
    ),
    const Consumable(
      id: 'liniment',
      name: 'Liniment',
      blurb: 'Vet-grade. Clears a moderate injury.',
      kind: ConsumableKind.remedy,
      sprite: 4,
      price: 140,
      healSeverity: 2,
    ),
    const Consumable(
      id: 'dust_off',
      name: 'Dust Off',
      blurb: 'For grit in places grit should not be.',
      kind: ConsumableKind.remedy,
      sprite: 5,
      price: 30,
      fatigueRelief: 25,
    ),
    const Consumable(
      id: 'fine_comb',
      name: 'Fine Comb',
      blurb: 'Settles her nerves and her feathers.',
      kind: ConsumableKind.remedy,
      sprite: 6,
      price: 35,
      fatigueRelief: 15,
      xpGain: 10,
    ),
    const Consumable(
      id: 'antiseptic',
      name: 'Antiseptic Spray',
      blurb: 'Stops a split claw becoming a career.',
      kind: ConsumableKind.remedy,
      sprite: 7,
      price: 150,
      healSeverity: 2,
      fatigueRelief: 15,
    ),
    const Consumable(
      id: 'rest_cushion',
      name: 'Rest Cushion',
      blurb: 'A proper night. Clears almost everything.',
      kind: ConsumableKind.remedy,
      sprite: 8,
      price: 110,
      fatigueRelief: 70,
    ),

    // ---------------------------------------------------------- supplement
    const Consumable(
      id: 'clover_tonic',
      name: 'Clover Tonic',
      blurb: 'Steadier corners for one race.',
      kind: ConsumableKind.supplement,
      sprite: 0,
      price: 55,
      raceMods: StatMods(control: 2),
    ),
    const Consumable(
      id: 'nettle_draught',
      name: 'Nettle Draught',
      blurb: 'Unpleasant. Effective. Longer stride.',
      kind: ConsumableKind.supplement,
      sprite: 1,
      price: 65,
      raceMods: StatMods(stride: 1, stamina: -4),
    ),
    const Consumable(
      id: 'root_extract',
      name: 'Root Extract',
      blurb: 'Deepens the tank for one race.',
      kind: ConsumableKind.supplement,
      sprite: 2,
      price: 70,
      raceMods: StatMods(stamina: 20),
    ),
    const Consumable(
      id: 'thistle_powder',
      name: 'Thistle Powder',
      blurb: 'Grips anything for one race.',
      kind: ConsumableKind.supplement,
      sprite: 3,
      price: 60,
      raceMods: StatMods(grip: 2),
    ),
    const Consumable(
      id: 'bloom_syrup',
      name: 'Bloom Syrup',
      blurb: 'One more command in hand.',
      kind: ConsumableKind.supplement,
      sprite: 4,
      price: 85,
      raceMods: StatMods(hand: 1),
    ),
    const Consumable(
      id: 'iron_tincture',
      name: 'Iron Tincture',
      blurb: 'She simply refuses to tire.',
      kind: ConsumableKind.supplement,
      sprite: 5,
      price: 95,
      raceMods: StatMods(recovery: 4),
    ),
    const Consumable(
      id: 'fern_infusion',
      name: 'Fern Infusion',
      blurb: 'A whole extra effort, once.',
      kind: ConsumableKind.supplement,
      sprite: 6,
      price: 130,
      raceMods: StatMods(effort: 1),
    ),
    const Consumable(
      id: 'moss_pack',
      name: 'Moss Pack',
      blurb: 'Soothes the legs between events.',
      kind: ConsumableKind.supplement,
      sprite: 7,
      price: 40,
      fatigueRelief: 30,
    ),
    const Consumable(
      id: 'sage_bundle',
      name: 'Sage Bundle',
      blurb: 'Teaches her something about herself.',
      kind: ConsumableKind.supplement,
      sprite: 8,
      price: 75,
      xpGain: 45,
    ),
    const Consumable(
      id: 'briar_cutting',
      name: 'Briar Cutting',
      blurb: 'Sells well at the next town.',
      kind: ConsumableKind.supplement,
      sprite: 9,
      price: 20,
      grainGain: 60,
    ),
    const Consumable(
      id: 'lily_balm',
      name: 'Lily Balm',
      blurb: 'Starts her race already composed.',
      kind: ConsumableKind.supplement,
      sprite: 10,
      price: 50,
      startStatuses: {Status.composure: 4},
    ),
    const Consumable(
      id: 'ash_rub',
      name: 'Ash Rub',
      blurb: 'Guard against anyone who leans on her.',
      kind: ConsumableKind.supplement,
      sprite: 11,
      price: 55,
      startStatuses: {Status.guard: 4},
    ),
    const Consumable(
      id: 'wind_seed',
      name: 'Wind Seed',
      blurb: 'A slipstream she carries with her.',
      kind: ConsumableKind.supplement,
      sprite: 12,
      price: 60,
      startStatuses: {Status.slipstream: 2},
    ),
    const Consumable(
      id: 'sun_petal',
      name: 'Sun Petal',
      blurb: 'Opens on frenzy.',
      kind: ConsumableKind.supplement,
      sprite: 13,
      price: 65,
      startStatuses: {Status.frenzy: 3},
    ),
    const Consumable(
      id: 'stone_lichen',
      name: 'Stone Lichen',
      blurb: 'Banks a second wind for the finish.',
      kind: ConsumableKind.supplement,
      sprite: 14,
      price: 90,
      startStatuses: {Status.secondWind: 18},
    ),
    const Consumable(
      id: 'night_bloom',
      name: 'Night Bloom',
      blurb: 'Rare, and it does almost everything.',
      kind: ConsumableKind.supplement,
      sprite: 15,
      price: 160,
      raceMods: StatMods(stamina: 14, stride: 1, hand: 1),
    ),
  ];

  static List<Consumable> ofKind(ConsumableKind kind) =>
      all.where((c) => c.kind == kind).toList(growable: false);
}
