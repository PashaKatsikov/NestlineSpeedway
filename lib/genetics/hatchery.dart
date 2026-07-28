import '../core/rng.dart';
import 'genome.dart';
import 'locus.dart';
import 'pedigree.dart';
import 'racer.dart';

/// Egg tiers. The tier of the egg a pairing is bred into decides how wide the
/// allele pool is and how much mutation noise creeps in, so eggs are the real
/// bridge between racing well and breeding well.
class EggTier {
  const EggTier(this.index, this.name, this.blurb, this.mutation, this.bias);

  final int index;
  final String name;
  final String blurb;

  /// Per-allele mutation rate for a pairing bred into this tier.
  final double mutation;

  /// How far the tier lifts recessive alleles when it has to invent one.
  final double bias;

  static const List<EggTier> all = [
    EggTier(
      0,
      'Plain',
      'A working egg. Nothing gained, nothing lost.',
      0.02,
      0.0,
    ),
    EggTier(1, 'Speckled', 'Steadier hatch. Slightly kinder odds.', 0.02, 0.1),
    EggTier(
      2,
      'Burnished',
      'Warm shell. Traits carry through cleanly.',
      0.015,
      0.2,
    ),
    EggTier(
      3,
      'Gilded',
      'Rare stock. Recessives surface more often.',
      0.015,
      0.35,
    ),
    EggTier(4, 'Prism', 'Unstable and generous in equal measure.', 0.05, 0.5),
    EggTier(
      5,
      'Crystal',
      'Almost no drift. What you plan is what you get.',
      0.005,
      0.45,
    ),
    EggTier(6, 'Heirloom', 'The best shell on the circuit.', 0.01, 0.7),
  ];

  static EggTier at(int i) => all[i.clamp(0, all.length - 1)];
}

/// Breeding, naming and founder generation.
class Hatchery {
  Hatchery._();

  static const List<String> _names = [
    'Amber',
    'Bramble',
    'Clover',
    'Dottie',
    'Ember',
    'Fable',
    'Ginger',
    'Hazel',
    'Juniper',
    'Kestrel',
    'Lark',
    'Marigold',
    'Nutmeg',
    'Olive',
    'Pippin',
    'Quill',
    'Rosie',
    'Saffron',
    'Thistle',
    'Umber',
    'Vesper',
    'Willow',
    'Yarrow',
    'Zinnia',
    'Comet',
    'Dash',
    'Flint',
    'Gale',
    'Harrow',
    'Ibis',
    'Jasper',
    'Kindle',
    'Linnet',
    'Mote',
    'Nimbus',
    'Onyx',
    'Pica',
    'Rill',
    'Sorrel',
    'Tansy',
    'Vetch',
    'Wren',
    'Cinder',
    'Bunting',
    'Sparrow',
  ];

  static const List<String> _roman = [
    '',
    ' II',
    ' III',
    ' IV',
    ' V',
    ' VI',
    ' VII',
    ' VIII',
    ' IX',
    ' X',
  ];

  static int _idCounter = 0;

  static String newId() {
    _idCounter++;
    return 'r${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}$_idCounter';
  }

  /// Picks a name, appending a lineage numeral when the stable already has one.
  static String pickName(Rng rng, Iterable<String> taken) {
    final used = taken.toSet();
    final free = _names.where((n) => !used.contains(n)).toList(growable: false);
    if (free.isNotEmpty) return rng.pick(free);
    final base = rng.pick(_names);
    for (final suffix in _roman.skip(1)) {
      if (!used.contains('$base$suffix')) return '$base$suffix';
    }
    return '$base ${rng.range(11, 99)}';
  }

  /// The three birds a new stable starts with: deliberately plain, with one
  /// hidden recessive each so the player has something to discover immediately.
  static List<Racer> founders(Rng rng, Pedigree pedigree) {
    final out = <Racer>[];
    final taken = <String>[];
    for (var i = 0; i < 3; i++) {
      final genome = Genome.random(rng, recessiveBias: 0.15);
      // Guarantee at least one carried recessive on each founder.
      final locus = rng.pick(Locus.values);
      final pool = locus.alleles.length;
      genome.alleles[locus.index * 2] = 0;
      genome.alleles[locus.index * 2 + 1] = pool - 1;

      final name = pickName(rng, taken);
      taken.add(name);
      final id = newId();
      final order = pedigree.nextBirthOrder;
      pedigree.register(PedigreeNode(id: id, name: name, birthOrder: order));
      out.add(
        Racer(
          id: id,
          name: name,
          genome: genome,
          birthOrder: order,
          plume: _plumeFor(genome, rng),
          originTier: 0,
        ),
      );
    }
    return out;
  }

