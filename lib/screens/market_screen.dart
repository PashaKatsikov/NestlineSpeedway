import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import '../data/catalog.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import 'shops.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Egg Market',
      icon: Icons.storefront_rounded,
      background: AppGradients.gold,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          final entries = game.basket.entries
              .where((e) => e.value > 0)
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          final total = entries.fold<int>(
              0, (s, e) => s + Catalog.eggs[e.key].value * e.value);

          if (entries.isEmpty) {
            return _EmptyMarket();
          }
          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns(context),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final rarity = entries[i].key;
                    final count = entries[i].value;
                    return _EggSellCard(
                      rarity: rarity,
                      count: count,
                      onSell: () {
                        final earned = game.sellRarity(rarity);
                        showFloatingMessage(context, '+$earned coins',
                            icon: Icons.paid_rounded, color: AppColors.gold);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: CandyButton(
                  gradient: AppGradients.leaf,
                  shadow: AppColors.leafDeep,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 14),
                  onTap: () {
                    final earned = game.sellAllEggs();
                    if (earned > 0) {
                      showFloatingMessage(context, 'Sold everything! +$earned coins',
                          icon: Icons.paid_rounded, color: AppColors.gold);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sell_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('Sell All  ·  $total',
                          style: AppText.heading(18, color: Colors.white)),
                      const SizedBox(width: 6),
                      Sprite(Sprites.coin, width: 22, height: 22),
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
}

class _EggSellCard extends StatelessWidget {
  final int rarity;
  final int count;
  final VoidCallback onSell;
  const _EggSellCard(
      {required this.rarity, required this.count, required this.onSell});

  @override
  Widget build(BuildContext context) {
    final egg = Catalog.eggs[rarity];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: egg.color.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: egg.color.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Sprite(Sprites.egg(rarity)),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Pill('x$count', color: egg.color),
                ),
              ],
            ),
          ),
          Text(egg.name, style: AppText.heading(13.5)),
          Text('${egg.value} each',
              style: AppText.text(11, color: AppColors.inkMute)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: GestureDetector(
              onTap: onSell,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.goldDeep.withValues(alpha: 0.5),
                        offset: const Offset(0, 3)),
                  ],
                ),
                alignment: Alignment.center,
                child: Text('Sell ${egg.value * count}',
                    style: AppText.heading(14, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMarket extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Sprite(Sprites.egg(0), width: 90, height: 90),
          const SizedBox(height: 12),
          Text('Your basket is empty',
              style: AppText.heading(20, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          Text('Keep your chicken happy to collect eggs,\nthen come back to sell them!',
              textAlign: TextAlign.center,
              style: AppText.text(14, color: AppColors.inkMute)),
        ],
      ),
    );
  }
}
