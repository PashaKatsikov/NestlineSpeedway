import 'package:flutter/material.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/dice.dart';
import 'package:nestline_circuit/heat/track.dart';

enum StopKind {
  sprint,
  endurance,
  steeplechase,
  duel,
  training,
  trader,
  rest,
  grandPrix,
}

extension NodeKindInfo on StopKind {
  String get label => switch (this) {
    StopKind.sprint => 'Sprint',
    StopKind.endurance => 'Endurance',
    StopKind.steeplechase => 'Steeplechase',
    StopKind.duel => 'Rival Duel',
    StopKind.training => 'Training',
    StopKind.trader => 'Trader',
    StopKind.rest => 'Rest',
    StopKind.grandPrix => 'Grand Prix',
  };

  String get blurb => switch (this) {
    StopKind.sprint => 'Short and fast. Small purse, small risk.',
    StopKind.endurance => 'Long haul. Good money if your wind holds.',
    StopKind.steeplechase => 'Obstacles everywhere. Grip or grief.',
    StopKind.duel => 'One rival, no field, proper stakes and proper tack.',
    StopKind.training => 'No race. Spend the day improving one thing.',
    StopKind.trader => 'Buy tack, feed and gene reads.',
    StopKind.rest => 'Clear fatigue and treat an injury.',
    StopKind.grandPrix => 'The season finale. A champion is waiting.',
  };

  bool get isRace => switch (this) {
    StopKind.sprint ||
    StopKind.endurance ||
    StopKind.steeplechase ||
    StopKind.duel ||
    StopKind.grandPrix => true,
    _ => false,
  };

  IconData get icon => switch (this) {
    StopKind.sprint => Icons.flag,
    StopKind.endurance => Icons.timeline,
    StopKind.steeplechase => Icons.grass,
    StopKind.duel => Icons.sports_kabaddi,
    StopKind.training => Icons.fitness_center,
    StopKind.trader => Icons.storefront,
    StopKind.rest => Icons.bedtime,
    StopKind.grandPrix => Icons.emoji_events,
  };

  Color get tint => switch (this) {
    StopKind.sprint => Pigment.momentum,
    StopKind.endurance => Pigment.distance,
    StopKind.steeplechase => Pigment.ember,
    StopKind.duel => Pigment.bad,
    StopKind.training => Pigment.stamina,
    StopKind.trader => Pigment.amber,
    StopKind.rest => Pigment.inkSoft,
    StopKind.grandPrix => Pigment.amber,
  };

  /// Laps run at this event type.
  int get laps => switch (this) {
    StopKind.sprint => 1,
    StopKind.endurance => 2,
    StopKind.grandPrix => 3,
    _ => 1,
  };

  /// Base purse before grade and placement multipliers.
  int get purse => switch (this) {
    StopKind.sprint => 70,
    StopKind.endurance => 130,
    StopKind.steeplechase => 110,
    StopKind.duel => 180,
    StopKind.grandPrix => 320,
    _ => 0,
  };
}

class CircuitStop {
  CircuitStop({
    required this.id,
    required this.row,
    required this.col,
    required this.kind,
    required this.venueId,
    required this.next,
  });

  final int id;
  final int row;
  final int col;
  final StopKind kind;
  final String venueId;
  final List<int> next;

  Venue get venue => Venue.byId(venueId);

  Map<String, dynamic> toJson() => {
    'id': id,
    'r': row,
    'c': col,
    'k': kind.index,
    'v': venueId,
    'n': next,
  };

  static CircuitStop fromJson(Map<String, dynamic> j) => CircuitStop(
    id: j['id'] as int,
    row: j['r'] as int,
    col: j['c'] as int,
    kind: StopKind.values[j['k'] as int],
    venueId: j['v'] as String,
    next: (j['n'] as List<dynamic>).cast<int>().toList(),
  );
}

/// The season schedule: a small directed graph the player walks left to right.
/// Every row is a choice, and the point of the choice is that a Trader you skip
/// is tack you never get.
class CircuitBook {
  CircuitBook(this.nodes, this.rows);

