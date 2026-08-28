import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/blood/brooder.dart';
import 'package:nestline_circuit/yard/works.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';

/// The yard: permanent upgrades, paid for in eggs.
class WorksScreen extends StatelessWidget {
  const WorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();
    final stable = game.stable;
    final available = stable.availableUpgrades;
    final built = YardWork.all
        .where((u) => stable.isBuilt(u.id))
        .toList(growable: false);

    return Stage(
      title: 'The yard',
      subtitle:
          '${built.length} of ${YardWork.all.length} built. '
          'Everything here is permanent.',
      plate: Backdrops.scene(1),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        StatMark(
          label: 'eggs',
          value: '${stable.eggTotal}',
          iconAsset: Atlas.egg(
            stable.bestEggTier < 0 ? 0 : stable.bestEggTier,
          ),
          compact: true,
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Pane(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaneTitle('Available'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: available.isEmpty
                        ? const VacantNote('Everything is built.')
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 300,
                                  mainAxisExtent: 92,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            itemCount: available.length,
                            itemBuilder: (context, i) => _WorkCard(
                              upgrade: available[i],
                              affordable: stable.canBuild(available[i]),
                              onTap: () => game.buildUpgrade(available[i]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 232,
            child: Pane(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaneTitle('Standing'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        _Row('Hatch slots', '${stable.hatchSlots}'),
                        _Row('Travelling slots', '${stable.rosterSlots}'),
                        _Row('Tack slots', '${stable.tackSlots}'),
                        _Row('Starting grain', '${stable.startingGrain}'),
                        _Row(
                          'Gene reads per hatch',
                          '${stable.geneReadsPerHatch}',
                        ),
                        _Row('Injury reduction', '${stable.injuryGuard}'),
                        _Row('Rest bonus', '+${stable.restBonus} fatigue'),
                        _Row('Egg tier bonus', '+${stable.eggTierBonus}'),
                        _Row(
                          'Purse multiplier',
                          '×${stable.purseMultiplier.toStringAsFixed(2)}',
                        ),
                        _Row(
                          'Trader prices',
                          '×${stable.traderMultiplier.toStringAsFixed(2)}',
                        ),
                        _Row(
                          'Experience',
                          '×${stable.xpMultiplier.toStringAsFixed(2)}',
                        ),
                        if (built.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text('BUILT', style: Face.label(8.5)),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final u in built)
                                Tooltip(
                                  message: '${u.name}\n${u.blurb}',
                                  child: Image.asset(u.iconPath, width: 30),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Face.text(11))),
          Text(value, style: Face.number(12, color: Pigment.amber)),
        ],
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({
    required this.upgrade,
    required this.affordable,
    required this.onTap,
  });

  final YardWork upgrade;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pane(
      onTap: onTap,
      selected: affordable,
      padding: const EdgeInsets.all(9),
      child: Row(
        children: [
          Opacity(
            opacity: affordable ? 1 : 0.45,
            child: Image.asset(upgrade.iconPath, width: 40, height: 40),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                // Name and price stay; the description shrinks to the lines the
                // grid cell can actually show.
                final forBlurb = box.maxHeight - 40;
                final blurbLines = (forBlurb / 13).floor().clamp(0, 2);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      upgrade.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Face.title(13),
                    ),
                    if (blurbLines > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        upgrade.blurb,
                        maxLines: blurbLines,
                        overflow: TextOverflow.ellipsis,
                        style: Face.text(10),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.asset(Atlas.egg(upgrade.costTier), width: 17),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${upgrade.costCount} × '
                            '${ShellTier.at(upgrade.costTier).name}+',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Face.text(
                              9.5,
                              color: affordable
                                  ? Pigment.tiers[upgrade.costTier]
                                  : Pigment.inkMute,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
