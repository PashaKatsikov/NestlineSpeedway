import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import '../data/progress_defs.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import 'shops.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Daily Quests',
      icon: Icons.assignment_turned_in_rounded,
      background: AppGradients.orange,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            children: [
              Panel(
                gradient: AppGradients.gold,
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete quests each day for coins and XP. They refresh at midnight!',
                        style: AppText.text(13.5, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final id in game.dailyQuests)
                _QuestTile(quest: game.questById(id)),
            ],
          );
        },
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  final QuestTemplate quest;
  const _QuestTile({required this.quest});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final progress = game.questProgress(quest);
    final pct = (progress / quest.goal).clamp(0.0, 1.0);
    final claimed = game.claimedQuests.contains(quest.id);
    final ready = game.questReady(quest);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  claimed
                      ? Icons.check_rounded
                      : Icons.flag_rounded,
                  color: AppColors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quest.name, style: AppText.heading(16)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.orange),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$progress/${quest.goal}',
                          style:
                              AppText.text(12.5, color: AppColors.inkSoft)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Sprite(Sprites.coin, width: 16, height: 16),
                      const SizedBox(width: 3),
                      Text('${quest.coinReward}',
                          style: AppText.text(12, color: AppColors.goldDeep)),
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded,
                          size: 15, color: AppColors.leaf),
                      Text(' ${quest.xpReward} XP',
                          style: AppText.text(12, color: AppColors.leafDeep)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _ClaimButton(
              claimed: claimed,
              ready: ready,
              onTap: () {
                if (game.claimQuest(quest)) {
                  showFloatingMessage(context, 'Quest complete! Reward claimed',
                      icon: Icons.celebration_rounded, color: AppColors.orange);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final bool claimed;
  final bool ready;
  final VoidCallback onTap;
  const _ClaimButton(
      {required this.claimed, required this.ready, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (claimed) {
      return const Pill('Done', color: AppColors.success, icon: Icons.check);
    }
    return CandyButton(
      onTap: ready ? onTap : null,
      gradient: AppGradients.orange,
      shadow: AppColors.orange,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Text('Claim', style: AppText.heading(14, color: Colors.white)),
    );
  }
}
