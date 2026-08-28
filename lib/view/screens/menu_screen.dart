import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/widgets/bird_view.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';
import 'package:nestline_circuit/view/screens/primer_screen.dart';
import 'package:nestline_circuit/view/screens/options_screen.dart';
import 'package:nestline_circuit/view/screens/yard_screen.dart';

/// The main menu. Startup already happened on the loading screen, so this is the
/// root of the stack that every other screen is pushed onto.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<Director>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Backdrops.trackNight, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Pigment.pitch.withValues(alpha: 0.92),
                  Pigment.pitch.withValues(alpha: 0.55),
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
                    child: _FitOrScroll(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(Atlas.logo, width: 330),
                          const SizedBox(height: 6),
                          Text(
                            'A tactical racing roguelike.\n'
                            'Your command deck is the genome of the birds you breed.',
                            style: Face.text(13, color: Pigment.inkSoft),
                          ),
                          const SizedBox(height: 22),
                          LeadButton(
                            label: game.seasonActive
                                ? 'Continue season'
                                : 'Enter the stable',
                            icon: Icons.play_arrow_rounded,
                            onTap: () => Navigator.of(
                              context,
                            ).push(stageRoute(const YardScreen())),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              QuietButton(
                                label: 'Settings',
                                icon: Icons.tune_rounded,
                                compact: true,
                                onTap: () => Navigator.of(
                                  context,
                                ).push(stageRoute(const OptionsScreen())),
                              ),
                              const SizedBox(width: 10),
                              QuietButton(
                                label: 'About',
                                icon: Icons.info_outline_rounded,
                                compact: true,
                                onTap: () => Navigator.of(
                                  context,
                                ).push(stageRoute(const PrimerScreen())),
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
                      child: LivingBird(
                        pose: Atlas.poseStrut,
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
class _FitOrScroll extends StatelessWidget {
  const _FitOrScroll({required this.child});

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
