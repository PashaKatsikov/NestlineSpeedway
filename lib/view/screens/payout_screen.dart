import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/blood/brooder.dart';
import 'package:nestline_circuit/blood/runner.dart';
import 'package:nestline_circuit/campaign/kit.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/widgets/bird_view.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';

/// Post-race summary: placement, purse, egg, experience and whatever the race
/// cost the bird.
class PayoutScreen extends StatelessWidget {
  const PayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();
    final payout = game.lastPayout;
    final racer = game.activeRacer;

    if (payout == null || racer == null) {
      return Scaffold(
        body: Center(
          child: LeadButton(
            label: 'Back to the season',
            onTap: () => _leave(context, game),
          ),
        ),
      );
    }

    final won = payout.placement == 1;
    final podium = payout.placement <= 3;

    return Stage(
      title: won
          ? 'Winner'
          : podium
          ? 'On the podium'
          : 'Beaten',
      subtitle: '${_ordinal(payout.placement)} of ${payout.fieldSize}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Pane(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: LivingBird(
                        pose: won
                            ? Atlas.poseWin
                            : podium
                            ? Atlas.poseCheer
                            : Atlas.poseSpent,
                        plume: racer.plume,
                        size: 132,
                      ),
                    ),
                  ),
                  Text(racer.name, style: Face.title(20)),
                  const SizedBox(height: 4),
                  Text(
                    won
                        ? 'She held the line when it counted.'
                        : podium
                        ? 'A share of the purse and something learned.'
                        : 'The circuit does not owe anyone a result.',
                    textAlign: TextAlign.center,
                    style: Face.text(11.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Pane(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaneTitle('Payout'),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        _Line(
                          icon: Icons.savings,
                          tint: Pigment.amber,
                          label: 'Purse',
                          value: '+${payout.grain} grain',
                        ),
                        if (payout.eggTier >= 0)
                          _Line(
                            iconAsset: Atlas.egg(payout.eggTier),
                            tint: Pigment.tiers[payout.eggTier],
                            label: '${ShellTier.at(payout.eggTier).name} egg',
                            value: 'banked for breeding',
                          ),
                        _Line(
                          icon: Icons.trending_up,
                          tint: Pigment.stamina,
                          label: 'Experience',
                          value:
                              '+${payout.xp}'
                              '${racer.rank >= 5 ? '' : ' (${racer.xpToNextRank} to rank ${racer.rank + 1})'}',
                        ),
                        _Line(
                          icon: Icons.battery_2_bar,
                          tint: Pigment.warn,
                          label: 'Fatigue',
                          value: '+${payout.fatigue} (now ${racer.fatigue})',
                        ),
                        if (payout.tackId != null)
                          _Line(
                            iconAsset: Tack.byId(payout.tackId!)?.iconPath,
                            tint: Pigment.schoolRainbow,
                            label: Tack.byId(payout.tackId!)?.name ?? 'Tack',
                            value: 'won — fit it before the next event',
                          ),
                        if (payout.injuryId != null)
                          _Line(
                            icon: Icons.healing,
                            tint: Pigment.bad,
                            label: Injury.byId(payout.injuryId!).name,
                            value: Injury.byId(payout.injuryId!).careerEnding
                                ? 'career ending'
                                : Injury.byId(payout.injuryId!).mods.describe(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  LeadButton(
                    label: game.season?.over == true
                        ? 'Close the season'
                        : 'Back to the schedule',
                    icon: Icons.arrow_forward_rounded,
                    expand: true,
                    onTap: () => _leave(context, game),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns to wherever the player came from.
  ///
  /// This screen replaced the race in the stack, so a single pop lands back on
  /// the schedule. When that race was the finale the season has just closed and
  /// there is no schedule left to show, so it steps back to the stable instead.
  void _leave(BuildContext context, Director game) {
    final seasonClosing = game.season?.over ?? false;
    game.acknowledgeResult();

    final navigator = Navigator.of(context);
    navigator.pop();
    if (seasonClosing && navigator.canPop()) navigator.pop();
  }

  static String _ordinal(int n) => switch (n) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    _ => '${n}th',
  };
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.tint,
    this.icon,
    this.iconAsset,
  });

  final String label;
  final String value;
  final Color tint;
  final IconData? icon;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: iconAsset != null
                ? Image.asset(iconAsset!, width: 26, height: 26)
                : Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Face.title(13, color: tint)),
                Text(value, style: Face.text(11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
