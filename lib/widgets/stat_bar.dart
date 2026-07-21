import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../data/items.dart';

/// A rounded, animated stat meter with an icon, used in the HUD.
class StatBar extends StatelessWidget {
  final Stat stat;
  final double value; // 0..100
  final double width;
  final bool compact;
  const StatBar({
    super.key,
    required this.stat,
    required this.value,
    this.width = 150,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / 100).clamp(0.0, 1.0);
    final color = stat.color;
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Container(
            width: compact ? 26 : 30,
            height: compact ? 26 : 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon, size: compact ? 15 : 18, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 2),
                    child: Text(stat.label,
                        style: AppText.text(10.5,
                            color: AppColors.inkSoft,
                            weight: FontWeight.w800)),
                  ),
                Stack(
                  children: [
                    Container(
                      height: compact ? 9 : 12,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    LayoutBuilder(builder: (context, c) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        height: compact ? 9 : 12,
                        width: c.maxWidth * pct,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Color.alphaBlend(
                                Colors.white.withValues(alpha: 0.4), color),
                            color,
                          ]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
