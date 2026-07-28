import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/typography.dart';
import '../../genetics/genome.dart';
import '../../genetics/hatchery.dart';
import '../../genetics/locus.dart';
import '../../genetics/racer.dart';
import '../../meta/codex.dart';

/// One allele as a lettered chip. Unknown alleles show a question mark, which is
/// the whole point of the discovery layer.
class AlleleChip extends StatelessWidget {
  const AlleleChip({
    super.key,
    required this.allele,
    this.known = true,
    this.dim = false,
    this.size = 22,
  });

  final Allele allele;
  final bool known;
  final bool dim;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = allele.tint;
    return Tooltip(
      message: known
          ? '${allele.name} (${allele.code})\n${allele.blurb}\n'
                '${allele.mods.describe()}'
          : 'Carried, but not yet identified.',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: known
              ? tint.withValues(alpha: dim ? 0.12 : 0.24)
              : Palette.slate.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: known ? tint.withValues(alpha: 0.8) : Palette.slateHi,
          ),
        ),
        child: Text(
          known ? allele.code : '?',
          style: Type.number(
            size * 0.52,
            color: known ? tint : Palette.inkMute,
          ),
        ),
      ),
    );
  }
}

/// The six loci of a bird, with the carried allele masked until the Codex has
/// identified it.
class GenomeStrip extends StatelessWidget {
  const GenomeStrip({
    super.key,
    required this.racer,
    required this.codex,
    this.showGenotype = false,
    this.dense = false,
  });

  final Racer racer;
  final Codex codex;

  /// Set by the Pedigree Office upgrade: always show both alleles.
  final bool showGenotype;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final g = racer.genome;
    final chip = dense ? 19.0 : 22.0;
    final labelWidth = dense ? 56.0 : 66.0;

    return LayoutBuilder(
      builder: (context, box) {
        // The strip is shown in side panels that get genuinely narrow on a small
        // phone, so the trait name is dropped before the chips are, and the
        // locus label gives up width before either.
        final chipsWidth = chip * 2 + 12;
        final forName = box.maxWidth - chipsWidth - labelWidth;
        final showName = forName >= 44;
        final label = showName
            ? labelWidth
            : (box.maxWidth - chipsWidth).clamp(0.0, labelWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in Locus.values)
              Padding(
                padding: EdgeInsets.only(bottom: dense ? 4 : 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: label,
                      child: Text(
                        l.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: Type.label(dense ? 8 : 8.5),
                      ),
                    ),
                    AlleleChip(allele: g.expressed(l), size: chip),
                    const SizedBox(width: 4),
                    if (g.isHomozygous(l))
                      AlleleChip(allele: g.expressed(l), size: chip)
                    else
                      AlleleChip(
                        allele: g.hidden(l)!,
                        known:
                            showGenotype ||
                            codex.knowsAllele(l, g.hidden(l)!.index),
                        dim: true,
                        size: chip,
                      ),
                    if (showName) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        // Two matching chips and the amber tint already say the
                        // locus is pure, so the name gets the whole column.
                        child: Text(
                          g.expressed(l).name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Type.text(
                            dense ? 10 : 11,
                            color: g.isHomozygous(l)
                                ? Palette.amber
                                : Palette.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Traits, pure traits and synergies as a compact readout.
class TraitSummary extends StatelessWidget {
  const TraitSummary({super.key, required this.phenotype});
  final Phenotype phenotype;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Tag('${phenotype.staminaMax} wind', Palette.stamina),
            _Tag('${phenotype.stride} stride', Palette.ember),
            _Tag('${phenotype.effort} effort', Palette.effort),
            _Tag('${phenotype.grip} grip', Palette.momentum),
            _Tag('${phenotype.control} control', Palette.distance),
            _Tag('${phenotype.recovery} recovery', Palette.stamina),
            _Tag('${phenotype.hand} hand', Palette.inkSoft),
          ],
        ),
        if (phenotype.pureTraits.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text('PURE TRAITS', style: Type.label(8.5)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in phenotype.pureTraits)
                _Tag('${a.name} ${a.locus.label}', Palette.amber),
            ],
          ),
        ],
        if (phenotype.synergies.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text('SYNERGIES', style: Type.label(8.5)),
          const SizedBox(height: 4),
          for (final s in phenotype.synergies)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: Palette.schoolRainbow,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${s.name} — ${s.blurb}',
                      style: Type.text(10.5, color: Palette.schoolRainbow),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.tint);
  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: Type.text(10, color: tint)),
    );
  }
}

/// Offspring forecast for a pairing: what each locus can produce and how likely
/// a pure trait is. This is the planning tool the meta game lives on.
class PairingForecast extends StatelessWidget {
  const PairingForecast({
    super.key,
    required this.sire,
    required this.dam,
    required this.codex,
    required this.showGenotype,
  });

  final Racer sire;
  final Racer dam;
  final Codex codex;
  final bool showGenotype;

  @override
  Widget build(BuildContext context) {
    final forecast = Hatchery.forecast(sire, dam);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final l in Locus.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(l.label.toUpperCase(), style: Type.label(8.5)),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      for (final entry in _sorted(forecast[l]!))
                        _Odds(
                          allele: Alleles.at(l, entry.key),
                          chance: entry.value,
                          known:
                              showGenotype || codex.knowsAllele(l, entry.key),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 62,
                  child: Text(
                    'pure ${(Hatchery.pureChance(sire, dam, l) * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: Type.text(
                      9.5,
                      color: Hatchery.pureChance(sire, dam, l) > 0
                          ? Palette.amber
                          : Palette.inkMute,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<MapEntry<int, double>> _sorted(Map<int, double> raw) {
    final list = raw.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}

class _Odds extends StatelessWidget {
  const _Odds({
    required this.allele,
    required this.chance,
    required this.known,
  });

  final Allele allele;
  final double chance;
  final bool known;

  @override
  Widget build(BuildContext context) {
    final tint = allele.tint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Shape.rSm),
        border: Border.all(color: tint.withValues(alpha: 0.45)),
      ),
      child: Text(
        '${known ? allele.name : '???'} ${(chance * 100).round()}%',
        style: Type.text(10, color: known ? tint : Palette.inkMute),
      ),
    );
  }
}
