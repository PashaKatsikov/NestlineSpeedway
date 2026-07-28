import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/typography.dart';
import '../../genetics/racer.dart';
import '../../race/command_library.dart';
import '../../state/game.dart';
import '../widgets/bird_view.dart';
import '../widgets/command_card.dart';
import '../widgets/genome_view.dart';
import '../widgets/ui_kit.dart';

/// The flock: every bird, her genome, her deck and her record.
class FlockScreen extends StatefulWidget {
  const FlockScreen({super.key});

  @override
  State<FlockScreen> createState() => _FlockScreenState();
}

class _FlockScreenState extends State<FlockScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();
    final birds = game.stable.racers;
    final selected =
        game.stable.byId(_selectedId) ?? (birds.isEmpty ? null : birds.first);

    return GameScreen(
      title: 'The flock',
      subtitle:
          '${game.stable.active.length} in work, '
          '${game.stable.retiredBirds.length} retired',
      plate: Plates.scene(3),
      onBack: () => Navigator.of(context).maybePop(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 244,
            child: birds.isEmpty
                ? const EmptyNote('The stable is empty.')
                : ListView.separated(
                    itemCount: birds.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 7),
                    itemBuilder: (context, i) => RacerCard(
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
                ? const Panel(child: EmptyNote('Nothing to show.'))
                : _RacerDetail(racer: selected, game: game),
          ),
        ],
      ),
    );
  }
}

class _RacerDetail extends StatelessWidget {
  const _RacerDetail({required this.racer, required this.game});
  final Racer racer;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final pheno = racer.basePhenotype;
    final deck = <String, int>{};
    for (final id in pheno.commandIds) {
      deck[id] = (deck[id] ?? 0) + 1;
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BreathingBird(
                pose: racer.portraitPose,
                plume: racer.plume,
                size: 74,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(racer.name, style: Type.title(20)),
                    Text(
                      '${racer.lineageLabel} · rank ${racer.rank} · '
                      '${racer.wins} wins from ${racer.races} starts',
                      style: Type.text(11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      racer.genome.notation,
                      style: Type.text(10.5, color: Palette.inkMute),
                    ),
                  ],
                ),
              ),
              if (!racer.careerOver)
                GhostButton(
                  label: 'Retire',
                  compact: true,
                  tint: Palette.bad,
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
                      Text('GENOME', style: Type.label(8.5)),
                      const SizedBox(height: 6),
                      GenomeStrip(
                        racer: racer,
                        codex: game.stable.codex,
                        showGenotype: game.stable.showsGenotypes,
                      ),
                      const SizedBox(height: 8),
                      TraitSummary(phenotype: pheno),
                      if (racer.injuries.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('INJURIES', style: Type.label(8.5)),
                        const SizedBox(height: 5),
                        for (final injury in racer.injuryList)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Image.asset(
                                  Sprites.remedy(injury.remedySprite),
                                  width: 20,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${injury.name} — ${injury.blurb}',
                                    style: Type.text(10.5, color: Palette.bad),
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
                        'DECK · ${pheno.commandIds.length} COMMANDS',
                        style: Type.label(8.5),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.separated(
                          itemCount: deck.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final entry = deck.entries.elementAt(i);
                            return CommandTile(
                              command: Commands.byId(entry.key),
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
