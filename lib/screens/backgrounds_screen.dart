import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import '../widgets/item_card.dart';
import 'shops.dart';

class BackgroundsScreen extends StatelessWidget {
  const BackgroundsScreen({super.key});

  static int priceFor(int index) => index == 0 ? 0 : 250 + index * 300;

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Coop Scenes',
      icon: Icons.image_rounded,
      background: AppGradients.sky,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns(context) - 1,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.86,
            ),
            itemCount: Backgrounds.count,
            itemBuilder: (context, i) {
              final unlocked = game.unlockedBg.contains(i);
              final selected = game.selectedBg == i;
              final price = priceFor(i);
              final afford = game.coins >= price;
              return GestureDetector(
                onTap: () {
                  if (unlocked) {
                    game.selectBackground(i);
                  } else if (game.unlockBackground(i, price)) {
                    showFloatingMessage(context, '${Backgrounds.names[i]} unlocked!',
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.skyDeep);
                  } else {
                    showFloatingMessage(context, 'Not enough coins',
                        icon: Icons.info_rounded, color: AppColors.danger);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? AppColors.gold : Colors.white,
                        width: selected ? 3 : 2),
                    boxShadow: [
                      BoxShadow(
                          color: (selected ? AppColors.gold : AppColors.woodDark)
                              .withValues(alpha: selected ? 0.4 : 0.16),
                          blurRadius: 12,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Sprite(Backgrounds.bg(i), fit: BoxFit.cover),
                      if (!unlocked)
                        Container(
                          color: AppColors.woodDark.withValues(alpha: 0.45),
                          child: const Center(
                            child: Icon(Icons.lock_rounded,
                                color: Colors.white, size: 30),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(Backgrounds.names[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.heading(14,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              if (selected)
                                const Pill('Active',
                                    color: AppColors.success,
                                    icon: Icons.check_rounded)
                              else if (unlocked)
                                const Pill('Tap to use', color: Colors.white)
                              else
                                SizedBox(
                                  width: 90,
                                  child: PriceTag(
                                      price: price, affordable: afford),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (selected)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 24),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
