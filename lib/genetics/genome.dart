import '../core/rng.dart';
import 'locus.dart';

/// A diploid genome: two alleles at each of the six loci, stored flat as
/// `[locus0_a, locus0_b, locus1_a, locus1_b, ...]` in [Locus.values] order.
class Genome {
  Genome(this.alleles)
    : assert(
        alleles.length == Locus.values.length * 2,
        'a genome needs two alleles per locus',
      );

  /// Mutation rate applied per allele on every inheritance event.
  static const double mutationRate = 0.02;

  final List<int> alleles;

  int first(Locus l) => alleles[l.index * 2];
  int second(Locus l) => alleles[l.index * 2 + 1];

  /// The dominant of the two alleles wins, and dominance is the allele's index,
  /// so the expressed allele is simply the lower of the pair.
  int expressedIndex(Locus l) {
    final a = first(l);
    final b = second(l);
    return a <= b ? a : b;
  }

  Allele expressed(Locus l) => Alleles.at(l, expressedIndex(l));

  bool isHomozygous(Locus l) => first(l) == second(l);

  /// True when the bird shows a dominant phenotype while silently holding a
  /// recessive allele — the state the whole breeding programme runs on.
  bool isCarrier(Locus l) => !isHomozygous(l);

  /// The allele being carried but not expressed, if any.
  Allele? hidden(Locus l) {
    if (isHomozygous(l)) return null;
    final a = first(l);
    final b = second(l);
    return Alleles.at(l, a > b ? a : b);
  }

  /// Loci where the bird is homozygous, i.e. showing a pure trait.
  List<Locus> get pureLoci =>
      Locus.values.where(isHomozygous).toList(growable: false);

  /// Loci carrying an unexpressed allele — the ones a Gene Read can open up.
  List<Locus> get hiddenLoci =>
      Locus.values.where((l) => !isHomozygous(l)).toList(growable: false);

  /// Pedigree notation, e.g. `Lb DE Tw PP Cn hh`.
  String get notation => Locus.values
      .map((l) {
        final a = Alleles.at(l, first(l)).code;
        final b = Alleles.at(l, second(l)).code;
        // Dominant letter first, matching how breeders write pairs.
        return first(l) <= second(l) ? '$a$b' : '$b$a';
      })
      .join(' ');

  Genome copy() => Genome(List<int>.of(alleles));

  List<int> toJson() => List<int>.of(alleles);

  static Genome fromJson(List<dynamic> raw) =>
      Genome(raw.map((e) => e as int).toList());

  /// Meiosis: one allele drawn at random from each parent per locus, with an
  /// independent mutation roll per inherited allele.
  static Genome breed(
    Genome sire,
    Genome dam,
    Rng rng, {
    double mutation = mutationRate,
  }) {
    final out = <int>[];
    for (final l in Locus.values) {
      final pool = l.alleles.length;
      var fromSire = rng.chance(0.5) ? sire.first(l) : sire.second(l);
      var fromDam = rng.chance(0.5) ? dam.first(l) : dam.second(l);
      if (rng.chance(mutation)) fromSire = rng.int_(pool);
      if (rng.chance(mutation)) fromDam = rng.int_(pool);
      out.add(fromSire);
      out.add(fromDam);
    }
    return Genome(out);
  }

  /// Random genome. [recessiveBias] pushes the draw toward recessive alleles,
  /// which is how higher-tier eggs and later-grade rival stock get better genes.
  static Genome random(Rng rng, {double recessiveBias = 0.0}) {
    final out = <int>[];
    for (final l in Locus.values) {
      final n = l.alleles.length;
      for (var copy = 0; copy < 2; copy++) {
        final weights = <double>[];
        for (var i = 0; i < n; i++) {
          // Dominant alleles are common in the wild population; the bias term
          // lifts the tail so bred and premium stock can surface rarities.
          final base = (n - i).toDouble();
          final tail = (i + 1) * recessiveBias * n;
          weights.add(base + tail);
        }
        out.add(rng.weighted(List.generate(n, (i) => i), weights));
      }
    }
    return Genome(out);
  }

  /// A deliberately plain genome for the claim clutch handed out when a stable
  /// runs dry.
  static Genome plain() =>
      Genome(Locus.values.expand((l) => const [0, 0]).toList());
}

/// A pair of pure traits that together unlock an extra command.
class Synergy {
  const Synergy(
    this.a,
    this.aIndex,
    this.b,
    this.bIndex,
    this.command,
    this.name,
    this.blurb,
  );

  final Locus a;
  final int aIndex;
  final Locus b;
  final int bIndex;
  final String command;
  final String name;
  final String blurb;

  bool matches(Genome g) =>
      g.isHomozygous(a) &&
      g.first(a) == aIndex &&
      g.isHomozygous(b) &&
      g.first(b) == bIndex;

  String get requirement {
    final ac = Alleles.at(a, aIndex).code;
    final bc = Alleles.at(b, bIndex).code;
    return '$ac$ac + $bc$bc';
  }
}

