import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/typography.dart';
import '../../state/game.dart';
import '../widgets/ui_kit.dart';
import 'about_screen.dart';
import 'intro_screen.dart';
import 'web_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();

    return GameScreen(
      title: 'Settings',
      plate: Plates.scene(7),
      onBack: () => Navigator.of(context).maybePop(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Audio'),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _Toggle(
                            label: 'Sound effects',
                            blurb: 'Race feedback, hatching, the trader.',
                            value: game.sfxOn,
                            onChanged: game.setSfx,
                          ),
                          _Toggle(
                            label: 'Music',
                            blurb: 'Bundled theme. Mixes with your own audio.',
                            value: game.musicOn,
                            onChanged: game.setMusic,
                          ),
                        ],
                      ),
                    ),
                  ),
                  GhostButton(
                    label: 'Privacy policy',
                    icon: Icons.privacy_tip_outlined,
                    compact: true,
                    onTap: () => Navigator.of(context).push(
                      gameRoute(
                        const WebScreen(
                          title: 'Privacy policy',
                          asset: 'assets/web/privacy.html',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GhostButton(
                    label: 'Help & support',
                    icon: Icons.help_outline_rounded,
                    compact: true,
                    onTap: () => Navigator.of(context).push(
                      gameRoute(
                        const WebScreen(
                          title: 'Help & support',
                          asset: 'assets/web/support.html',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GhostButton(
                    label: 'Replay the walkthrough',
                    icon: Icons.school_outlined,
                    compact: true,
                    onTap: () {
                      game.replayTutorial();
                      // Back to the menu first: the screens behind this one are
                      // already built and would not re-arm their coach marks
                      // until they are entered again from the top.
                      final navigator = Navigator.of(context)
                        ..popUntil((r) => r.isFirst);
                      navigator.push(gameRoute(const IntroScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  GhostButton(
                    label: 'About this game',
                    icon: Icons.info_outline_rounded,
                    compact: true,
                    onTap: () => Navigator.of(
                      context,
                    ).push(gameRoute(const AboutScreen())),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Stable record'),
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
                    style: Type.text(11, color: Palette.inkMute),
                  ),
                  const SizedBox(height: 10),
                  GhostButton(
                    label: 'Found a new stable',
                    icon: Icons.delete_outline_rounded,
                    tint: Palette.bad,
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

  void _confirmReset(BuildContext context, Game game) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.asphalt,
        title: Text('Start over?', style: Type.title(17)),
        content: Text(
          'Every bird, the whole pedigree, the Codex and the yard are erased. '
          'This cannot be undone.',
          style: Type.text(12),
        ),
        actions: [
          GhostButton(
            label: 'Keep my stable',
            compact: true,
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
          PrimaryButton(
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
                Text(label, style: Type.title(14)),
                Text(blurb, style: Type.text(10.5)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Palette.amber,
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
          Expanded(child: Text(label, style: Type.text(11.5))),
          Text(value, style: Type.number(13, color: Palette.amber)),
        ],
      ),
    );
  }
}
