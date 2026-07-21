import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'achievements_screen.dart';
import 'backgrounds_screen.dart';
import 'collection_screen.dart';
import 'coop_screen.dart';
import 'decor_screen.dart';
import 'market_screen.dart';
import 'minigames_menu_screen.dart';
import 'profile_screen.dart';
import 'quests_screen.dart';
import 'settings_screen.dart';
import 'shops.dart';
import 'skins_screen.dart';
import 'wardrobe_screen.dart';
import 'web_screen.dart';

class _Dest {
  final String label;
  final IconData icon;
  final Color color;
  final Widget Function() builder;
  const _Dest(this.label, this.icon, this.color, this.builder);
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dests = <_Dest>[
      _Dest('Feed', Icons.restaurant_rounded, AppColors.hunger,
          () => const FoodShopScreen()),
      _Dest('Care & Spa', Icons.spa_rounded, AppColors.energy,
          () => const CareShopScreen()),
      _Dest('Toys', Icons.sports_esports_rounded, AppColors.leaf,
          () => const ToyShopScreen()),
      _Dest('Wardrobe', Icons.checkroom_rounded, AppColors.trust,
          () => const WardrobeScreen()),
      _Dest('Feather Skins', Icons.brush_rounded, Color(0xFFEE6FB0),
          () => const SkinsScreen()),
      _Dest('Coop Upgrades', Icons.home_rounded, AppColors.wood,
          () => const CoopScreen()),
      _Dest('Decorations', Icons.local_florist_rounded, AppColors.leafDeep,
          () => const DecorScreen()),
      _Dest('Scenes', Icons.image_rounded, AppColors.skyDeep,
          () => const BackgroundsScreen()),
      _Dest('Market', Icons.storefront_rounded, AppColors.gold,
          () => const MarketScreen()),
      _Dest('Egg Collection', Icons.egg_rounded, AppColors.amber,
          () => const CollectionScreen()),
      _Dest('Mini-Games', Icons.videogame_asset_rounded, Color(0xFF8A79F0),
          () => const MiniGamesMenuScreen()),
      _Dest('Daily Quests', Icons.assignment_turned_in_rounded,
          AppColors.orange, () => const QuestsScreen()),
      _Dest('Achievements', Icons.emoji_events_rounded, AppColors.goldDeep,
          () => const AchievementsScreen()),
      _Dest('Profile', Icons.badge_rounded, AppColors.health,
          () => const ProfileScreen()),
      _Dest('Settings', Icons.settings_rounded, AppColors.inkSoft,
          () => const SettingsScreen()),
      _Dest('Privacy Policy', Icons.privacy_tip_rounded, AppColors.skyDeep,
          () => const WebScreen(page: WebPage.privacy)),
      _Dest('Support', Icons.support_agent_rounded, AppColors.leaf,
          () => const WebScreen(page: WebPage.support)),
      _Dest('About', Icons.info_rounded, AppColors.wood,
          () => const AboutScreen()),
    ];

    return Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            Consumer<GameState>(
              builder: (context, game, _) => ScreenHeader(
                title: 'Menu',
                icon: Icons.grid_view_rounded,
                actions: [CoinChip(coins: game.coins)],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns(context),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: dests.length,
                itemBuilder: (context, i) {
                  final d = dests[i];
                  return _MenuTile(
                    dest: d,
                    onTap: () => pushScreen(context, d.builder()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _Dest dest;
  final VoidCallback onTap;
  const _MenuTile({required this.dest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      glow: dest.color,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                      Colors.white.withValues(alpha: 0.5), dest.color),
                  dest.color,
                ],
              ),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.6),
              boxShadow: [
                BoxShadow(
                    color: dest.color.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(dest.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            dest.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.heading(13.5),
          ),
        ],
      ),
    );
  }
}