/// The authored synergy table. Every entry needs two simultaneous homozygous
/// traits, which is the deepest thing the breeding programme can be asked for.
class Synergies {
  Synergies._();

  static const List<Synergy> all = [
    Synergy(
      Locus.stride,
      2,
      Locus.temper,
      2,
      'thunder_hop',
      'Thunder Hop',
      'Bounding gait with no restraint at all.',
    ),
    Synergy(
      Locus.wind,
      2,
      Locus.comb,
      2,
      'perpetual',
      'Perpetual Motion',
      'A tiny tank fed by an enormous crown.',
    ),
    Synergy(
      Locus.plumage,
      3,
      Locus.comb,
      2,
      'kaleidoscope',
      'Kaleidoscope',
      'Impossible plumage, impossible energy.',
    ),
    Synergy(
      Locus.claw,
      2,
      Locus.stride,
      1,
      'pivot_master',
      'Pivot Master',
      'Short steps hooked into every corner.',
    ),
    Synergy(
      Locus.temper,
      0,
      Locus.wind,
      0,
      'diesel',
      'Diesel',
      'Unshakeable temper on a bottomless tank.',
    ),
    Synergy(
      Locus.plumage,
      0,
      Locus.claw,
      1,
      'all_weather',
      'All Weather',
      'Speckled hardiness on fine, searching toes.',
    ),
    Synergy(
      Locus.stride,
      0,
      Locus.temper,
      1,
      'long_bomb',
      'Long Bomb',
      'A reaching gait and the will to use it early.',
    ),
    Synergy(
      Locus.wind,
      1,
      Locus.plumage,
      2,
      'clockwork',
      'Clockwork',
      'Even wind, clean line, no wasted motion.',
    ),
    Synergy(
      Locus.comb,
      1,
      Locus.claw,
      2,
      'sleight',
      'Sleight',
      'Reads the corner and hooks it before anyone moves.',
    ),
    Synergy(
      Locus.temper,
      2,
      Locus.claw,
      0,
      'runaway',
      'Runaway',
      'All that wildness finally has something to push against.',
    ),
    Synergy(
      Locus.plumage,
      1,
      Locus.wind,
      0,
      'showstopper',
      'Showstopper',
      'A gold bird with the lungs to milk the crowd all race.',
    ),
    Synergy(
      Locus.stride,
      0,
      Locus.claw,
      0,
      'freight',
      'Freight',
      'Long stride planted on broad pads. Immovable.',
    ),
  ];

  static List<Synergy> matching(Genome g) =>
      all.where((s) => s.matches(g)).toList(growable: false);
}

/// Everything a genome resolves to: the stat block plus the command list the
/// racer takes onto the track.
class Phenotype {
  Phenotype({
    required this.staminaMax,
    required this.stride,
    required this.effort,
    required this.grip,
    required this.control,
    required this.recovery,
    required this.hand,
    required this.momentumGain,
    required this.commandIds,
    required this.expressedTraits,
    required this.pureTraits,
    required this.synergies,
  });

  final int staminaMax;
  final int stride;
  final int effort;
  final int grip;
  final int control;
  final int recovery;
  final int hand;
  final int momentumGain;

  /// Deck contents, in a stable order so the UI does not jump around.
  final List<String> commandIds;

  final List<Allele> expressedTraits;
  final List<Allele> pureTraits;
  final List<Synergy> synergies;

  /// Rough single-number quality used for sorting and rival scaling.
  int get rating =>
      staminaMax ~/ 2 +
      stride * 6 +
      effort * 8 +
      grip * 3 +
      control * 3 +
      recovery * 2 +
      pureTraits.length * 5 +
      synergies.length * 10;

  /// Core commands every racer knows regardless of genome.
  static const List<String> coreCommands = [
    'push',
    'push',
    'steady',
    'steady',
    'draft',
    'cut_inside',
    'hold_line',
  ];

  static Phenotype of(Genome g) {
    var mods = Alleles.baseline;
    final expressed = <Allele>[];
    final pure = <Allele>[];
    final commands = <String>[...coreCommands];

    for (final l in Locus.values) {
      final a = g.expressed(l);
      expressed.add(a);
      mods = mods + a.mods;
      commands.add(a.traitCommand);
      if (g.isHomozygous(l)) {
        pure.add(a);
        mods = mods + a.pureMods;
        commands.add(a.signatureCommand);
      }
    }

    final syn = Synergies.matching(g);
    for (final s in syn) {
      commands.add(s.command);
    }

    return Phenotype(
      staminaMax: mods.stamina.clamp(12, 200),
      stride: mods.stride.clamp(1, 12),
      effort: mods.effort.clamp(1, 8),
      grip: mods.grip.clamp(0, 8),
      control: mods.control.clamp(-3, 8),
      recovery: mods.recovery.clamp(1, 20),
      hand: mods.hand.clamp(3, 8),
      momentumGain: mods.momentumGain,
      commandIds: commands,
      expressedTraits: expressed,
      pureTraits: pure,
      synergies: syn,
    );
  }
}
