import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/sprites.dart';
import '../data/catalog.dart';
import 'coop_screen.dart';
import 'shops.dart';

class DecorScreen extends StatelessWidget {
  const DecorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Decorations',
      icon: Icons.local_florist_rounded,
      background: AppGradients.leaf,
      body: CoopLikeGrid(
        items: Catalog.decor,
        decor: true,
        accent: AppColors.leafDeep,
        spriteFor: Sprites.plant,
      ),
    );
  }
}
