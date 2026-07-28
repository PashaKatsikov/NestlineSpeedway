import '../genetics/genome.dart';
import '../genetics/locus.dart';

/// The player's record of what they have actually seen. Genotypes are hidden
/// until an allele is in here, so the Codex is a gameplay system rather than a
/// gallery: filling it is what turns breeding from guesswork into planning.
class Codex {
  final Set<String> alleles = {};
  final Set<String> commands = {};
  final Set<String> synergies = {};
  final Set<String> venues = {};
  final Set<String> champions = {};
  final Set<String> tack = {};
  final Set<String> rivals = {};

  static String alleleKey(Locus l, int index) => '${l.index}:$index';

  bool knowsAllele(Locus l, int index) => alleles.contains(alleleKey(l, index));

  /// Records an allele. Returns true when it was genuinely new.
  bool discoverAllele(Locus l, int index) => alleles.add(alleleKey(l, index));

  /// A bird's phenotype is always visible, so every expressed allele is learned
  /// the moment she is in the stable.
  List<String> observe(Genome g) {
    final learned = <String>[];
    for (final l in Locus.values) {
      final expressed = g.expressedIndex(l);
      if (discoverAllele(l, expressed)) {
        learned.add(Alleles.at(l, expressed).name);
      }
      // A homozygote proves both copies, so nothing stays hidden on a pure bird.
      if (g.isHomozygous(l)) continue;
    }
    for (final s in Synergies.matching(g)) {
      synergies.add(s.command);
    }
    return learned;
  }

  /// Reveals the hidden allele at [l], as a Gene Read or a Gene Lab does.
  String? reveal(Genome g, Locus l) {
    final hidden = g.hidden(l);
    if (hidden == null) return null;
    return discoverAllele(l, hidden.index) ? hidden.name : null;
  }

  int get alleleTotal => Alleles.all.length;
  int get completion {
    final parts = <double>[
      alleles.length / alleleTotal,
      synergies.length / Synergies.all.length,
    ];
    final avg = parts.reduce((a, b) => a + b) / parts.length;
    return (avg * 100).round();
  }

  Map<String, dynamic> toJson() => {
    'alleles': alleles.toList(),
    'commands': commands.toList(),
    'synergies': synergies.toList(),
    'venues': venues.toList(),
    'champions': champions.toList(),
    'tack': tack.toList(),
    'rivals': rivals.toList(),
  };

  void loadJson(Map<String, dynamic> j) {
    void fill(Set<String> target, String key) {
      target
        ..clear()
        ..addAll((j[key] as List<dynamic>? ?? const []).cast<String>());
    }

    fill(alleles, 'alleles');
    fill(commands, 'commands');
    fill(synergies, 'synergies');
    fill(venues, 'venues');
    fill(champions, 'champions');
    fill(tack, 'tack');
    fill(rivals, 'rivals');
  }
}
