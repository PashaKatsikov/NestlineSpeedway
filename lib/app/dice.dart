import 'dart:math';

/// Seeded random source. Seasons carry their seed so a schedule, its venues and
/// its rival field can be rebuilt exactly when a save is reloaded.
class Dice {
  Dice(this.seed) : _r = Random(seed);

  final int seed;
  final Random _r;

  int int_(int maxExclusive) => _r.nextInt(maxExclusive);

  /// Inclusive on both ends.
  int range(int minInclusive, int maxInclusive) =>
      minInclusive + _r.nextInt(maxInclusive - minInclusive + 1);

  double float() => _r.nextDouble();

  bool chance(double p) => _r.nextDouble() < p;

  T pick<T>(List<T> items) => items[_r.nextInt(items.length)];

  /// Weighted pick. [weights] must be the same length as [items] and sum > 0.
  T weighted<T>(List<T> items, List<double> weights) {
    var total = 0.0;
    for (final w in weights) {
      total += w;
    }
    var roll = _r.nextDouble() * total;
    for (var i = 0; i < items.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return items[i];
    }
    return items.last;
  }

  /// In-place Fisher–Yates.
  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = _r.nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }

  /// Picks [count] distinct entries, or all of them when the list is shorter.
  List<T> sample<T>(List<T> items, int count) {
    final copy = List<T>.of(items);
    shuffle(copy);
    return copy.take(count).toList();
  }

  static int newSeed() => DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
}
