import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/rng.dart';
import '../race/track.dart';

enum NodeKind {
  sprint,
  endurance,
  steeplechase,
  duel,
  training,
  trader,
  rest,
  grandPrix,
}

extension NodeKindInfo on NodeKind {
  String get label => switch (this) {
    NodeKind.sprint => 'Sprint',
    NodeKind.endurance => 'Endurance',
    NodeKind.steeplechase => 'Steeplechase',
    NodeKind.duel => 'Rival Duel',
    NodeKind.training => 'Training',
    NodeKind.trader => 'Trader',
    NodeKind.rest => 'Rest',
    NodeKind.grandPrix => 'Grand Prix',
  };

  String get blurb => switch (this) {
    NodeKind.sprint => 'Short and fast. Small purse, small risk.',
    NodeKind.endurance => 'Long haul. Good money if your wind holds.',
    NodeKind.steeplechase => 'Obstacles everywhere. Grip or grief.',
    NodeKind.duel => 'One rival, no field, proper stakes and proper tack.',
    NodeKind.training => 'No race. Spend the day improving one thing.',
    NodeKind.trader => 'Buy tack, feed and gene reads.',
    NodeKind.rest => 'Clear fatigue and treat an injury.',
    NodeKind.grandPrix => 'The season finale. A champion is waiting.',
  };

  bool get isRace => switch (this) {
    NodeKind.sprint ||
    NodeKind.endurance ||
    NodeKind.steeplechase ||
    NodeKind.duel ||
    NodeKind.grandPrix => true,
    _ => false,
  };

  IconData get icon => switch (this) {
    NodeKind.sprint => Icons.flag,
    NodeKind.endurance => Icons.timeline,
    NodeKind.steeplechase => Icons.grass,
    NodeKind.duel => Icons.sports_kabaddi,
    NodeKind.training => Icons.fitness_center,
    NodeKind.trader => Icons.storefront,
    NodeKind.rest => Icons.bedtime,
    NodeKind.grandPrix => Icons.emoji_events,
  };

  Color get tint => switch (this) {
    NodeKind.sprint => Palette.momentum,
    NodeKind.endurance => Palette.distance,
    NodeKind.steeplechase => Palette.ember,
    NodeKind.duel => Palette.bad,
    NodeKind.training => Palette.stamina,
    NodeKind.trader => Palette.amber,
    NodeKind.rest => Palette.inkSoft,
    NodeKind.grandPrix => Palette.amber,
  };

  /// Laps run at this event type.
  int get laps => switch (this) {
    NodeKind.sprint => 1,
    NodeKind.endurance => 2,
    NodeKind.grandPrix => 3,
    _ => 1,
  };

  /// Base purse before grade and placement multipliers.
  int get purse => switch (this) {
    NodeKind.sprint => 70,
    NodeKind.endurance => 130,
    NodeKind.steeplechase => 110,
    NodeKind.duel => 180,
    NodeKind.grandPrix => 320,
    _ => 0,
  };
}

class SeasonNode {
  SeasonNode({
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
  final NodeKind kind;
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

  static SeasonNode fromJson(Map<String, dynamic> j) => SeasonNode(
    id: j['id'] as int,
    row: j['r'] as int,
    col: j['c'] as int,
    kind: NodeKind.values[j['k'] as int],
    venueId: j['v'] as String,
    next: (j['n'] as List<dynamic>).cast<int>().toList(),
  );
}

/// The season schedule: a small directed graph the player walks left to right.
/// Every row is a choice, and the point of the choice is that a Trader you skip
/// is tack you never get.
class SeasonMap {
  SeasonMap(this.nodes, this.rows);

  final List<SeasonNode> nodes;
  final int rows;

  SeasonNode byId(int id) => nodes.firstWhere((n) => n.id == id);

  List<SeasonNode> inRow(int row) =>
      nodes.where((n) => n.row == row).toList(growable: false)
        ..sort((a, b) => a.col.compareTo(b.col));

  List<SeasonNode> get starts => inRow(0);

  SeasonNode get finale => nodes.last;

  Map<String, dynamic> toJson() => {
    'rows': rows,
    'nodes': nodes.map((n) => n.toJson()).toList(),
  };

  static SeasonMap fromJson(Map<String, dynamic> j) => SeasonMap(
    (j['nodes'] as List<dynamic>)
        .map((e) => SeasonNode.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    j['rows'] as int,
  );

  /// Builds a schedule of [rows] rows. Row 0 is always a single opening sprint
  /// so a season starts the same way every time, and the last row is always the
  /// Grand Prix.
  static SeasonMap generate(Rng rng, {int rows = 12, int grade = 0}) {
    final nodes = <SeasonNode>[];
    var nextId = 0;
    final rowNodes = <List<SeasonNode>>[];

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
      final list = <SeasonNode>[];

      for (var col = 0; col < count; col++) {
        final kind = isFirst
            ? NodeKind.sprint
            : isLast
            ? NodeKind.grandPrix
            : _kindFor(row, rows, rng);
        final node = SeasonNode(
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

    return SeasonMap(nodes, rows);
  }

  static NodeKind _kindFor(int row, int rows, Rng rng) {
    final phase = row / (rows - 1);
    // Traders and Rests cluster mid-season; duels appear once the field is warm.
    final kinds = <NodeKind>[
      NodeKind.sprint,
      NodeKind.endurance,
      NodeKind.steeplechase,
      NodeKind.trader,
      NodeKind.rest,
      NodeKind.training,
      NodeKind.duel,
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
