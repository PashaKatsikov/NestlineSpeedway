/// One node of the stable's family tree. Kept separate from [Runner] so a bird
/// can be retired or lost without erasing the lineage information her
/// descendants need.
class KinNode {
  const KinNode({
    required this.id,
    required this.name,
    this.sireId,
    this.damId,
    required this.birthOrder,
  });

  final String id;
  final String name;
  final String? sireId;
  final String? damId;

  /// Monotonic hatch counter. Used to orient the kinship recursion — a bird can
  /// only descend from birds with a lower birth order.
  final int birthOrder;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (sireId != null) 'sire': sireId,
    if (damId != null) 'dam': damId,
    'n': birthOrder,
  };

  static KinNode fromJson(Map<String, dynamic> j) => KinNode(
    id: j['id'] as String,
    name: j['name'] as String? ?? 'Unknown',
    sireId: j['sire'] as String?,
    damId: j['dam'] as String?,
    birthOrder: j['n'] as int? ?? 0,
  );
}

/// The stable's family tree, and the kinship maths on top of it.
///
/// Inbreeding is computed with the standard recursive tabular method:
/// the kinship coefficient of two birds is the average of the kinship of one
/// bird's parents with the other, and a bird's inbreeding coefficient is the
/// kinship of its own sire and dam. Unknown parents contribute nothing, so
/// fresh outside stock genuinely dilutes a tight line.
class Bloodline {
  Bloodline();

  final Map<String, KinNode> _nodes = {};
  final Map<String, double> _kinshipCache = {};

  int _birthCounter = 0;

  Iterable<KinNode> get nodes => _nodes.values;

  int get nextBirthOrder => ++_birthCounter;

  void register(KinNode node) {
    _nodes[node.id] = node;
    if (node.birthOrder > _birthCounter) _birthCounter = node.birthOrder;
    _kinshipCache.clear();
  }

  KinNode? node(String? id) => id == null ? null : _nodes[id];

  /// Wright's inbreeding coefficient F for a bird, from the kinship of her
  /// parents. Returns 0 for founders and for birds with an unknown parent.
  double inbreedingOf(String? sireId, String? damId) {
    if (sireId == null || damId == null) return 0;
    return kinship(sireId, damId);
  }

  /// Kinship (coancestry) coefficient of two birds.
  double kinship(String? xId, String? yId, [int depth = 0]) {
    if (xId == null || yId == null) return 0;
    if (depth > 12) return 0;

    final x = _nodes[xId];
    final y = _nodes[yId];
    if (x == null || y == null) return 0;

    final key = xId.compareTo(yId) <= 0 ? '$xId|$yId' : '$yId|$xId';
    final cached = _kinshipCache[key];
    if (cached != null) return cached;

    double result;
    if (xId == yId) {
      // f(x,x) = 0.5 * (1 + F_x)
      result = 0.5 * (1 + inbreedingOf(x.sireId, x.damId));
    } else {
      // Recurse on whichever bird is younger, so we always walk upward.
      final younger = x.birthOrder >= y.birthOrder ? x : y;
      final other = younger == x ? y : x;
      if (younger.sireId == null && younger.damId == null) {
        result = 0;
      } else {
        final viaSire = kinship(younger.sireId, other.id, depth + 1);
        final viaDam = kinship(younger.damId, other.id, depth + 1);
        result = 0.5 * (viaSire + viaDam);
      }
    }

    _kinshipCache[key] = result;
    return result;
  }

  /// Ancestors of [id] up to [generations] back, nearest first. Powers the
  /// pedigree chart in the Brooder.
  List<KinNode> ancestors(String id, {int generations = 3}) {
    final out = <KinNode>[];
    final seen = <String>{};
    var frontier = <String>[id];
    for (var g = 0; g < generations; g++) {
      final next = <String>[];
      for (final cur in frontier) {
        final n = _nodes[cur];
        if (n == null) continue;
        for (final parent in [n.sireId, n.damId]) {
          if (parent == null || !seen.add(parent)) continue;
          final pn = _nodes[parent];
          if (pn != null) {
            out.add(pn);
            next.add(parent);
          }
        }
      }
      frontier = next;
      if (frontier.isEmpty) break;
    }
    return out;
  }

  List<Map<String, dynamic>> toJson() =>
      _nodes.values.map((n) => n.toJson()).toList();

  void loadJson(List<dynamic> raw) {
    _nodes.clear();
    _kinshipCache.clear();
    _birthCounter = 0;
    for (final entry in raw) {
      register(KinNode.fromJson(Map<String, dynamic>.from(entry as Map)));
    }
  }
}

/// Penalties applied for a tight pedigree. Thresholds follow the usual
/// livestock breakpoints: 0.25 is a full-sibling mating, 0.375 is worse.
class KinCost {
  const KinCost(this.staminaPenalty, this.commandLoss, this.label);

  final double staminaPenalty;
  final int commandLoss;
  final String label;

  static const none = KinCost(0, 0, '');
  static const frail = KinCost(0.20, 0, 'Frail');
  static const weakHatch = KinCost(0.20, 1, 'Weak Hatch');

  static KinCost forCoefficient(double f) {
    if (f >= 0.375) return weakHatch;
    if (f >= 0.25) return frail;
    return none;
  }
}
