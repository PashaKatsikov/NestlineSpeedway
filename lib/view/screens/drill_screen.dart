import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/blood/locus.dart';
import 'package:nestline_circuit/campaign/meets.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/widgets/bird_view.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';

/// A training day: no race, one choice, and it always costs something.
class DrillScreen extends StatelessWidget {
  const DrillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();
    final offer = game.trainingOffer;
    final racer = game.activeRacer;

    if (offer == null || racer == null) {
      return const Scaffold(body: VacantNote('Nothing to work on today.'));
    }

    return Stage(
      title: 'Training day',
      subtitle:
          '${racer.name} · rank ${racer.rank}'
          '${racer.rank >= 5 ? '' : ', ${racer.xpToNextRank} to the next'}',
      plate: Backdrops.scene(4),
      onBack: () => Navigator.of(context).maybePop(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 210,
            child: Pane(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: LivingBird(
                        pose: racer.portraitPose,
                        plume: racer.plume,
                        size: 108,
                      ),
                    ),
                  ),
                  GaugeBar(
                    value: racer.fatigue,
                    max: 100,
                    tint: racer.fatigue > 60 ? Pigment.bad : Pigment.warn,
                    label: 'Fatigue',
                  ),
                  const SizedBox(height: 8),
                  GaugeBar(
                    value: racer.xp,
                    max: racer.xp + racer.xpToNextRank,
                    tint: Pigment.stamina,
                    label: 'Experience',
                    showNumbers: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListView.separated(
              itemCount: offer.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _DrillCard(
                option: offer[i],
                onTap: () {
                  game.train(offer[i]);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrillCard extends StatelessWidget {
  const _DrillCard({required this.option, required this.onTap});
  final DrillOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pane(
      onTap: onTap,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Image.asset(
            Atlas.trainer(option.kind.index * 3),
            width: 38,
            height: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option.title, style: Face.title(15)),
                Text(option.blurb, style: Face.text(11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (option.xp > 0)
                Text(
                  '+${option.xp} xp',
                  style: Face.number(13, color: Pigment.stamina),
                ),
              if (option.fatigue > 0)
                Text(
                  '+${option.fatigue} fatigue',
                  style: Face.text(10.5, color: Pigment.bad),
                ),
              if (option.fatigueRelief > 0)
                Text(
                  '-${option.fatigueRelief} fatigue',
                  style: Face.text(10.5, color: Pigment.stamina),
                ),
              if (option.locus != null)
                Text(
                  'reads ${option.locus!.label}',
                  style: Face.text(10.5, color: Pigment.amber),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