  final List<CircuitStop> nodes;
  final int rows;

  CircuitStop byId(int id) => nodes.firstWhere((n) => n.id == id);

  List<CircuitStop> inRow(int row) =>
      nodes.where((n) => n.row == row).toList(growable: false)
        ..sort((a, b) => a.col.compareTo(b.col));

  List<CircuitStop> get starts => inRow(0);

  CircuitStop get finale => nodes.last;

  Map<String, dynamic> toJson() => {
    'rows': rows,
    'nodes': nodes.map((n) => n.toJson()).toList(),
  };

  static CircuitBook fromJson(Map<String, dynamic> j) => CircuitBook(
    (j['nodes'] as List<dynamic>)
        .map((e) => CircuitStop.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    j['rows'] as int,
  );

  /// Builds a schedule of [rows] rows. Row 0 is always a single opening sprint
  /// so a season starts the same way every time, and the last row is always the
  /// Grand Prix.
  static CircuitBook generate(Dice rng, {int rows = 12, int grade = 0}) {
    final nodes = <CircuitStop>[];
    var nextId = 0;
    final rowNodes = <List<CircuitStop>>[];

    // Venue rotation: shuffled once so a season has its own character, with the
    // Grand Prix always at Midnight Oval.
    final pool = Venue.all
        .where((v) => v.id != 'midnight')
        .map((v) => v.id)
        .toList(growable: false);
    final rotation = rng.sample(pool, pool.length);

    String venueFor(int row) => rotation[row % rotation.length];

    for (var row = 0; row < rows; row++) {
      final isFirst = row == 0;
      final isLast = row == rows - 1;
      final count = isFirst || isLast ? 1 : rng.range(2, 3);
      final list = <CircuitStop>[];

      for (var col = 0; col < count; col++) {
        final kind = isFirst
            ? StopKind.sprint
            : isLast
            ? StopKind.grandPrix
            : _kindFor(row, rows, rng);
        final node = CircuitStop(
          id: nextId++,
          row: row,
          col: col,
          kind: kind,
          venueId: isLast ? 'midnight' : venueFor(row + col),
          next: [],
        );
        list.add(node);
        nodes.add(node);
      }
      rowNodes.add(list);
    }

    // Wire rows together, guaranteeing every node is reachable and every node
    // leads somewhere.
    for (var row = 0; row < rows - 1; row++) {
      final from = rowNodes[row];
      final to = rowNodes[row + 1];
      for (var i = 0; i < from.length; i++) {
        final anchor = to.isEmpty
            ? 0
            : ((i / from.length) * to.length).floor().clamp(0, to.length - 1);
        from[i].next.add(to[anchor].id);
        // A second branch when there is somewhere else sensible to go.
        if (to.length > 1 && rng.chance(0.55)) {
          final alt = (anchor + (rng.chance(0.5) ? 1 : -1)).clamp(
            0,
            to.length - 1,
          );
          if (!from[i].next.contains(to[alt].id)) {
            from[i].next.add(to[alt].id);
          }
        }
      }
      // Make sure nothing in the next row is orphaned.
      for (final target in to) {
        final reachable = from.any((f) => f.next.contains(target.id));
        if (!reachable) {
          final source = from[rng.int_(from.length)];
          source.next.add(target.id);
        }
      }
    }

    return CircuitBook(nodes, rows);
  }

  static StopKind _kindFor(int row, int rows, Dice rng) {
    final phase = row / (rows - 1);
    // Traders and Rests cluster mid-season; duels appear once the field is warm.
    final kinds = <StopKind>[
      StopKind.sprint,
      StopKind.endurance,
      StopKind.steeplechase,
      StopKind.trader,
      StopKind.rest,
      StopKind.training,
      StopKind.duel,
    ];
    final weights = <double>[
      3.0,
      phase > 0.25 ? 2.6 : 1.0,
      phase > 0.2 ? 2.2 : 0.8,
      2.0,
      phase > 0.3 ? 2.0 : 0.9,
      1.6,
      phase > 0.35 ? 1.8 : 0.2,
    ];
    return rng.weighted(kinds, weights);
  }
}
