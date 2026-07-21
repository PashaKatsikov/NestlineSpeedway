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
import 'shops.dart';

/// Shared grid for coop upgrades and decorations (both add comfort).
class CoopLikeGrid extends StatelessWidget {
  final List<CoopItem> items;
  final bool decor;
  final String Function(int sprite) spriteFor;
  final Color accent;
  const CoopLikeGrid({
    super.key,
    required this.items,
    required this.decor,
    required this.spriteFor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, game, _) {
        final owned = decor ? game.ownedDecor : game.ownedCoop;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Panel(
                child: Row(
                  children: [
                    const Icon(Icons.spa_rounded, color: AppColors.leafDeep),
                    const SizedBox(width: 10),
                    Text('Coop Comfort',
                        style: AppText.heading(16)),
                    const Spacer(),
                    Pill('${game.comfort}',
                        color: AppColors.leafDeep,
                        icon: Icons.favorite_rounded),
                    const SizedBox(width: 8),
                    Text('More comfort → faster, rarer eggs',
                        style: AppText.text(11.5, color: AppColors.inkMute)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns(context),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final c = items[i];
                  final isOwned = owned.contains(c.id);
                  final locked = game.level < c.unlockLevel;
                  final afford = game.coins >= c.price;
                  return ItemCard(
                    sprite: spriteFor(c.sprite),
                    title: c.name,
                    subtitle: '+${c.comfort} comfort',
                    accent: accent,
                    owned: isOwned,
                    locked: locked && !isOwned,
                    cornerBadge:
                        (locked && !isOwned) ? 'Lv ${c.unlockLevel}' : null,
                    footer: isOwned
                        ? _OwnedTag()
                        : PriceTag(price: c.price, affordable: afford),
                    onTap: isOwned || locked
                        ? null
                        : () {
                            if (game.buyCoop(c, decor: decor)) {
                              showFloatingMessage(context, '${c.name} added!',
                                  icon: Icons.check_circle_rounded,
                                  color: accent);
                            } else {
                              showFloatingMessage(context, 'Not enough coins',
                                  icon: Icons.info_rounded,
                                  color: AppColors.danger);
                            }
                          },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OwnedTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text('Owned', style: AppText.heading(14, color: AppColors.success)),
    );
  }
}

class CoopScreen extends StatelessWidget {
  const CoopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Coop Upgrades',
      icon: Icons.home_rounded,
      background: AppGradients.screen,
      body: CoopLikeGrid(
        items: Catalog.coop,
        decor: false,
        accent: AppColors.wood,
        spriteFor: Sprites.coop,
      ),
    );
  }
}
