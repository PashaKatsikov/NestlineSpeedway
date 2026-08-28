import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/widgets/bird_view.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';

/// A rest day: clear fatigue, and treat one injury if there is one to treat.
class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  String? _selectedInjury;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();
    final racer = game.activeRacer;
    if (racer == null) {
      return const Scaffold(body: VacantNote('Nobody to rest.'));
    }

    final treatable = racer.injuryList
        .where((i) => !i.careerEnding)
        .toList(growable: false);
    final relief = 55 + game.stable.restBonus;

    return Stage(
      title: 'Rest day',
      subtitle:
          '${racer.name} takes the day off. '
          'Fatigue drops by $relief.',
      plate: Backdrops.scene(0),
      onBack: () => Navigator.of(context).maybePop(),
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
                        pose: Atlas.poseCalm,
                        plume: racer.plume,
                        size: 132,
                      ),
                    ),
                  ),
                  GaugeBar(
                    value: racer.fatigue,
                    max: 100,
                    tint: racer.fatigue > 60 ? Pigment.bad : Pigment.warn,
                    label: 'Fatigue now',
                  ),
                  const SizedBox(height: 6),
                  GaugeBar(
                    value: (racer.fatigue - relief).clamp(0, 100),
                    max: 100,
                    tint: Pigment.stamina,
                    label: 'After resting',
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
                  const PaneTitle(
                    'Treatment',
                    subtitle: 'One injury can be worked on.',
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: treatable.isEmpty
                        ? const VacantNote(
                            'Sound in every leg. Nothing to fix.',
                            icon: Icons.check_circle_outline_rounded,
                          )
                        : ListView.separated(
                            itemCount: treatable.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final injury = treatable[i];
                              return Pane(
                                selected: _selectedInjury == injury.id,
                                accent: Pigment.bad,
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
                                      Atlas.remedy(injury.remedySprite),
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
                                            style: Face.title(13),
                                          ),
                                          Text(
                                            injury.blurb,
                                            style: Face.text(10.5),
                                          ),
                                          Text(
                                            injury.mods.describe(),
                                            style: Face.text(
                                              10,
                                              color: Pigment.bad,
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
                  LeadButton(
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
