import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/theme.dart';
import '../../core/typography.dart';
import '../../genetics/hatchery.dart';
import '../../genetics/pedigree.dart';
import '../../genetics/racer.dart';
import '../../meta/stable.dart';
import '../../state/game.dart';
import '../../tutorial/lesson.dart';
import '../widgets/bird_view.dart';
import '../widgets/coach_mark.dart';
import '../widgets/genome_view.dart';
import '../widgets/ui_kit.dart';

/// Breeding. Pick two birds, read the forecast, pick a shell, pay for it.
class HatcheryScreen extends StatefulWidget {
  const HatcheryScreen({super.key});

  @override
  State<HatcheryScreen> createState() => _HatcheryScreenState();
}

class _HatcheryScreenState extends State<HatcheryScreen> {
  String? _sireId;
  String? _damId;
  int _tier = 0;
  Racer? _lastHatched;

  final GlobalKey _flockKey = GlobalKey();
  final GlobalKey _pairKey = GlobalKey();

  late final bool _teaching = context.read<Game>().needsLesson(Lesson.hatchery);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();

    return CoachOverlay(
      active: _teaching,
      onDone: () => game.completeLesson(Lesson.hatchery),
      steps: [
        CoachStep(
          anchor: _flockKey,
          icon: Icons.groups_rounded,
          title: 'Pick a pairing',
          body:
              'Tap two different birds to set them as A and B. What matters is '
              'not how fast they are but which alleles they carry, because that '
              'is what the chick will have to race with.',
        ),
        CoachStep(
          anchor: _pairKey,
          icon: Icons.insights_rounded,
          title: 'Read the forecast first',
          body:
              'The forecast lists what the pairing can produce and how likely '
              'each outcome is. F is the inbreeding coefficient: at 0.25 the '
              'chick hatches Frail, so watch it climb as your line tightens.',
        ),
        CoachStep(
          anchor: _pairKey,
          icon: Icons.egg_alt_rounded,
          title: 'Then choose the shell',
          body:
              'A better egg rescues more recessives and mutates more often, and '
              'it is spent whether or not you like what hatches. Cheap shells '
              'are for testing a pairing; good ones are for committing to it.',
        ),
      ],
      child: _buildScreen(context, game),
    );
  }

  Widget _buildScreen(BuildContext context, Game game) {
    final stable = game.stable;
    final birds = stable.active;

    final sire = stable.byId(_sireId);
    final dam = stable.byId(_damId);
    final pairReady = sire != null && dam != null && sire.id != dam.id;
    final tier = EggTier.at(_tier);
    final canAfford = stable.canSpendEggs(tier.index, 1);

    return GameScreen(
      title: 'Hatchery',
      subtitle:
          'Pair two birds. Recessives only express when doubled up — and '
          'doubling up costs you in blood.',
      plate: Plates.scene(0),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        StatChip(
          label: 'eggs',
          value: '${stable.eggTotal}',
          iconAsset: Sprites.egg(0),
          compact: true,
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Roster picker.
          SizedBox(
            width: 232,
            child: Panel(
              key: _flockKey,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('The flock'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: birds.length < 2
                        ? const EmptyNote(
                            'You need two fit birds to breed a pairing.',
                          )
                        : ListView.separated(
                            itemCount: birds.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 7),
                            itemBuilder: (context, i) {
                              final racer = birds[i];
                              final isSire = racer.id == _sireId;
                              final isDam = racer.id == _damId;
                              return RacerCard(
                                racer: racer,
                                compact: true,
                                selected: isSire || isDam,
                                trailing: isSire || isDam
                                    ? Text(
                                        isSire ? 'A' : 'B',
                                        style: Type.number(
                                          14,
                                          color: Palette.amber,
                                        ),
                                      )
                                    : null,
                                onTap: () => _assign(racer),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Pairing detail.
          Expanded(
            child: Panel(
              key: _pairKey,
              child: pairReady
                  ? _PairingDetail(
                      game: game,
                      sire: sire,
                      dam: dam,
                      tier: tier,
                      onTier: (v) => setState(() => _tier = v),
                      canAfford: canAfford,
                      onBreed: () {
                        final chick = game.breed(sire, dam, tier);
                        if (chick != null) {
                          setState(() => _lastHatched = chick);
                        }
                      },
                      lastHatched: _lastHatched,
                    )
                  : const EmptyNote(
                      'Pick two different birds on the left to see what the '
                      'pairing can produce.',
                      icon: Icons.favorite_outline_rounded,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _assign(Racer racer) {
    setState(() {
      if (racer.id == _sireId) {
        _sireId = null;
      } else if (racer.id == _damId) {
        _damId = null;
      } else if (_sireId == null) {
        _sireId = racer.id;
      } else if (_damId == null) {
        _damId = racer.id;
      } else {
        _sireId = racer.id;
      }
    });
  }
}

class _PairingDetail extends StatelessWidget {
  const _PairingDetail({
    required this.game,
    required this.sire,
    required this.dam,
    required this.tier,
    required this.onTier,
    required this.canAfford,
    required this.onBreed,
    required this.lastHatched,
  });

  final Game game;
  final Racer sire;
  final Racer dam;
  final EggTier tier;
  final ValueChanged<int> onTier;
  final bool canAfford;
  final VoidCallback onBreed;
  final Racer? lastHatched;

  @override
  Widget build(BuildContext context) {
    final stable = game.stable;
    final f = stable.pedigree.inbreedingOf(sire.id, dam.id);
    final penalty = InbreedingPenalty.forCoefficient(f);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _ParentHead(racer: sire, tag: 'A'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.add_rounded, color: Palette.inkMute, size: 18),
            ),
            _ParentHead(racer: dam, tag: 'B'),
            const Spacer(),
            _InbreedingBadge(coefficient: f, penalty: penalty),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text('OFFSPRING FORECAST', style: Type.label(8.5)),
                    const SizedBox(height: 7),
                    PairingForecast(
                      sire: sire,
                      dam: dam,
                      codex: stable.codex,
                      showGenotype: stable.showsGenotypes,
                    ),
                    const SizedBox(height: 10),
                    Text('THE SHELL', style: Type.label(8.5)),
                    const SizedBox(height: 6),
                    _TierPicker(
                      stable: stable,
                      selected: tier.index,
                      onSelect: onTier,
                    ),
                    const SizedBox(height: 6),
                    Text(tier.blurb, style: Type.text(11)),
                    Text(
                      'Mutation ${(tier.mutation * 100).toStringAsFixed(1)}%'
                      ' · recessive rescue ${(tier.bias * 100).round()}%',
                      style: Type.text(10, color: Palette.inkMute),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 210,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: lastHatched == null
                          ? _PedigreeNote(sire: sire, dam: dam, game: game)
                          : _HatchResult(racer: lastHatched!, game: game),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: canAfford
                          ? 'Set the pairing'
                          : 'Need a ${tier.name} egg',
                      icon: Icons.egg_alt_rounded,
                      expand: true,
                      onTap: canAfford ? onBreed : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParentHead extends StatelessWidget {
  const _ParentHead({required this.racer, required this.tag});
  final Racer racer;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BirdView(pose: racer.portraitPose, plume: racer.plume, size: 40),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$tag · ${racer.name}', style: Type.title(13)),
            Text(
              racer.genome.notation,
              style: Type.text(9.5, color: Palette.inkMute),
            ),
          ],
        ),
      ],
    );
  }
}

class _InbreedingBadge extends StatelessWidget {
  const _InbreedingBadge({required this.coefficient, required this.penalty});
  final double coefficient;
  final InbreedingPenalty penalty;

  @override
  Widget build(BuildContext context) {
    final tint = coefficient >= 0.25
        ? Palette.bad
        : coefficient >= 0.125
        ? Palette.warn
        : Palette.stamina;
    return Tooltip(
      message:
          'Wright inbreeding coefficient of the pairing.\n'
          'At 0.25 the chick is Frail, at 0.375 she also hatches weak.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Shape.rSm),
          border: Border.all(color: tint.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'F = ${coefficient.toStringAsFixed(3)}',
              style: Type.number(13, color: tint),
            ),
            Text(
              penalty.label.isEmpty ? 'no penalty' : penalty.label,
              style: Type.text(9.5, color: tint),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierPicker extends StatelessWidget {
  const _TierPicker({
    required this.stable,
    required this.selected,
    required this.onSelect,
  });

  final Stable stable;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var t = 0; t < EggTier.all.length; t++)
          Expanded(
            child: Tappable(
              onTap: () => onSelect(t),
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected == t
                      ? Palette.tiers[t].withValues(alpha: 0.2)
                      : Palette.pitch.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(Shape.rSm),
                  border: Border.all(
                    color: selected == t ? Palette.tiers[t] : Palette.slate,
                    width: selected == t ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Opacity(
                      opacity: stable.eggs[t] > 0 ? 1 : 0.35,
                      child: Image.asset(Sprites.egg(t), height: 26),
                    ),
                    Text(
                      '${stable.eggs[t]}',
                      style: Type.number(10, color: Palette.tiers[t]),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PedigreeNote extends StatelessWidget {
  const _PedigreeNote({
    required this.sire,
    required this.dam,
    required this.game,
  });

  final Racer sire;
  final Racer dam;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final ancestors = <PedigreeNode>[
      ...game.stable.pedigree.ancestors(sire.id, generations: 2),
      ...game.stable.pedigree.ancestors(dam.id, generations: 2),
    ];
    final shared = <String>{};
    final seen = <String>{};
    for (final a in ancestors) {
      if (!seen.add(a.id)) shared.add(a.name);
    }

    return ListView(
      children: [
        Text('PEDIGREE', style: Type.label(8.5)),
        const SizedBox(height: 6),
        if (ancestors.isEmpty)
          Text(
            'Both birds are foundation stock. No shared blood at all.',
            style: Type.text(11),
          )
        else ...[
          Text(
            shared.isEmpty
                ? 'No common ancestors within two generations.'
                : 'Common ancestors: ${shared.join(', ')}',
            style: Type.text(
              11,
              color: shared.isEmpty ? Palette.stamina : Palette.warn,
            ),
          ),
          const SizedBox(height: 8),
          Text('${sire.name}: ${_line(game, sire)}', style: Type.text(10)),
          const SizedBox(height: 3),
          Text('${dam.name}: ${_line(game, dam)}', style: Type.text(10)),
        ],
      ],
    );
  }

  String _line(Game game, Racer racer) {
    final parents = [
      game.stable.pedigree.node(racer.sireId)?.name,
      game.stable.pedigree.node(racer.damId)?.name,
    ].whereType<String>().toList();
    return parents.isEmpty ? 'foundation stock' : parents.join(' × ');
  }
}

class _HatchResult extends StatelessWidget {
  const _HatchResult({required this.racer, required this.game});
  final Racer racer;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final pheno = racer.basePhenotype;
    return ListView(
      children: [
        Row(
          children: [
            BirdView(pose: Sprites.poseCheer, plume: racer.plume, size: 44),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(racer.name, style: Type.title(15)),
                  Text(
                    'hatched · ${racer.genome.notation}',
                    style: Type.text(9.5, color: Palette.inkMute),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GenomeStrip(
          racer: racer,
          codex: game.stable.codex,
          showGenotype: game.stable.showsGenotypes,
          dense: true,
        ),
        const SizedBox(height: 6),
        TraitSummary(phenotype: pheno),
      ],
    );
  }
}
