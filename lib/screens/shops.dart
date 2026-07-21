import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import '../data/catalog.dart';
import '../data/items.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import '../widgets/item_card.dart';

/// Shared scaffold for grid-based shop/collection screens.
class ShopScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget body;
  final Gradient background;
  const ShopScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.body,
    this.background = AppGradients.screen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        gradient: background,
        child: Column(
          children: [
            Consumer<GameState>(
              builder: (context, game, _) => ScreenHeader(
                title: title,
                icon: icon,
                actions: [CoinChip(coins: game.coins)],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

int gridColumns(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w > 1100) return 6;
  if (w > 880) return 5;
  if (w > 640) return 4;
  return 3;
}

String effectText(Map<Stat, int> effects) => effects.entries
    .map((e) => '${e.value > 0 ? '+' : ''}${e.value} ${e.key.label}')
    .join('  ');

/// A green "Play" button used for already-owned toys.
class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: AppGradients.leaf,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.leafDeep.withValues(alpha: 0.5),
                offset: const Offset(0, 3)),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 2),
            Text('Play', style: AppText.heading(14, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class FoodShopScreen extends StatelessWidget {
  const FoodShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Feed',
      icon: Icons.restaurant_rounded,
      background: AppGradients.screen,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns(context),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: Catalog.foods.length,
            itemBuilder: (context, i) {
              final f = Catalog.foods[i];
              final locked = !game.isFoodUnlocked(f);
              final afford = game.coins >= f.price;
              return ItemCard(
                sprite: Sprites.food(f.sprite),
                title: f.name,
                subtitle: effectText(f.effects),
                accent: AppColors.hunger,
                locked: locked,
                cornerBadge: locked ? 'Lv ${f.unlockLevel}' : null,
                footer: PriceTag(price: f.price, affordable: afford || f.price == 0),
                onTap: locked
                    ? null
                    : () {
                        if (game.feed(f)) {
                          showFloatingMessage(context, 'Yum! ${f.name} served',
                              icon: Icons.restaurant_rounded,
                              color: AppColors.hunger);
                        } else {
                          showFloatingMessage(context, 'Not enough coins',
                              icon: Icons.info_rounded, color: AppColors.danger);
                        }
                      },
              );
            },
          );
        },
      ),
    );
  }
}

class CareShopScreen extends StatelessWidget {
  const CareShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Care & Spa',
      icon: Icons.spa_rounded,
      background: AppGradients.cream,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns(context),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: Catalog.care.length,
            itemBuilder: (context, i) {
              final c = Catalog.care[i];
              final locked = !game.isCareUnlocked(c);
              final afford = game.coins >= c.price;
              return ItemCard(
                sprite: Sprites.care(c.sprite),
                title: c.name,
                subtitle: '${c.verb} · ${effectText(c.effects)}',
                accent: AppColors.energy,
                locked: locked,
                cornerBadge: locked ? 'Lv ${c.unlockLevel}' : null,
                footer:
                    PriceTag(price: c.price, affordable: afford || c.price == 0),
                onTap: locked
                    ? null
                    : () {
                        if (game.useCare(c)) {
                          showFloatingMessage(
                              context, '${c.verb} complete — so fresh!',
                              icon: Icons.spa_rounded, color: AppColors.energy);
                        } else {
                          showFloatingMessage(context, 'Not enough coins',
                              icon: Icons.info_rounded, color: AppColors.danger);
                        }
                      },
              );
            },
          );
        },
      ),
    );
  }
}

class ToyShopScreen extends StatelessWidget {
  const ToyShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Toys & Play',
      icon: Icons.sports_esports_rounded,
      background: AppGradients.leaf,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns(context),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: Catalog.toys.length,
            itemBuilder: (context, i) {
              final t = Catalog.toys[i];
              final locked = game.level < t.unlockLevel;
              final owned = game.ownedToys.contains(t.id);
              final afford = game.coins >= t.price;
              return ItemCard(
                sprite: Sprites.toy(t.sprite),
                title: t.name,
                subtitle: '+${t.moodGain} Mood · -6 Energy',
                accent: AppColors.leaf,
                locked: locked,
                owned: owned,
                cornerBadge: locked ? 'Lv ${t.unlockLevel}' : null,
                footer: owned
                    ? _PlayButton(onTap: () {
                        game.playToy(t);
                        showFloatingMessage(
                            context, 'Wheee! Playing with ${t.name}',
                            icon: Icons.celebration_rounded,
                            color: AppColors.leaf);
                      })
                    : PriceTag(price: t.price, affordable: afford),
                onTap: locked || owned
                    ? null
                    : () {
                        if (game.buyToy(t)) {
                          showFloatingMessage(context, '${t.name} unlocked!',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.leaf);
                        } else {
                          showFloatingMessage(context, 'Not enough coins',
                              icon: Icons.info_rounded, color: AppColors.danger);
                        }
                      },
              );
            },
          );
        },
      ),
    );
  }
}
