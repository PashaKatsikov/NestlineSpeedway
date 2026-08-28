import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/look.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/blood/brooder.dart';
import 'package:nestline_circuit/blood/bloodline.dart';
import 'package:nestline_circuit/blood/runner.dart';
import 'package:nestline_circuit/yard/roster.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/walkthrough/guide.dart';
import 'package:nestline_circuit/view/widgets/bird_view.dart';
import 'package:nestline_circuit/view/widgets/guide_overlay.dart';
import 'package:nestline_circuit/view/widgets/heredity_view.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';

/// Breeding. Pick two birds, read the forecast, pick a shell, pay for it.
class BrooderScreen extends StatefulWidget {
  const BrooderScreen({super.key});

  @override
  State<BrooderScreen> createState() => _BrooderScreenState();
}

class _BrooderScreenState extends State<BrooderScreen> {
  String? _sireId;
  String? _damId;
  int _tier = 0;
  Runner? _lastHatched;

  final GlobalKey _flockKey = GlobalKey();
  final GlobalKey _pairKey = GlobalKey();

  late final bool _teaching = context.read<Director>().needsGuide(Guide.hatchery);

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();

    return GuideOverlay(
      active: _teaching,
      onDone: () => game.completeGuide(Guide.hatchery),
      steps: [
        GuideBeat(
          anchor: _flockKey,
          icon: Icons.groups_rounded,
          title: 'Pick a pairing',
          body:
              'Tap two different birds to set them as A and B. What matters is '
              'not how fast they are but which alleles they carry, because that '
              'is what the chick will have to race with.',
        ),
        GuideBeat(
          anchor: _pairKey,
          icon: Icons.insights_rounded,
          title: 'Read the forecast first',
          body:
              'The forecast lists what the pairing can produce and how likely '
              'each outcome is. F is the inbreeding coefficient: at 0.25 the '
              'chick hatches Frail, so watch it climb as your line tightens.',
        ),
        GuideBeat(
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

  Widget _buildScreen(BuildContext context, Director game) {
    final stable = game.stable;
    final birds = stable.active;

    final sire = stable.byId(_sireId);
    final dam = stable.byId(_damId);
    final pairReady = sire != null && dam != null && sire.id != dam.id;
    final tier = ShellTier.at(_tier);
    final canAfford = stable.canSpendEggs(tier.index, 1);

    return Stage(
      title: 'Hatchery',
      subtitle:
          'Pair two birds. Recessives only express when doubled up — and '
          'doubling up costs you in blood.',
      plate: Backdrops.scene(0),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        StatMark(
          label: 'eggs',
          value: '${stable.eggTotal}',
          iconAsset: Atlas.egg(0),
          compact: true,
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Roster picker.
          SizedBox(
            width: 232,
            child: Pane(
              key: _flockKey,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaneTitle('The flock'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: birds.length < 2
                        ? const VacantNote(
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
                              return RunnerCard(
                                racer: racer,
                                compact: true,
                                selected: isSire || isDam,
                                trailing: isSire || isDam
                                    ? Text(
                                        isSire ? 'A' : 'B',
                                        style: Face.number(
                                          14,
                                          color: Pigment.amber,
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
            child: Pane(
              key: _pairKey,
              child: pairReady
                  ? _PairingBoard(
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
                  : const VacantNote(
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

  void _assign(Runner racer) {
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

class _PairingBoard extends StatelessWidget {
  const _PairingBoard({
    required this.game,
    required this.sire,
    required this.dam,
    required this.tier,
    required this.onTier,
    required this.canAfford,
    required this.onBreed,
    required this.lastHatched,
  });

  final Director game;
  final Runner sire;
  final Runner dam;
  final ShellTier tier;
  final ValueChanged<int> onTier;
  final bool canAfford;
  final VoidCallback onBreed;
  final Runner? lastHatched;

  @override
  Widget build(BuildContext context) {
    final stable = game.stable;
    final f = stable.pedigree.inbreedingOf(sire.id, dam.id);
    final penalty = KinCost.forCoefficient(f);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _DamSireHead(racer: sire, tag: 'A'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.add_rounded, color: Pigment.inkMute, size: 18),
            ),
            _DamSireHead(racer: dam, tag: 'B'),
            const Spacer(),
            _KinBadge(coefficient: f, penalty: penalty),
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
                    Text('OFFSPRING FORECAST', style: Face.label(8.5)),
                    const SizedBox(height: 7),
                    PairingOutlook(
                      sire: sire,
                      dam: dam,
                      codex: stable.codex,
                      showGenotype: stable.showsGenotypes,
                    ),
                    const SizedBox(height: 10),
                    Text('THE SHELL', style: Face.label(8.5)),
                    const SizedBox(height: 6),
                    _ShellPicker(
                      stable: stable,
                      selected: tier.index,
                      onSelect: onTier,
                    ),
                    const SizedBox(height: 6),
                    Text(tier.blurb, style: Face.text(11)),
                    Text(
                      'Mutation ${(tier.mutation * 100).toStringAsFixed(1)}%'
                      ' · recessive rescue ${(tier.bias * 100).round()}%',
                      style: Face.text(10, color: Pigment.inkMute),
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
                          ? _BloodNote(sire: sire, dam: dam, game: game)
                          : _BroodResult(racer: lastHatched!, game: game),
                    ),
                    const SizedBox(height: 8),
                    LeadButton(
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

class _DamSireHead extends StatelessWidget {
  const _DamSireHead({required this.racer, required this.tag});
  final Runner racer;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HenView(pose: racer.portraitPose, plume: racer.plume, size: 40),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$tag · ${racer.name}', style: Face.title(13)),
            Text(
              racer.genome.notation,
              style: Face.text(9.5, color: Pigment.inkMute),
            ),
          ],
        ),
      ],
    );
  }
}

class _KinBadge extends StatelessWidget {
  const _KinBadge({required this.coefficient, required this.penalty});
  final double coefficient;
  final KinCost penalty;

  @override
  Widget build(BuildContext context) {
    final tint = coefficient >= 0.25
        ? Pigment.bad
        : coefficient >= 0.125
        ? Pigment.warn
        : Pigment.stamina;
    return Tooltip(
      message:
          'Wright inbreeding coefficient of the pairing.\n'
          'At 0.25 the chick is Frail, at 0.375 she also hatches weak.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Corners.rSm),
          border: Border.all(color: tint.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'F = ${coefficient.toStringAsFixed(3)}',
              style: Face.number(13, color: tint),
            ),
            Text(
              penalty.label.isEmpty ? 'no penalty' : penalty.label,
              style: Face.text(9.5, color: tint),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellPicker extends StatelessWidget {
  const _ShellPicker({
    required this.stable,
    required this.selected,
    required this.onSelect,
  });

  final Yard stable;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var t = 0; t < ShellTier.all.length; t++)
          Expanded(
            child: Pressable(
              onTap: () => onSelect(t),
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected == t
                      ? Pigment.tiers[t].withValues(alpha: 0.2)
                      : Pigment.pitch.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(Corners.rSm),
                  border: Border.all(
                    color: selected == t ? Pigment.tiers[t] : Pigment.slate,
                    width: selected == t ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Opacity(
                      opacity: stable.eggs[t] > 0 ? 1 : 0.35,
                      child: Image.asset(Atlas.egg(t), height: 26),
                    ),
                    Text(
                      '${stable.eggs[t]}',
                      style: Face.number(10, color: Pigment.tiers[t]),
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

class _BloodNote extends StatelessWidget {
  const _BloodNote({
    required this.sire,
    required this.dam,
    required this.game,
  });

  final Runner sire;
  final Runner dam;
  final Director game;

  @override
  Widget build(BuildContext context) {
    final ancestors = <KinNode>[
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
        Text('PEDIGREE', style: Face.label(8.5)),
        const SizedBox(height: 6),
        if (ancestors.isEmpty)
          Text(
            'Both birds are foundation stock. No shared blood at all.',
            style: Face.text(11),
          )
        else ...[
          Text(
            shared.isEmpty
                ? 'No common ancestors within two generations.'
                : 'Common ancestors: ${shared.join(', ')}',
            style: Face.text(
              11,
              color: shared.isEmpty ? Pigment.stamina : Pigment.warn,
            ),
          ),
          const SizedBox(height: 8),
          Text('${sire.name}: ${_line(game, sire)}', style: Face.text(10)),
          const SizedBox(height: 3),
          Text('${dam.name}: ${_line(game, dam)}', style: Face.text(10)),
        ],
      ],
    );
  }

  String _line(Director game, Runner racer) {
    final parents = [
      game.stable.pedigree.node(racer.sireId)?.name,
      game.stable.pedigree.node(racer.damId)?.name,
    ].whereType<String>().toList();
    return parents.isEmpty ? 'foundation stock' : parents.join(' × ');
  }
}

class _BroodResult extends StatelessWidget {
  const _BroodResult({required this.racer, required this.game});
  final Runner racer;
  final Director game;

  @override
  Widget build(BuildContext context) {
    final pheno = racer.basePhenotype;
    return ListView(
      children: [
        Row(
          children: [
            HenView(pose: Atlas.poseCheer, plume: racer.plume, size: 44),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(racer.name, style: Face.title(15)),
                  Text(
                    'hatched · ${racer.genome.notation}',
                    style: Face.text(9.5, color: Pigment.inkMute),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        HeredityStrip(
          racer: racer,
          codex: game.stable.codex,
          showGenotype: game.stable.showsGenotypes,
          dense: true,
        ),
        const SizedBox(height: 6),
        TraitStrip(phenotype: pheno),
      ],
    );
  }
}
