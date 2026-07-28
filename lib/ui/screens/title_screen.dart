import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/palette.dart';
import '../../core/sprites.dart';
import '../../core/typography.dart';
import '../../state/game.dart';
import '../widgets/bird_view.dart';
import '../widgets/ui_kit.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'stable_screen.dart';

/// The main menu. Startup already happened on the loading screen, so this is the
/// root of the stack that every other screen is pushed onto.
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Game>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Plates.trackNight, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Palette.pitch.withValues(alpha: 0.92),
                  Palette.pitch.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _CenteredOrScrollable(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(Sprites.logo, width: 330),
                          const SizedBox(height: 6),
                          Text(
                            'A tactical racing roguelike.\n'
                            'Your command deck is the genome of the birds you breed.',
                            style: Type.text(13, color: Palette.inkSoft),
                          ),
                          const SizedBox(height: 22),
                          PrimaryButton(
                            label: game.seasonActive
                                ? 'Continue season'
                                : 'Enter the stable',
                            icon: Icons.play_arrow_rounded,
                            onTap: () => Navigator.of(
                              context,
                            ).push(gameRoute(const StableScreen())),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              GhostButton(
                                label: 'Settings',
                                icon: Icons.tune_rounded,
                                compact: true,
                                onTap: () => Navigator.of(
                                  context,
                                ).push(gameRoute(const SettingsScreen())),
                              ),
                              const SizedBox(width: 10),
                              GhostButton(
                                label: 'About',
                                icon: Icons.info_outline_rounded,
                                compact: true,
                                onTap: () => Navigator.of(
                                  context,
                                ).push(gameRoute(const AboutScreen())),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: BreathingBird(
                        pose: Sprites.poseStrut,
                        plume: 1,
                        size: 210,
                      ),
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

/// Centres [child] when there is room for it and scrolls it when there is not.
///
/// The title block is close to the height of a small phone in landscape, so a
/// plain centred column clips on the shortest screens.
class _CenteredOrScrollable extends StatelessWidget {
  const _CenteredOrScrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: child,
        ),
      ),
    );
  }
}
