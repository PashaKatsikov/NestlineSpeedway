import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import '../data/catalog.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import 'shops.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Egg Collection',
      icon: Icons.egg_rounded,
      background: AppGradients.cream,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          final discovered =
              Catalog.eggs.where((e) => (game.collectionSeen[e.index] ?? 0) > 0)
                  .length;
          final pct = discovered / Catalog.eggs.length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                child: Panel(
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.gold),
                      const SizedBox(width: 10),
                      Text('Discovered $discovered / ${Catalog.eggs.length}',
                          style: AppText.heading(16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 12,
                            backgroundColor: Colors.black.withValues(alpha: 0.08),
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.gold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${(pct * 100).round()}%',
                          style: AppText.heading(16, color: AppColors.goldDeep)),
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
                    childAspectRatio: 0.85,
                  ),
                  itemCount: Catalog.eggs.length,
                  itemBuilder: (context, i) {
                    final egg = Catalog.eggs[i];
                    final seen = game.collectionSeen[egg.index] ?? 0;
                    final found = seen > 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.creamCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: found
                                ? egg.color.withValues(alpha: 0.7)
                                : Colors.white,
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (found ? egg.color : AppColors.woodDark)
                                .withValues(alpha: found ? 0.28 : 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: found
                                    ? Sprite(Sprites.egg(egg.index))
                                    : ColorFiltered(
                                        colorFilter: const ColorFilter.mode(
                                            Colors.black45, BlendMode.srcIn),
                                        child: Opacity(
                                          opacity: 0.35,
                                          child: Sprite(Sprites.egg(egg.index)),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Text(found ? egg.name : '???',
                              style: AppText.heading(13.5)),
                          const SizedBox(height: 2),
                          Text(found ? 'Collected: $seen' : 'Undiscovered',
                              style:
                                  AppText.text(11, color: AppColors.inkMute)),
                          const SizedBox(height: 8),
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
