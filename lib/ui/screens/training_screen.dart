import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/typography.dart';
import '../../genetics/locus.dart';
import '../../season/encounters.dart';
import '../../state/game.dart';
import '../widgets/bird_view.dart';
import '../widgets/ui_kit.dart';

/// A training day: no race, one choice, and it always costs something.
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final offer = game.trainingOffer;
    final racer = game.activeRacer;

    if (offer == null || racer == null) {
      return const Scaffold(body: EmptyNote('Nothing to work on today.'));
    }

    return GameScreen(
      title: 'Training day',
      subtitle:
          '${racer.name} · rank ${racer.rank}'
          '${racer.rank >= 5 ? '' : ', ${racer.xpToNextRank} to the next'}',
      plate: Plates.scene(4),
      onBack: () => Navigator.of(context).maybePop(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 210,
            child: Panel(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: BreathingBird(
                        pose: racer.portraitPose,
                        plume: racer.plume,
                        size: 108,
                      ),
                    ),
                  ),
                  MeterBar(
                    value: racer.fatigue,
                    max: 100,
                    tint: racer.fatigue > 60 ? Palette.bad : Palette.warn,
                    label: 'Fatigue',
                  ),
                  const SizedBox(height: 8),
                  MeterBar(
                    value: racer.xp,
                    max: racer.xp + racer.xpToNextRank,
                    tint: Palette.stamina,
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
              itemBuilder: (context, i) => _OptionCard(
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

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.option, required this.onTap});
  final TrainingOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Image.asset(
            Sprites.trainer(option.kind.index * 3),
            width: 38,
            height: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option.title, style: Type.title(15)),
                Text(option.blurb, style: Type.text(11)),
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
                  style: Type.number(13, color: Palette.stamina),
                ),
              if (option.fatigue > 0)
                Text(
                  '+${option.fatigue} fatigue',
                  style: Type.text(10.5, color: Palette.bad),
                ),
              if (option.fatigueRelief > 0)
                Text(
                  '-${option.fatigueRelief} fatigue',
                  style: Type.text(10.5, color: Palette.stamina),
                ),
              if (option.locus != null)
                Text(
                  'reads ${option.locus!.label}',
                  style: Type.text(10.5, color: Palette.amber),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
