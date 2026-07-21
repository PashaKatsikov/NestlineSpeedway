import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import 'effects.dart';

/// Loads a sprite/image asset. Handles both .png (sliced) and .webp assets.
class Sprite extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  const Sprite(this.asset,
      {super.key, this.width, this.height, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => SizedBox(width: width, height: height),
    );
  }
}

/// A luminous frosted-glass panel. When a [gradient] is supplied it becomes a
/// glossy coloured panel; otherwise it renders as translucent glass with a
/// bright top sheen and a soft glow — the signature surface of the game.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Border? border;
  final bool blur;
  final Color glow;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = AppColors.creamCard,
    this.radius = 24,
    this.gradient,
    this.onTap,
    this.border,
    this.blur = false,
    this.glow = AppColors.woodDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool colored = gradient != null;
    Widget surface = Stack(
      children: [
        // Fill.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: colored
                  ? gradient
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.86),
                        Colors.white.withValues(alpha: 0.66),
                      ],
                    ),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
        // Top sheen highlight.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 42,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: colored ? 0.4 : 0.6),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            ),
          ),
        ),
        Padding(padding: padding, child: child),
      ],
    );

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: colored ? 0.5 : 0.75),
              width: 1.4,
            ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          if (colored)
            BoxShadow(
              color: (gradient as LinearGradient)
                  .colors
                  .last
                  .withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: blur
            ? BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: surface,
              )
            : surface,
      ),
    );

    if (onTap == null) return content;
    return _Pressable(onTap: onTap!, child: content);
  }
}

/// Adds a subtle press-scale to any tappable surface.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A glossy, tactile candy button with a bright gloss cap and a chunky 3D base.
class CandyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color shadow;
  const CandyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.gradient = AppGradients.gold,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
    this.radius = 22,
    this.shadow = AppColors.goldDeep,
  });

  @override
  State<CandyButton> createState() => _CandyButtonState();
}

class _CandyButtonState extends State<CandyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
        decoration: BoxDecoration(
          gradient: enabled
              ? widget.gradient
              : const LinearGradient(
                  colors: [Color(0xFFD9CFC2), Color(0xFFC3B6A6)]),
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: (enabled ? widget.shadow : const Color(0xFF9C8E7C))
                  .withValues(alpha: 1),
              offset: Offset(0, _down ? 1 : 6),
              blurRadius: 0,
            ),
            if (enabled)
              BoxShadow(
                color: widget.shadow.withValues(alpha: 0.5),
                offset: const Offset(0, 8),
                blurRadius: 16,
              ),
          ],
        ),
        child: Stack(
          children: [
            // Gloss cap on the top half.
            Positioned(
              left: 4,
              right: 4,
              top: 3,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(widget.radius),
                ),
              ),
            ),
            Padding(
              padding: widget.padding,
              child: DefaultTextStyle(
                style: AppText.heading(17, color: Colors.white),
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 20),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round glassy icon button (used for back/close/nav).
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.98),
              color.withValues(alpha: 0.82),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.85), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: AppColors.woodDark.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.ink, size: size * 0.5),
      ),
    );
  }
}

/// A luminous coin balance chip with a shimmering sweep.
class CoinChip extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;
  const CoinChip({super.key, required this.coins, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 4, 14, 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFF6DE)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.55), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Shimmer(
              color: const Color(0xFFFFF3C4),
              child: Sprite(Sprites.coin, width: 28, height: 28),
            ),
            const SizedBox(width: 6),
            GradientText(
              '$coins',
              gradient: AppGradients.gold,
              style: AppText.heading(18),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.add_circle_rounded,
                  color: AppColors.goldDeep, size: 20),
            ]
          ],
        ),
      ),
    );
  }
}

/// A themed enchanted background for secondary screens. The provided gradient
/// defines the colour family; drifting orbs and motes are derived from it.
class ScreenBackground extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  const ScreenBackground(
      {super.key, required this.child, this.gradient = AppGradients.screen});

  @override
  Widget build(BuildContext context) {
    final raw = gradient is LinearGradient
        ? (gradient as LinearGradient).colors
        : [AppColors.cream, AppColors.gold];
    // Soften toward a light pastel so vibrant screens stay readable behind
    // white glass cards, while keeping each screen's colour identity.
    final soft = [
      for (int i = 0; i < raw.length; i++)
        Color.alphaBlend(
            Colors.white.withValues(alpha: i == 0 ? 0.5 : 0.28), raw[i]),
    ];
    final orbs = [
      for (final c in raw.take(3))
        Color.alphaBlend(Colors.white.withValues(alpha: 0.45), c),
      Colors.white,
    ];
    return EnchantedBackground(
      colors: soft.length >= 2 ? soft : [soft.first, soft.first],
      orbs: orbs,
      child: SafeArea(child: child),
    );
  }
}

/// A consistent glassy header row for sub-screens.
class ScreenHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> actions;
  const ScreenHeader(
      {super.key,
      required this.title,
      this.icon = Icons.pets_rounded,
      this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.6),
              boxShadow: [
                BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.5),
                    blurRadius: 10),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GradientText(
              title,
              gradient: const LinearGradient(
                colors: [AppColors.woodDark, Color(0xFFB05A20)],
              ),
              style: AppText.heading(25),
              glow: [
                Shadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 8),
              ],
              maxLines: 1,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// A little frosted pill label.
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, {super.key, this.color = AppColors.gold, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.4),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: AppText.text(12.5,
                  color: Color.alphaBlend(
                      color.withValues(alpha: 0.9), AppColors.ink),
                  weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// A floating snackbar helper with a glassy card.
void showFloatingMessage(BuildContext context, String message,
    {IconData icon = Icons.check_circle_rounded,
    Color color = AppColors.success}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(milliseconds: 1500),
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF7E8)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: AppText.text(14.5, color: AppColors.ink)),
            ),
          ],
        ),
      ),
    ),
  );
}
