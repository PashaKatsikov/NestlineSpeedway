import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';
import 'package:nestline_circuit/view/screens/primer_screen.dart';
import 'package:nestline_circuit/view/screens/opening_screen.dart';
import 'package:nestline_circuit/view/screens/document_screen.dart';

class OptionsScreen extends StatelessWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();

    return Stage(
      title: 'Settings',
      plate: Backdrops.scene(7),
      onBack: () => Navigator.of(context).maybePop(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Pane(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaneTitle('Audio'),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _Toggle(
                            label: 'Sound effects',
                            blurb: 'Race feedback, hatching, the trader.',
                            value: game.cuesOn,
                            onChanged: game.enableCues,
                          ),
                          _Toggle(
                            label: 'Music',
                            blurb: 'Bundled theme. Mixes with your own audio.',
                            value: game.scoreOn,
                            onChanged: game.enableScore,
                          ),
                        ],
                      ),
                    ),
                  ),
                  QuietButton(
                    label: 'Privacy policy',
                    icon: Icons.privacy_tip_outlined,
                    compact: true,
                    onTap: () => Navigator.of(context).push(
                      stageRoute(
                        const DocumentScreen(
                          title: 'Privacy policy',
                          asset: 'assets/docs/policy.html',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  QuietButton(
                    label: 'Help & support',
                    icon: Icons.help_outline_rounded,
                    compact: true,
                    onTap: () => Navigator.of(context).push(
                      stageRoute(
                        const DocumentScreen(
                          title: 'Help & support',
                          asset: 'assets/docs/help.html',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  QuietButton(
                    label: 'Replay the walkthrough',
                    icon: Icons.school_outlined,
                    compact: true,
                    onTap: () {
                      game.replayWalkthrough();
                      // Back to the menu first: the screens behind this one are
                      // already built and would not re-arm their coach marks
                      // until they are entered again from the top.
                      final navigator = Navigator.of(context)
                        ..popUntil((r) => r.isFirst);
                      navigator.push(stageRoute(const OpeningScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  QuietButton(
                    label: 'About this game',
                    icon: Icons.info_outline_rounded,
                    compact: true,
                    onTap: () => Navigator.of(
                      context,
                    ).push(stageRoute(const PrimerScreen())),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Pane(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaneTitle('Stable record'),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Stat('Seasons run', '${game.stable.seasonsRun}'),
                          _Stat('Grand Prix won', '${game.stable.seasonsWon}'),
                          _Stat('Races started', '${game.stable.totalRaces}'),
                          _Stat('Races won', '${game.stable.totalWins}'),
                          _Stat('Highest grade', '${game.stable.highestGrade}'),
                          _Stat('Codex', '${game.stable.codex.completion}%'),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    'No ads, no purchases, no accounts, no tracking. '
                    'Everything is stored on this device.',
                    style: Face.text(11, color: Pigment.inkMute),
                  ),
                  const SizedBox(height: 10),
                  QuietButton(
                    label: 'Found a new stable',
                    icon: Icons.delete_outline_rounded,
                    tint: Pigment.bad,
                    compact: true,
                    onTap: () => _confirmReset(context, game),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, Director game) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Pigment.asphalt,
        title: Text('Start over?', style: Face.title(17)),
        content: Text(
          'Every bird, the whole pedigree, the Codex and the yard are erased. '
          'This cannot be undone.',
          style: Face.text(12),
        ),
        actions: [
          QuietButton(
            label: 'Keep my stable',
            compact: true,
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
          LeadButton(
            label: 'Erase',
            compact: true,
            onTap: () {
              game.resetEverything();
              Navigator.of(dialogContext).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.blurb,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String blurb;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Face.title(14)),
                Text(blurb, style: Face.text(10.5)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Pigment.amber,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Face.text(11.5))),
          Text(value, style: Face.number(13, color: Pigment.amber)),
        ],
      ),
    );
  }
}
