import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import 'common.dart';

/// A premium product / collectible card: glossy glass surface, an accent glow
/// halo behind the sprite, and a satisfying press animation.
class ItemCard extends StatefulWidget {
  final String sprite;
  final String title;
  final String? subtitle;
  final Widget footer;
  final bool locked;
  final bool selected;
  final bool owned;
  final Color accent;
  final VoidCallback? onTap;
  final String? cornerBadge;

  const ItemCard({
    super.key,
    required this.sprite,
    required this.title,
    required this.footer,
    this.subtitle,
    this.locked = false,
    this.selected = false,
    this.owned = false,
    this.accent = AppColors.gold,
    this.onTap,
    this.cornerBadge,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final sel = widget.selected;
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel:
          widget.onTap == null ? null : () => setState(() => _down = false),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.72),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: sel ? accent : Colors.white.withValues(alpha: 0.85),
              width: sel ? 3 : 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: (sel ? accent : AppColors.woodDark)
                    .withValues(alpha: sel ? 0.45 : 0.16),
                blurRadius: sel ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Accent glow halo behind sprite.
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.1),
                            radius: 0.9,
                            colors: [
                              accent.withValues(alpha: 0.26),
                              accent.withValues(alpha: 0.0),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(9),
                      child: Opacity(
                        opacity: widget.locked ? 0.42 : 1,
                        child: Sprite(widget.sprite),
                      ),
                    ),
                    if (widget.locked)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.woodDark.withValues(alpha: 0.62),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 1.5),
                            ),
                            child: const Icon(Icons.lock_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    if (widget.owned && !widget.locked)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            gradient: AppGradients.leaf,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.leafDeep
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    if (widget.cornerBadge != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Pill(widget.cornerBadge!, color: accent),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
                child: Text(widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppText.heading(14.5)),
              ),
              if (widget.subtitle != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppText.text(11, color: AppColors.inkMute)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                child: widget.footer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A glossy price tag with the coin sprite, or an owned/equipped state.
class PriceTag extends StatelessWidget {
  final int price;
  final bool affordable;
  const PriceTag({super.key, required this.price, this.affordable = true});

  @override
  Widget build(BuildContext context) {
    if (price == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.success.withValues(alpha: 0.22),
            AppColors.success.withValues(alpha: 0.12),
          ]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.5), width: 1.4),
        ),
        alignment: Alignment.center,
        child: Text('FREE',
            style: AppText.heading(14, color: AppColors.success)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: affordable ? AppGradients.gold : null,
        color: affordable ? null : const Color(0xFFE6DCCB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.white.withValues(alpha: affordable ? 0.6 : 0.3),
            width: 1.4),
        boxShadow: affordable
            ? [
                BoxShadow(
                    color: AppColors.goldDeep.withValues(alpha: 0.55),
                    offset: const Offset(0, 3),
                    blurRadius: 6)
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Sprite(Sprites.coin, width: 18, height: 18),
          const SizedBox(width: 4),
          Text('$price',
              style: AppText.heading(15,
                  color: affordable ? Colors.white : AppColors.inkMute)),
        ],
      ),
    );
  }
}
