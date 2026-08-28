import 'package:nestline_circuit/app/dice.dart';
import 'package:nestline_circuit/blood/locus.dart';
import 'package:nestline_circuit/campaign/kit.dart';

/// One line of a Trader's stock.
class StallLine {
  StallLine({
    required this.kind,
    required this.price,
    this.tackId,
    this.consumableId,
    this.locus,
    this.sold = false,
  });

  final StallKind kind;
  final int price;
  final String? tackId;
  final String? consumableId;

  /// For gene reads: which locus is being read.
  final Locus? locus;

  bool sold;

  String get title => switch (kind) {
    StallKind.tack => Tack.byId(tackId ?? '')?.name ?? 'Tack',
    StallKind.consumable =>
      Consumable.byId(consumableId ?? '')?.name ?? 'Supply',
    StallKind.geneRead => 'Gene Read: ${locus?.label ?? ''}',
  };

  String get blurb => switch (kind) {
    StallKind.tack => Tack.byId(tackId ?? '')?.blurb ?? '',
    StallKind.consumable => Consumable.byId(consumableId ?? '')?.blurb ?? '',
    StallKind.geneRead =>
      'Reads the hidden allele your racer carries at this locus.',
  };
}

enum StallKind { tack, consumable, geneRead }

/// Builds a Trader's stock. Deterministic for a given node so leaving the screen
/// and coming back cannot reroll the shop.
class Trader {
  Trader._();

  static List<StallLine> stock({
    required int seed,
    required int grade,
    required double priceMultiplier,
  }) {
    final rng = Dice(seed);
    final lines = <StallLine>[];

    int price(int base) => (base * priceMultiplier).round().clamp(5, 9999);

    // Tack: two commons early, shifting to fine and champion gear with grade.
    final tackGrades = <int>[0, grade >= 2 ? 1 : 0, grade >= 4 ? 2 : 1];
    for (final g in tackGrades) {
      final pool = Tack.ofGrade(g);
      final pick = rng.pick(pool);
      lines.add(
        StallLine(
          kind: StallKind.tack,
          tackId: pick.id,
          price: price(pick.price),
        ),
      );
    }

    // Two feeds and one remedy or supplement.
    for (final feed in rng.sample(Consumable.ofKind(ConsumableKind.feed), 2)) {
      lines.add(
        StallLine(
          kind: StallKind.consumable,
          consumableId: feed.id,
          price: price(feed.price),
        ),
      );
    }
    final extras = [
      ...Consumable.ofKind(ConsumableKind.remedy),
      ...Consumable.ofKind(ConsumableKind.supplement),
    ];
    for (final extra in rng.sample(extras, 2)) {
      lines.add(
        StallLine(
          kind: StallKind.consumable,
          consumableId: extra.id,
          price: price(extra.price),
        ),
      );
    }

    // A gene read is always on offer; it is the only way to see a carried
    // allele without waiting for a homozygote to turn up.
    lines.add(
      StallLine(
        kind: StallKind.geneRead,
        locus: rng.pick(Locus.values),
        price: price(90 + grade * 15),
      ),
    );

    return lines;
  }
}

enum DrillKind { intervals, longGallop, schooling, geneRead, recovery }

class DrillOption {
  const DrillOption({
    required this.kind,
    required this.title,
    required this.blurb,
    required this.xp,
    required this.fatigue,
    required this.fatigueRelief,
    this.locus,
  });

  final DrillKind kind;
  final String title;
  final String blurb;
  final int xp;
  final int fatigue;
  final int fatigueRelief;
  final Locus? locus;

  static List<DrillOption> offer({required int seed, required int bonus}) {
    final rng = Dice(seed);
    final scale = 1 + bonus;
    return [
      DrillOption(
        kind: DrillKind.intervals,
        title: 'Interval Work',
        blurb: 'Short repeats on the gallops. Solid, tiring, dependable.',
        xp: 45 * scale,
        fatigue: 12,
        fatigueRelief: 0,
      ),
      DrillOption(
        kind: DrillKind.longGallop,
        title: 'Long Gallop',
        blurb: 'Everything you have, over everything she has.',
        xp: 85 * scale,
        fatigue: 30,
        fatigueRelief: 0,
      ),
      DrillOption(
        kind: DrillKind.schooling,
        title: 'Schooling',
        blurb: 'Corners, lanes and manners. Light on the legs.',
        xp: 30 * scale,
        fatigue: 0,
        fatigueRelief: 10,
      ),
      DrillOption(
        kind: DrillKind.geneRead,
        title: 'Watch Her Closely',
        blurb: 'A day of observation reveals one carried allele.',
        xp: 15 * scale,
        fatigue: 0,
        fatigueRelief: 0,
        locus: rng.pick(Locus.values),
      ),
      DrillOption(
        kind: DrillKind.recovery,
        title: 'Easy Day',
        blurb: 'No work at all. She comes back fresh.',
        xp: 0,
        fatigue: 0,
        fatigueRelief: 45,
      ),
    ];
  }
}
