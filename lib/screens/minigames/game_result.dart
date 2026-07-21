import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/sprites.dart';
import '../../state/game_state.dart';
import '../../widgets/common.dart';

/// Shows a celebratory result sheet, awards the coins/mood and returns to the
/// mini-games menu.
Future<void> showGameResult(
  BuildContext context, {
  required String title,
  required int score,
  required String scoreLabel,
  required int coins,
  required int mood,
}) async {
  context.read<GameState>().finishMiniGame(coins, mood);
  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.creamCard,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Sprite(Sprites.giftBox, width: 76, height: 76),
            const SizedBox(height: 6),
            Text(title, style: AppText.heading(24)),
            const SizedBox(height: 4),
            Text('$scoreLabel: $score',
                style: AppText.text(15, color: AppColors.inkSoft)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Sprite(Sprites.coin, width: 26, height: 26),
                  const SizedBox(width: 6),
                  Text('+$coins',
                      style: AppText.heading(22, color: Colors.white)),
                  const SizedBox(width: 14),
                  const Icon(Icons.sentiment_very_satisfied_rounded,
                      color: Colors.white),
                  const SizedBox(width: 4),
                  Text('+$mood',
                      style: AppText.heading(22, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CandyButton(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 12),
              onTap: () {
                Navigator.of(context).pop(); // dialog
                Navigator.of(context).maybePop(); // game screen
              },
              child:
                  Text('Collect', style: AppText.heading(17, color: Colors.white)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A reusable "tap to start" overlay for mini-games.
class GameStartOverlay extends StatelessWidget {
  final String title;
  final String hint;
  final VoidCallback onStart;
  const GameStartOverlay(
      {super.key,
      required this.title,
      required this.hint,
      required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.woodDark.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Panel(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppText.heading(28)),
            const SizedBox(height: 8),
            Text(hint,
                textAlign: TextAlign.center,
                style: AppText.text(14, color: AppColors.inkSoft)),
            const SizedBox(height: 18),
            CandyButton(
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 13),
              onTap: onStart,
              child: Text('Start',
                  style: AppText.heading(19, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small HUD chip used inside mini-games (score / timer).
class GameHudChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const GameHudChip(
      {super.key, required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDark.withValues(alpha: 0.16),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(value, style: AppText.heading(18, color: AppColors.ink)),
        ],
      ),
    );
  }
}