  /// Outside stock: a bird with no pedigree, used by Traders and events. Fresh
  /// blood is the only way to bring an inbreeding coefficient back down.
  static Racer wildStock(
    Rng rng,
    Pedigree pedigree, {
    required int grade,
    Iterable<String> taken = const [],
  }) {
    final genome = Genome.random(rng, recessiveBias: 0.1 + grade * 0.06);
    final name = pickName(rng, taken);
    final id = newId();
    final order = pedigree.nextBirthOrder;
    pedigree.register(PedigreeNode(id: id, name: name, birthOrder: order));
    return Racer(
      id: id,
      name: name,
      genome: genome,
      birthOrder: order,
      plume: _plumeFor(genome, rng),
      originTier: (grade ~/ 2).clamp(0, 3),
    );
  }

  /// Breeds [sire] with [dam] into an egg of [tier].
  static Racer breed({
    required Racer sire,
    required Racer dam,
    required EggTier tier,
    required Rng rng,
    required Pedigree pedigree,
    Iterable<String> taken = const [],
  }) {
    final genome = Genome.breed(
      sire.genome,
      dam.genome,
      rng,
      mutation: tier.mutation,
    );

    // Premium shells can rescue one locus toward a recessive the pair carries,
    // which is what turns a good egg into a planning tool rather than a lottery.
    if (tier.bias > 0 && rng.chance(tier.bias)) {
      final carried = Locus.values
          .where((l) {
            final hiddenSire = sire.genome.hidden(l);
            final hiddenDam = dam.genome.hidden(l);
            return hiddenSire != null || hiddenDam != null;
          })
          .toList(growable: false);
      if (carried.isNotEmpty) {
        final l = rng.pick(carried);
        final target = (sire.genome.hidden(l) ?? dam.genome.hidden(l))!;
        genome.alleles[l.index * 2] = target.index;
        genome.alleles[l.index * 2 + 1] = target.index;
      }
    }

    final f = pedigree.inbreedingOf(sire.id, dam.id);
    final name = pickName(rng, taken);
    final id = newId();
    final order = pedigree.nextBirthOrder;
    pedigree.register(
      PedigreeNode(
        id: id,
        name: name,
        sireId: sire.id,
        damId: dam.id,
        birthOrder: order,
      ),
    );

    return Racer(
      id: id,
      name: name,
      genome: genome,
      birthOrder: order,
      sireId: sire.id,
      damId: dam.id,
      inbreeding: f,
      originTier: tier.index,
      plume: _plumeFor(genome, rng),
    );
  }

  /// The claim clutch: three plain birds granted when a stable can no longer
  /// field a pair, so the player is never hard-locked out of the game.
  static List<Racer> claimClutch(
    Rng rng,
    Pedigree pedigree, {
    Iterable<String> taken = const [],
  }) {
    final used = <String>[...taken];
    return List.generate(3, (_) {
      final r = wildStock(rng, pedigree, grade: 0, taken: used);
      used.add(r.name);
      return r;
    });
  }

  /// Feather plate used for silks. Anchored to the plumage allele so silks read
  /// as a genetic trait rather than a random skin.
  static int _plumeFor(Genome g, Rng rng) {
    final base = switch (g.expressedIndex(Locus.plumage)) {
      0 => [4, 5, 9, 13],
      1 => [1, 11, 12, 15],
      2 => [0, 3, 8, 10],
      _ => [2, 6, 7, 14],
    };
    return rng.pick(base);
  }

  /// Predicted offspring distribution for a pairing, per locus. This is the
  /// planning tool the whole meta game runs on: it shows what a pairing *can*
  /// produce, using only alleles the player has actually discovered.
  static Map<Locus, Map<int, double>> forecast(Racer sire, Racer dam) {
    final out = <Locus, Map<int, double>>{};
    for (final l in Locus.values) {
      final sireOptions = [sire.genome.first(l), sire.genome.second(l)];
      final damOptions = [dam.genome.first(l), dam.genome.second(l)];
      final counts = <int, double>{};
      for (final a in sireOptions) {
        for (final b in damOptions) {
          final expressed = a <= b ? a : b;
          counts[expressed] = (counts[expressed] ?? 0) + 0.25;
        }
      }
      out[l] = counts;
    }
    return out;
  }

  /// Chance that a pairing produces a homozygote at [l], i.e. a pure trait.
  static double pureChance(Racer sire, Racer dam, Locus l) {
    final sireOptions = [sire.genome.first(l), sire.genome.second(l)];
    final damOptions = [dam.genome.first(l), dam.genome.second(l)];
    var hits = 0;
    for (final a in sireOptions) {
      for (final b in damOptions) {
        if (a == b) hits++;
      }
    }
    return hits / 4.0;
  }
}
