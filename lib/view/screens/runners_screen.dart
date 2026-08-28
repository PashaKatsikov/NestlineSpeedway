import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/blood/runner.dart';
import 'package:nestline_circuit/heat/maneuvers.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/widgets/bird_view.dart';
import 'package:nestline_circuit/view/widgets/maneuver_card.dart';
import 'package:nestline_circuit/view/widgets/heredity_view.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';

/// The flock: every bird, her genome, her deck and her record.
class RunnersScreen extends StatefulWidget {
  const RunnersScreen({super.key});

  @override
  State<RunnersScreen> createState() => _RunnersScreenState();
}

class _RunnersScreenState extends State<RunnersScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();
    final birds = game.stable.racers;
    final selected =
        game.stable.byId(_selectedId) ?? (birds.isEmpty ? null : birds.first);

    return Stage(
      title: 'The flock',
      subtitle:
          '${game.stable.active.length} in work, '
          '${game.stable.retiredBirds.length} retired',
      plate: Backdrops.scene(3),
      onBack: () => Navigator.of(context).maybePop(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 244,
            child: birds.isEmpty
                ? const VacantNote('The stable is empty.')
                : ListView.separated(
                    itemCount: birds.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 7),
                    itemBuilder: (context, i) => RunnerCard(
                      racer: birds[i],
                      compact: true,
                      selected: birds[i].id == selected?.id,
                      onTap: () => setState(() => _selectedId = birds[i].id),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: selected == null
                ? const Pane(child: VacantNote('Nothing to show.'))
                : _RunnerDetail(racer: selected, game: game),
          ),
        ],
      ),
    );
  }
}

class _RunnerDetail extends StatelessWidget {
  const _RunnerDetail({required this.racer, required this.game});
  final Runner racer;
  final Director game;

  @override
  Widget build(BuildContext context) {
    final pheno = racer.basePhenotype;
    final deck = <String, int>{};
    for (final id in pheno.maneuverIds) {
      deck[id] = (deck[id] ?? 0) + 1;
    }

    return Pane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LivingBird(
                pose: racer.portraitPose,
                plume: racer.plume,
                size: 74,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(racer.name, style: Face.title(20)),
                    Text(
                      '${racer.lineageLabel} · rank ${racer.rank} · '
                      '${racer.wins} wins from ${racer.races} starts',
                      style: Face.text(11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      racer.genome.notation,
                      style: Face.text(10.5, color: Pigment.inkMute),
                    ),
                  ],
                ),
              ),
              if (!racer.careerOver)
                QuietButton(
                  label: 'Retire',
                  compact: true,
                  tint: Pigment.bad,
                  onTap: () => game.retireRacer(racer),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Text('GENOME', style: Face.label(8.5)),
                      const SizedBox(height: 6),
                      HeredityStrip(
                        racer: racer,
                        codex: game.stable.codex,
                        showGenotype: game.stable.showsGenotypes,
                      ),
                      const SizedBox(height: 8),
                      TraitStrip(phenotype: pheno),
                      if (racer.injuries.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('INJURIES', style: Face.label(8.5)),
                        const SizedBox(height: 5),
                        for (final injury in racer.injuryList)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Image.asset(
                                  Atlas.remedy(injury.remedySprite),
                                  width: 20,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${injury.name} — ${injury.blurb}',
                                    style: Face.text(10.5, color: Pigment.bad),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'DECK · ${pheno.maneuverIds.length} COMMANDS',
                        style: Face.label(8.5),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.separated(
                          itemCount: deck.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final entry = deck.entries.elementAt(i);
                            return ManeuverTile(
                              command: Maneuvers.byId(entry.key),
                              count: entry.value,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
