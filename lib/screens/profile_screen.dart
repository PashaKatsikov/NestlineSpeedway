import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../state/game_state.dart';
import '../widgets/chicken_view.dart';
import '../widgets/common.dart';
import 'shops.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Profile',
      icon: Icons.badge_rounded,
      background: AppGradients.screen,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          final stats = <_Stat>[
            _Stat('Level', '${game.level}', Icons.military_tech_rounded,
                AppColors.gold),
            _Stat('Happiness', '${game.happiness.round()}%',
                Icons.sentiment_very_satisfied_rounded, AppColors.mood),
            _Stat('Coop Comfort', '${game.comfort}', Icons.home_rounded,
                AppColors.leafDeep),
            _Stat('Eggs Collected', '${game.counter('eggsCollected')}',
                Icons.egg_rounded, AppColors.amber),
            _Stat('Eggs Sold', '${game.counter('eggsSold')}',
                Icons.sell_rounded, AppColors.orange),
            _Stat('Coins Earned', '${game.counter('coinsEarned')}',
                Icons.paid_rounded, AppColors.goldDeep),
            _Stat('Times Fed', '${game.counter('fed')}',
                Icons.restaurant_rounded, AppColors.hunger),
            _Stat('Times Petted', '${game.counter('pet')}',
                Icons.favorite_rounded, AppColors.health),
            _Stat('Mini-Games', '${game.counter('gamesPlayed')}',
                Icons.videogame_asset_rounded, const Color(0xFF8A79F0)),
            _Stat('Accessories', '${game.ownedAccessories.length}',
                Icons.checkroom_rounded, AppColors.trust),
            _Stat('Feather Skins', '${game.ownedSkins.length}',
                Icons.brush_rounded, const Color(0xFFEE6FB0)),
            _Stat('Achievements', '${game.claimedAchievements.length}',
                Icons.emoji_events_rounded, AppColors.goldDeep),
          ];
          return Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 6, 14),
                  child: Panel(
                    gradient: AppGradients.gold,
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: ChickenView(
                              moodSprite: game.moodSprite,
                              skinId: game.equippedSkin,
                              equipped: game.equipped,
                              size: MediaQuery.of(context).size.height * 0.38,
                            ),
                          ),
                        ),
                        Text(game.petName,
                            style: AppText.heading(22, color: Colors.white)),
                        Text('Level ${game.level} Chicken',
                            style: AppText.text(13, color: Colors.white)),
                        const SizedBox(height: 6),
                        _EditNameButton(game: game),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 2, 14, 18),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns(context) - 1,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.9,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, i) {
                    final s = stats[i];
                    return Panel(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: s.color.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(s.icon, color: s.color, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(s.value,
                                    style: AppText.heading(18,
                                        color: AppColors.ink)),
                                Text(s.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.text(11,
                                        color: AppColors.inkMute)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _Stat(this.label, this.value, this.icon, this.color);
}

class _EditNameButton extends StatelessWidget {
  final GameState game;
  const _EditNameButton({required this.game});

  @override
  Widget build(BuildContext context) {
    return CandyButton(
      gradient: const LinearGradient(colors: [Colors.white, Color(0xFFFFF1D0)]),
      shadow: AppColors.goldDeep,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      onTap: () => _showEdit(context, game),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_rounded, size: 16, color: AppColors.goldDeep),
          const SizedBox(width: 6),
          Text('Rename',
              style: AppText.heading(14, color: AppColors.goldDeep)),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context, GameState game) {
    final controller = TextEditingController(text: game.petName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.creamCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Name your chicken', style: AppText.heading(20)),
        content: TextField(
          controller: controller,
          maxLength: 14,
          style: AppText.text(16, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'Clucky',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppText.heading(15, color: AppColors.inkMute)),
          ),
          CandyButton(
            onTap: () {
              game.setName(controller.text);
              Navigator.pop(context);
            },
            child: Text('Save', style: AppText.heading(15, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
