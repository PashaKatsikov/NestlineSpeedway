import '../core/rng.dart';
import '../genetics/locus.dart';
import 'items.dart';

/// One line of a Trader's stock.
class StockLine {
  StockLine({
    required this.kind,
    required this.price,
    this.tackId,
    this.consumableId,
    this.locus,
    this.sold = false,
  });

  final StockKind kind;
  final int price;
  final String? tackId;
  final String? consumableId;

  /// For gene reads: which locus is being read.
  final Locus? locus;

  bool sold;

  String get title => switch (kind) {
    StockKind.tack => Tack.byId(tackId ?? '')?.name ?? 'Tack',
    StockKind.consumable =>
      Consumable.byId(consumableId ?? '')?.name ?? 'Supply',
    StockKind.geneRead => 'Gene Read: ${locus?.label ?? ''}',
  };

  String get blurb => switch (kind) {
    StockKind.tack => Tack.byId(tackId ?? '')?.blurb ?? '',
    StockKind.consumable => Consumable.byId(consumableId ?? '')?.blurb ?? '',
    StockKind.geneRead =>
      'Reads the hidden allele your racer carries at this locus.',
  };
}

enum StockKind { tack, consumable, geneRead }

/// Builds a Trader's stock. Deterministic for a given node so leaving the screen
/// and coming back cannot reroll the shop.
class Trader {
  Trader._();

  static List<StockLine> stock({
    required int seed,
    required int grade,
    required double priceMultiplier,
  }) {
    final rng = Rng(seed);
    final lines = <StockLine>[];

    int price(int base) => (base * priceMultiplier).round().clamp(5, 9999);

    // Tack: two commons early, shifting to fine and champion gear with grade.
    final tackGrades = <int>[0, grade >= 2 ? 1 : 0, grade >= 4 ? 2 : 1];
    for (final g in tackGrades) {
      final pool = Tack.ofGrade(g);
      final pick = rng.pick(pool);
      lines.add(
        StockLine(
          kind: StockKind.tack,
          tackId: pick.id,
          price: price(pick.price),
        ),
      );
    }

    // Two feeds and one remedy or supplement.
    for (final feed in rng.sample(Consumable.ofKind(ConsumableKind.feed), 2)) {
      lines.add(
        StockLine(
          kind: StockKind.consumable,
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
        StockLine(
          kind: StockKind.consumable,
          consumableId: extra.id,
          price: price(extra.price),
        ),
      );
    }

    // A gene read is always on offer; it is the only way to see a carried
    // allele without waiting for a homozygote to turn up.
    lines.add(
      StockLine(
        kind: StockKind.geneRead,
        locus: rng.pick(Locus.values),
        price: price(90 + grade * 15),
      ),
    );

    return lines;
  }
}

enum TrainingKind { intervals, longGallop, schooling, geneRead, recovery }

class TrainingOption {
  const TrainingOption({
    required this.kind,
    required this.title,
    required this.blurb,
    required this.xp,
    required this.fatigue,
    required this.fatigueRelief,
    this.locus,
  });

  final TrainingKind kind;
  final String title;
  final String blurb;
  final int xp;
  final int fatigue;
  final int fatigueRelief;
  final Locus? locus;

  static List<TrainingOption> offer({required int seed, required int bonus}) {
    final rng = Rng(seed);
    final scale = 1 + bonus;
    return [
      TrainingOption(
        kind: TrainingKind.intervals,
        title: 'Interval Work',
        blurb: 'Short repeats on the gallops. Solid, tiring, dependable.',
        xp: 45 * scale,
        fatigue: 12,
        fatigueRelief: 0,
      ),
      TrainingOption(
        kind: TrainingKind.longGallop,
        title: 'Long Gallop',
        blurb: 'Everything you have, over everything she has.',
        xp: 85 * scale,
        fatigue: 30,
        fatigueRelief: 0,
      ),
      TrainingOption(
        kind: TrainingKind.schooling,
        title: 'Schooling',
        blurb: 'Corners, lanes and manners. Light on the legs.',
        xp: 30 * scale,
        fatigue: 0,
        fatigueRelief: 10,
      ),
      TrainingOption(
        kind: TrainingKind.geneRead,
        title: 'Watch Her Closely',
        blurb: 'A day of observation reveals one carried allele.',
        xp: 15 * scale,
        fatigue: 0,
        fatigueRelief: 0,
        locus: rng.pick(Locus.values),
      ),
      TrainingOption(
        kind: TrainingKind.recovery,
        title: 'Easy Day',
        blurb: 'No work at all. She comes back fresh.',
        xp: 0,
        fatigue: 0,
        fatigueRelief: 45,
      ),
    ];
  }
}
