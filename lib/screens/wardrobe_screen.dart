import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import '../data/catalog.dart';
import '../data/items.dart';
import '../state/game_state.dart';
import '../widgets/chicken_view.dart';
import '../widgets/common.dart';
import '../widgets/item_card.dart';
import 'shops.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  Slot _slot = Slot.head;

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Wardrobe',
      icon: Icons.checkroom_rounded,
      background: AppGradients.screen,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          final items =
              Catalog.accessories.where((a) => a.slot == _slot).toList();
          return Row(
            children: [
              // Live preview.
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.32,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 6, 14),
                  child: Panel(
                    gradient: AppGradients.sky,
                    child: Column(
                      children: [
                        Text('Preview',
                            style: AppText.heading(16, color: Colors.white)),
                        Expanded(
                          child: Center(
                            child: ChickenView(
                              moodSprite: Sprites.moodHappy,
                              skinId: game.equippedSkin,
                              equipped: game.equipped,
                              size: MediaQuery.of(context).size.height * 0.4,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final s in Slot.values)
                              if (game.equipped[s] != null)
                                Pill(Catalog.accById(game.equipped[s]!).name,
                                    color: Colors.white, icon: Icons.check),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _SlotTabs(
                      current: _slot,
                      onChanged: (s) => setState(() => _slot = s),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 8, 14, 18),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridColumns(context) - 1,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final a = items[i];
                          final owned = game.ownedAccessories.contains(a.id);
                          final equipped = game.equipped[a.slot] == a.id;
                          final locked = game.level < a.unlockLevel;
                          final afford = game.coins >= a.price;
                          return ItemCard(
                            sprite: Sprites.accessory(a.sprite),
                            title: a.name,
                            accent: AppColors.trust,
                            owned: owned,
                            selected: equipped,
                            locked: locked && !owned,
                            cornerBadge: (locked && !owned)
                                ? 'Lv ${a.unlockLevel}'
                                : null,
                            footer: owned
                                ? _EquipTag(equipped: equipped)
                                : PriceTag(price: a.price, affordable: afford),
                            onTap: () {
                              if (owned) {
                                game.equip(a);
                              } else if (locked) {
                                showFloatingMessage(
                                    context, 'Reach level ${a.unlockLevel}',
                                    icon: Icons.lock_rounded,
                                    color: AppColors.danger);
                              } else if (game.buyAccessory(a)) {
                                game.equip(a);
                                showFloatingMessage(
                                    context, '${a.name} unlocked & worn!',
                                    icon: Icons.auto_awesome_rounded,
                                    color: AppColors.trust);
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SlotTabs extends StatelessWidget {
  final Slot current;
  final ValueChanged<Slot> onChanged;
  const _SlotTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          for (final s in Slot.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onChanged(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: current == s ? AppGradients.gold : null,
                    color: current == s ? null : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.woodDark.withValues(alpha: 0.14),
                          blurRadius: 6,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Text(s.label,
                      style: AppText.heading(15,
                          color: current == s
                              ? Colors.white
                              : AppColors.inkSoft)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EquipTag extends StatelessWidget {
  final bool equipped;
  const _EquipTag({required this.equipped});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: equipped
            ? AppColors.success.withValues(alpha: 0.18)
            : AppColors.trust.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: equipped ? AppColors.success : AppColors.trust, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(equipped ? 'Worn' : 'Wear',
          style: AppText.heading(14,
              color: equipped ? AppColors.success : AppColors.trust)),
    );
  }
}
