import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../core/sprites.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import 'minigames/egg_catch_game.dart';
import 'minigames/memory_game.dart';
import 'minigames/tap_game.dart';
import 'shops.dart';

class MiniGamesMenuScreen extends StatelessWidget {
  const MiniGamesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = [
      _Game('Egg Catch', 'Catch falling eggs in the basket!',
          Sprites.egg(3), AppColors.amber, () => const EggCatchGame()),
      _Game('Memory Match', 'Flip and match the egg pairs.',
          Sprites.egg(5), const Color(0xFF8A79F0), () => const MemoryGame()),
      _Game('Feed Frenzy', 'Tap the chicken as fast as you can!',
          Sprites.chicken(Sprites.moodExcited), AppColors.leaf,
          () => const TapGame()),
    ];
    return ShopScaffold(
      title: 'Mini-Games',
      icon: Icons.videogame_asset_rounded,
      background: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCDB8FF), Color(0xFF9E86F0)],
      ),
      body: Consumer<GameState>(
        builder: (context, game, _) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
            itemCount: games.length,
            itemBuilder: (context, i) {
              final g = games[i];
              return Panel(
                onTap: () => pushScreen(context, g.builder()),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              g.color.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Sprite(g.sprite),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(g.title, style: AppText.heading(17)),
                    const SizedBox(height: 2),
                    Text(g.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: AppText.text(11.5, color: AppColors.inkMute)),
                    const SizedBox(height: 8),
                    CandyButton(
                      gradient: AppGradients.gold,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 8),
                      onTap: () => pushScreen(context, g.builder()),
                      child: Text('Play',
                          style: AppText.heading(15, color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Game {
  final String title;
  final String subtitle;
  final String sprite;
  final Color color;
  final Widget Function() builder;
  _Game(this.title, this.subtitle, this.sprite, this.color, this.builder);
}
