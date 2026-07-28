import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/typography.dart';
import '../../state/game.dart';
import '../widgets/bird_view.dart';
import '../widgets/ui_kit.dart';

/// A rest day: clear fatigue, and treat one injury if there is one to treat.
class RestScreen extends StatefulWidget {
  const RestScreen({super.key});

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  String? _selectedInjury;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final racer = game.activeRacer;
    if (racer == null) {
      return const Scaffold(body: EmptyNote('Nobody to rest.'));
    }

    final treatable = racer.injuryList
        .where((i) => !i.careerEnding)
        .toList(growable: false);
    final relief = 55 + game.stable.restBonus;

    return GameScreen(
      title: 'Rest day',
      subtitle:
          '${racer.name} takes the day off. '
          'Fatigue drops by $relief.',
      plate: Plates.scene(0),
      onBack: () => Navigator.of(context).maybePop(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Panel(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: BreathingBird(
                        pose: Sprites.poseCalm,
                        plume: racer.plume,
                        size: 132,
                      ),
                    ),
                  ),
                  MeterBar(
                    value: racer.fatigue,
                    max: 100,
                    tint: racer.fatigue > 60 ? Palette.bad : Palette.warn,
                    label: 'Fatigue now',
                  ),
                  const SizedBox(height: 6),
                  MeterBar(
                    value: (racer.fatigue - relief).clamp(0, 100),
                    max: 100,
                    tint: Palette.stamina,
                    label: 'After resting',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(
                    'Treatment',
                    subtitle: 'One injury can be worked on.',
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: treatable.isEmpty
                        ? const EmptyNote(
                            'Sound in every leg. Nothing to fix.',
                            icon: Icons.check_circle_outline_rounded,
                          )
                        : ListView.separated(
                            itemCount: treatable.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final injury = treatable[i];
                              return Panel(
                                selected: _selectedInjury == injury.id,
                                accent: Palette.bad,
                                padding: const EdgeInsets.all(10),
                                onTap: () => setState(
                                  () => _selectedInjury =
                                      _selectedInjury == injury.id
                                      ? null
                                      : injury.id,
                                ),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      Sprites.remedy(injury.remedySprite),
                                      width: 34,
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            injury.name,
                                            style: Type.title(13),
                                          ),
                                          Text(
                                            injury.blurb,
                                            style: Type.text(10.5),
                                          ),
                                          Text(
                                            injury.mods.describe(),
                                            style: Type.text(
                                              10,
                                              color: Palette.bad,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: _selectedInjury == null
                        ? 'Rest only'
                        : 'Rest and treat',
                    icon: Icons.bedtime_rounded,
                    expand: true,
                    onTap: () {
                      game.rest(healInjuryId: _selectedInjury);
                      Navigator.of(context).pop();
                    },
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
