import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import '../data/progress_defs.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import 'shops.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Achievements',
      icon: Icons.emoji_events_rounded,
      background: AppGradients.gold,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          final done = game.claimedAchievements.length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Panel(
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: AppColors.goldDeep),
                      const SizedBox(width: 10),
                      Text('Unlocked $done / ${ProgressDefs.achievements.length}',
                          style: AppText.heading(16)),
                      const Spacer(),
                      Text('Tap ready badges to claim rewards',
                          style: AppText.text(11.5, color: AppColors.inkMute)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns(context) - 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: ProgressDefs.achievements.length,
                  itemBuilder: (context, i) {
                    final a = ProgressDefs.achievements[i];
                    final value = game.counter(a.metric);
                    final claimed = game.claimedAchievements.contains(a.id);
                    final ready = game.achievementReady(a);
                    final pct = (value / a.goal).clamp(0.0, 1.0);
                    return GestureDetector(
                      onTap: ready
                          ? () {
                              if (game.claimAchievement(a)) {
                                showFloatingMessage(
                                    context, '${a.name} unlocked! +${a.reward}',
                                    icon: Icons.emoji_events_rounded,
                                    color: AppColors.goldDeep);
                              }
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.creamCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: ready
                                  ? AppColors.gold
                                  : claimed
                                      ? AppColors.success
                                      : Colors.white,
                              width: ready ? 3 : 2),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.woodDark
                                    .withValues(alpha: 0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Opacity(
                              opacity: (claimed || ready) ? 1 : 0.5,
                              child: Sprite(Sprites.reward(a.badge),
                                  width: 48, height: 48),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(a.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.heading(14.5)),
                                  Text(a.desc,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.text(11,
                                          color: AppColors.inkMute)),
                                  const SizedBox(height: 5),
                                  if (claimed)
                                    const Pill('Claimed',
                                        color: AppColors.success,
                                        icon: Icons.check_rounded)
                                  else if (ready)
                                    Pill('Claim +${a.reward}',
                                        color: AppColors.gold,
                                        icon: Icons.card_giftcard_rounded)
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: pct,
                                              minHeight: 8,
                                              backgroundColor: Colors.black
                                                  .withValues(alpha: 0.08),
                                              valueColor:
                                                  const AlwaysStoppedAnimation(
                                                      AppColors.gold),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('$value/${a.goal}',
                                            style: AppText.text(10.5,
                                                color: AppColors.inkSoft)),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
