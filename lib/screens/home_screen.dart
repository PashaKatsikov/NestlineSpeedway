import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../core/sprites.dart';
import '../data/items.dart';
import '../state/game_state.dart';
import '../widgets/chicken_view.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/stat_bar.dart';
import 'menu_screen.dart';
import 'settings_screen.dart';
import 'shops.dart';
import 'market_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Consumer<GameState>(
        builder: (context, game, _) {
          final chickenSize = size.height * 0.52;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Scene background.
              Sprite(Backgrounds.bg(game.selectedBg), fit: BoxFit.cover),
              // Cinematic vignette + top/bottom scrims for legibility.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.1),
                    radius: 1.1,
                    colors: [Color(0x00000000), Color(0x40000000)],
                    stops: [0.62, 1.0],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.16),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              // Floating light motes over the scene.
              const Positioned.fill(child: MotesOverlay()),

              // Warm spotlight glow under the chicken.
              Align(
                alignment: const Alignment(0, 0.44),
                child: Container(
                  width: size.height * 0.62,
                  height: size.height * 0.22,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(size.height),
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.5),
                        AppColors.gold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Chicken standing centre.
              Align(
                alignment: const Alignment(0, 0.12),
                child: ChickenView(
                  moodSprite: game.moodSprite,
                  skinId: game.equippedSkin,
                  equipped: game.equipped,
                  size: chickenSize,
                  onTap: () {
                    game.pet();
                    _floatHeart(context);
                  },
                ),
              ),

              // Foreground UI: HUD on top, nest + dock along the bottom. Kept in
              // the top-most layer so the Collect button and eggs stay tappable.
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                  child: Column(
                    children: [
                      _TopBar(game: game),
                      const Spacer(),
                      _NestRow(game: game),
                      const SizedBox(height: 6),
                      _BottomDock(game: game),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _floatHeart(BuildContext context) {
    // Lightweight tap acknowledgement handled by chicken bounce + sfx.
  }
}

class _TopBar extends StatelessWidget {
  final GameState game;
  const _TopBar({required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileCard(game: game),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                CoinChip(
                  coins: game.coins,
                  onTap: () => pushScreen(context, const MarketScreen()),
                ),
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: Icons.settings_rounded,
                  onTap: () => pushScreen(context, const SettingsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StatsCard(game: game),
          ],
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final GameState game;
  const _ProfileCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final pct = (game.xp / game.xpForNext).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.96),
            Colors.white.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDark.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
                gradient: AppGradients.gold, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${game.level}',
                style: AppText.heading(20, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(game.petName, style: AppText.heading(17)),
              const SizedBox(height: 3),
              SizedBox(
                width: 120,
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    LayoutBuilder(builder: (context, c) {
                      return Container(
                        height: 8,
                        width: c.maxWidth * pct,
                        decoration: BoxDecoration(
                          gradient: AppGradients.leaf,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text('XP ${game.xp}/${game.xpForNext}',
                  style: AppText.text(9.5, color: AppColors.inkMute)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final GameState game;
  const _StatsCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.94),
            Colors.white.withValues(alpha: 0.74),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDark.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in Stat.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: StatBar(
                  stat: s, value: game.stats[s]!, width: 132, compact: true),
            ),
        ],
      ),
    );
  }
}

class _NestRow extends StatelessWidget {
  final GameState game;
  const _NestRow({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (game.nest.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withValues(alpha: 0.92),
                Colors.white.withValues(alpha: 0.74),
              ]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85), width: 1.4),
              boxShadow: [
                BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final r in game.nest.take(8))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Sprite(Sprites.egg(r), width: 24, height: 26),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: game.nest.isEmpty
              ? _EggProgress(fill: game.eggFill)
              : CandyButton(
                  gradient: AppGradients.leaf,
                  shadow: AppColors.leafDeep,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  onTap: game.collectAllEggs,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.egg_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text('Collect ${game.nest.length}',
                          style: AppText.heading(15, color: Colors.white)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _EggProgress extends StatelessWidget {
  final double fill;
  const _EggProgress({required this.fill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.white.withValues(alpha: 0.92),
          Colors.white.withValues(alpha: 0.74),
        ]),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.3),
        boxShadow: [
          BoxShadow(
              color: AppColors.woodDark.withValues(alpha: 0.16),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_bottom_rounded,
              size: 15, color: AppColors.inkSoft),
          const SizedBox(width: 6),
          SizedBox(
            width: 90,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: fill,
                minHeight: 8,
                backgroundColor: Colors.black.withValues(alpha: 0.08),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('Next egg',
              style: AppText.text(11, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  final GameState game;
  const _BottomDock({required this.game});

  @override
  Widget build(BuildContext context) {
    // FittedBox guarantees the whole dock always fits on screen so the outer
    // buttons (Feed / Menu) never overflow off the edges and stay tappable.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DockButton(
            label: 'Feed',
            icon: Icons.restaurant_rounded,
            gradient: AppGradients.orange,
            shadow: AppColors.orange,
            onTap: () => pushScreen(context, const FoodShopScreen()),
          ),
          const SizedBox(width: 12),
          _DockButton(
            label: 'Care',
            icon: Icons.spa_rounded,
            gradient: AppGradients.sky,
            shadow: AppColors.skyDeep,
            onTap: () => pushScreen(context, const CareShopScreen()),
          ),
          const SizedBox(width: 12),
          _DockButton(
            label: 'Play',
            icon: Icons.sports_esports_rounded,
            gradient: AppGradients.leaf,
            shadow: AppColors.leafDeep,
            onTap: () => pushScreen(context, const ToyShopScreen()),
          ),
          const SizedBox(width: 12),
          _DockButton(
            label: 'Menu',
            icon: Icons.grid_view_rounded,
            gradient: AppGradients.gold,
            shadow: AppColors.goldDeep,
            onTap: () => pushScreen(context, const MenuScreen()),
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final Color shadow;
  final VoidCallback onTap;
  const _DockButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.shadow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CandyButton(
      gradient: gradient,
      shadow: shadow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label, style: AppText.heading(15, color: Colors.white)),
        ],
      ),
    );
  }
}
