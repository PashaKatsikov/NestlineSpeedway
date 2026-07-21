import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import '../data/catalog.dart';
import '../state/game_state.dart';
import '../widgets/chicken_view.dart';
import '../widgets/common.dart';
import '../widgets/item_card.dart';
import 'shops.dart';

class SkinsScreen extends StatelessWidget {
  const SkinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Feather Skins',
      icon: Icons.brush_rounded,
      background: AppGradients.cream,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          return Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 6, 14),
                  child: Panel(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFB6DE), Color(0xFFEE6FB0)],
                    ),
                    child: Column(
                      children: [
                        Text('Preview',
                            style: AppText.heading(16, color: Colors.white)),
                        Expanded(
                          child: Center(
                            child: ChickenView(
                              moodSprite: Sprites.moodContent,
                              skinId: game.equippedSkin,
                              equipped: const {},
                              size: MediaQuery.of(context).size.height * 0.4,
                            ),
                          ),
                        ),
                        Pill(Catalog.skinById(game.equippedSkin).name,
                            color: Colors.white, icon: Icons.brush_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 4, 14, 18),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns(context) - 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: Catalog.skins.length,
                  itemBuilder: (context, i) {
                    final s = Catalog.skins[i];
                    final owned = game.ownedSkins.contains(s.id);
                    final equipped = game.equippedSkin == s.id;
                    final afford = game.coins >= s.price;
                    return ItemCard(
                      sprite: Sprites.feather(s.sprite),
                      title: s.name,
                      accent: const Color(0xFFEE6FB0),
                      owned: owned,
                      selected: equipped,
                      footer: owned
                          ? _SkinTag(equipped: equipped)
                          : PriceTag(price: s.price, affordable: afford),
                      onTap: () {
                        if (owned) {
                          game.equipSkin(s);
                        } else if (game.buySkin(s)) {
                          game.equipSkin(s);
                          showFloatingMessage(context, '${s.name} unlocked!',
                              icon: Icons.auto_awesome_rounded,
                              color: const Color(0xFFEE6FB0));
                        } else {
                          showFloatingMessage(context, 'Not enough coins',
                              icon: Icons.info_rounded, color: AppColors.danger);
                        }
                      },
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

class _SkinTag extends StatelessWidget {
  final bool equipped;
  const _SkinTag({required this.equipped});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: equipped
            ? AppColors.success.withValues(alpha: 0.18)
            : const Color(0x22EE6FB0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: equipped ? AppColors.success : const Color(0xFFEE6FB0),
            width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(equipped ? 'Active' : 'Apply',
          style: AppText.heading(14,
              color: equipped ? AppColors.success : const Color(0xFFEE6FB0))),
    );
  }
}
