import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'shops.dart';
import 'web_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Settings',
      icon: Icons.settings_rounded,
      background: AppGradients.cream,
      body: Consumer<GameState>(
        builder: (context, game, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              _Section('Audio & Feel'),
              _ToggleTile(
                icon: Icons.volume_up_rounded,
                color: AppColors.gold,
                title: 'Sound Effects',
                subtitle: 'Chirps, coins and happy clucks',
                value: game.sfxOn,
                onChanged: game.setSfx,
              ),
              _ToggleTile(
                icon: Icons.vibration_rounded,
                color: AppColors.trust,
                title: 'Haptics',
                subtitle: 'Subtle vibration feedback',
                value: game.hapticsOn,
                onChanged: game.setHaptics,
              ),
              const SizedBox(height: 14),
              _Section('Information'),
              _LinkTile(
                icon: Icons.privacy_tip_rounded,
                color: AppColors.skyDeep,
                title: 'Privacy Policy',
                onTap: () =>
                    pushScreen(context, const WebScreen(page: WebPage.privacy)),
              ),
              _LinkTile(
                icon: Icons.support_agent_rounded,
                color: AppColors.leaf,
                title: 'Support',
                onTap: () =>
                    pushScreen(context, const WebScreen(page: WebPage.support)),
              ),
              _LinkTile(
                icon: Icons.info_rounded,
                color: AppColors.wood,
                title: 'About',
                onTap: () => pushScreen(context, const AboutScreen()),
              ),
              const SizedBox(height: 14),
              _Section('Danger Zone'),
              Panel(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restart_alt_rounded,
                          color: AppColors.danger),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reset Progress', style: AppText.heading(16)),
                          Text('Delete all coins, items and levels',
                              style:
                                  AppText.text(12, color: AppColors.inkMute)),
                        ],
                      ),
                    ),
                    CandyButton(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF7A6E), Color(0xFFEF4E42)]),
                      shadow: const Color(0xFFC5372D),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      onTap: () => _confirmReset(context, game),
                      child: Text('Reset',
                          style: AppText.heading(14, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text('Nestline Speedway · v1.0.0',
                    style: AppText.text(12, color: AppColors.inkMute)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmReset(BuildContext context, GameState game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.creamCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Reset everything?', style: AppText.heading(20)),
        content: Text(
            'This permanently deletes your chicken\u2019s progress. This cannot be undone.',
            style: AppText.text(14, color: AppColors.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppText.heading(15, color: AppColors.inkMute)),
          ),
          CandyButton(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF7A6E), Color(0xFFEF4E42)]),
            shadow: const Color(0xFFC5372D),
            onTap: () {
              game.resetProgress();
              Navigator.pop(context);
              showFloatingMessage(context, 'Progress reset',
                  icon: Icons.restart_alt_rounded, color: AppColors.danger);
            },
            child: Text('Reset', style: AppText.heading(15, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8, top: 2),
      child: Text(title,
          style: AppText.heading(15, color: AppColors.inkSoft)),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.heading(16)),
                  Text(subtitle,
                      style: AppText.text(12, color: AppColors.inkMute)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  const _LinkTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppText.heading(16))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkMute),
          ],
        ),
      ),
    );
  }
}
