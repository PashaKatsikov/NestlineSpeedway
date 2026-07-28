import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/typography.dart';
import '../../genetics/hatchery.dart';
import '../../meta/upgrades.dart';
import '../../state/game.dart';
import '../widgets/ui_kit.dart';

/// The yard: permanent upgrades, paid for in eggs.
class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final stable = game.stable;
    final available = stable.availableUpgrades;
    final built = StableUpgrade.all
        .where((u) => stable.isBuilt(u.id))
        .toList(growable: false);

    return GameScreen(
      title: 'The yard',
      subtitle:
          '${built.length} of ${StableUpgrade.all.length} built. '
          'Everything here is permanent.',
      plate: Plates.scene(1),
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        StatChip(
          label: 'eggs',
          value: '${stable.eggTotal}',
          iconAsset: Sprites.egg(
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
            child: Panel(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Available'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: available.isEmpty
                        ? const EmptyNote('Everything is built.')
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 300,
                                  mainAxisExtent: 92,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            itemCount: available.length,
                            itemBuilder: (context, i) => _UpgradeCard(
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
            child: Panel(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Standing'),
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
                          Text('BUILT', style: Type.label(8.5)),
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
          Expanded(child: Text(label, style: Type.text(11))),
          Text(value, style: Type.number(12, color: Palette.amber)),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.upgrade,
    required this.affordable,
    required this.onTap,
  });

  final StableUpgrade upgrade;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
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
                      style: Type.title(13),
                    ),
                    if (blurbLines > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        upgrade.blurb,
                        maxLines: blurbLines,
                        overflow: TextOverflow.ellipsis,
                        style: Type.text(10),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.asset(Sprites.egg(upgrade.costTier), width: 17),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${upgrade.costCount} × '
                            '${EggTier.at(upgrade.costTier).name}+',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Type.text(
                              9.5,
                              color: affordable
                                  ? Palette.tiers[upgrade.costTier]
                                  : Palette.inkMute,
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
