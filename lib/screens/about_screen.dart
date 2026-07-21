import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../core/sprites.dart';
import '../widgets/common.dart';
import 'shops.dart';
import 'web_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'About',
      icon: Icons.info_rounded,
      background: AppGradients.cream,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Sprite(Sprites.gameName, height: 130),
                const SizedBox(height: 6),
                Text(
                  'Raise the cutest chicken on the farm! Feed, groom and play with your\nfeathered friend, collect eggs of every rarity, dress it up and turn a tiny\ncoop into a cozy dream home.',
                  textAlign: TextAlign.center,
                  style: AppText.text(14.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 18),
                Panel(
                  child: Column(
                    children: [
                      _row('Version', '1.0.0'),
                      const Divider(height: 20),
                      _row('Developer', 'Nestline Speedway'),
                      const Divider(height: 20),
                      _row('Genre', 'Pet Care · Casual'),
                      const Divider(height: 20),
                      _row('Contact', 'support@nestlinnespeedway.com'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CandyButton(
                      gradient: AppGradients.sky,
                      shadow: AppColors.skyDeep,
                      onTap: () => pushScreen(
                          context, const WebScreen(page: WebPage.privacy)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.privacy_tip_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Privacy'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CandyButton(
                      gradient: AppGradients.leaf,
                      shadow: AppColors.leafDeep,
                      onTap: () => pushScreen(
                          context, const WebScreen(page: WebPage.support)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.support_agent_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Support'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Made with love for happy little chickens.',
                    style: AppText.text(12.5, color: AppColors.inkMute)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Row(
      children: [
        Text(k, style: AppText.heading(15, color: AppColors.inkSoft)),
        const Spacer(),
        Flexible(
          child: Text(v,
              textAlign: TextAlign.right,
              style: AppText.text(14, color: AppColors.ink)),
        ),
      ],
    );
  }
}
