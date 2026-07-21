import 'package:flutter/material.dart';

import '../core/sprites.dart';
import '../data/catalog.dart';
import '../data/items.dart';
import 'common.dart';

/// Renders the chicken with its equipped feather-skin tint and accessories,
/// plus a gentle idle breathing/bobbing animation and a tap bounce.
class ChickenView extends StatefulWidget {
  final int moodSprite;
  final String skinId;
  final Map<Slot, String?> equipped;
  final double size;
  final VoidCallback? onTap;
  const ChickenView({
    super.key,
    required this.moodSprite,
    required this.skinId,
    required this.equipped,
    this.size = 220,
    this.onTap,
  });

  @override
  State<ChickenView> createState() => _ChickenViewState();
}

class _ChickenViewState extends State<ChickenView>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    lowerBound: 0,
    upperBound: 1,
  );

  @override
  void dispose() {
    _idle.dispose();
    _bounce.dispose();
    super.dispose();
  }

  void _tap() {
    _bounce.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final skin = Catalog.skinById(widget.skinId);
    return GestureDetector(
      onTap: _tap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _bounce]),
        builder: (context, _) {
          final bob = (_idle.value - 0.5) * 8;
          final squish = 1 + 0.10 * (0.5 - (_bounce.value - 0.5).abs()) * 2;
          return Transform.translate(
            offset: Offset(0, bob),
            child: Transform.scale(
              scaleY: squish,
              scaleX: 2 - squish,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: _buildStack(skin),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStack(FeatherSkin skin) {
    final s = widget.size;
    final children = <Widget>[];

    // Companion (aura) that sits beside the pet renders behind.
    final aura = widget.equipped[Slot.aura];
    if (aura != null) {
      final idx = Catalog.accById(aura).sprite;
      if (idx >= 39) {
        children.add(Positioned(
          right: s * 0.02,
          bottom: s * 0.04,
          width: s * 0.34,
          child: Sprite(Sprites.accessory(idx)),
        ));
      }
    }

    // Base chicken.
    children.add(Positioned.fill(
      child: _tinted(Sprites.chicken(widget.moodSprite), skin),
    ));

    // Neck (bows / scarves).
    _overlay(children, Slot.neck, cx: 0.5, cy: 0.60, w: 0.52);
    // Eyes (glasses).
    _overlay(children, Slot.eyes, cx: 0.5, cy: 0.35, w: 0.5);
    // Head (hats / crowns).
    _overlay(children, Slot.head, cx: 0.5, cy: 0.11, w: 0.6);
    // Headphones (aura idx 36-38) sit over the head.
    if (aura != null) {
      final idx = Catalog.accById(aura).sprite;
      if (idx >= 36 && idx <= 38) {
        children.add(Positioned(
          left: s * 0.1,
          top: s * 0.06,
          width: s * 0.8,
          child: Sprite(Sprites.accessory(idx)),
        ));
      }
    }

    return Stack(clipBehavior: Clip.none, children: children);
  }

  void _overlay(List<Widget> children, Slot slot,
      {required double cx, required double cy, required double w}) {
    final id = widget.equipped[slot];
    if (id == null) return;
    final idx = Catalog.accById(id).sprite;
    final s = widget.size;
    final width = s * w;
    children.add(Positioned(
      left: s * cx - width / 2,
      top: s * cy - width / 2,
      width: width,
      height: width,
      child: Sprite(Sprites.accessory(idx)),
    ));
  }

  Widget _tinted(String asset, FeatherSkin skin) {
    final base = Sprite(asset, fit: BoxFit.contain);
    if (skin.tint == Colors.transparent || skin.tintStrength <= 0) return base;
    return Stack(
      fit: StackFit.expand,
      children: [
        base,
        Opacity(
          opacity: skin.tintStrength,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(skin.tint, BlendMode.srcIn),
            child: Sprite(asset, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}
