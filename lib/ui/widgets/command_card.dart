import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/typography.dart';
import '../../race/command.dart';
import 'ui_kit.dart';

/// A command in hand. Kept narrow enough that seven fit across a phone in
/// landscape without scrolling.
class CommandCard extends StatelessWidget {
  static const double _rulesSize = 9;
  static const double _rulesLeading = 1.25;

  const CommandCard({
    super.key,
    required this.command,
    this.playable = true,
    this.onTap,
    this.width = 116,
    this.selected = false,
  });

  final Command command;
  final bool playable;
  final VoidCallback? onTap;
  final double width;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tint = command.kind.tint;
    final dim = !playable;

    return Tappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: width,
        transform: Matrix4.translationValues(0, selected ? -10 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tint.withValues(alpha: dim ? 0.10 : 0.28),
              Palette.asphalt,
            ],
          ),
          borderRadius: BorderRadius.circular(Shape.rMd),
          border: Border.all(
            color: selected
                ? Palette.chalk
                : dim
                ? Palette.slate
                : tint.withValues(alpha: 0.65),
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected ? Shape.glow(tint, 0.6) : Shape.lift(0.6),
        ),
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
        // The hand gets whatever height is left after the track, so the card
        // scales itself: the sprite shrinks first, then the origin/type footer
        // goes, and the rules text takes only the lines that still fit.
        child: LayoutBuilder(
          builder: (context, box) {
            final room = box.maxHeight;
            final artHeight = room < 132 ? 22.0 : 34.0;
            final showFooter = room >= 116;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CostBadge(cost: command.effort, dim: dim),
                    const Spacer(),
                    Icon(
                      command.kind.icon,
                      size: 13,
                      color: dim ? Palette.inkMute : tint,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Center(
                  child: Opacity(
                    opacity: dim ? 0.4 : 1,
                    child: Image.asset(command.icon, height: artHeight),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  command.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Type.title(
                    12.5,
                    color: dim ? Palette.inkMute : Palette.ink,
                    spacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, textBox) {
                      const lineHeight = _rulesSize * _rulesLeading;
                      final lines = (textBox.maxHeight / lineHeight).floor();
                      if (lines < 1) return const SizedBox.shrink();
                      return Text(
                        command.text,
                        maxLines: lines,
                        overflow: TextOverflow.ellipsis,
                        style: Type.text(
                          _rulesSize,
                          color: dim ? Palette.inkMute : Palette.inkSoft,
                          height: _rulesLeading,
                        ),
                      );
                    },
                  ),
                ),
                if (showFooter) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: command.origin.tint.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          command.origin.label,
                          style: Type.text(8, color: command.origin.tint),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        command.kind.label,
                        style: Type.text(8, color: Palette.inkMute),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CostBadge extends StatelessWidget {
  const _CostBadge({required this.cost, required this.dim});
  final int cost;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: dim ? null : Grads.amber,
        color: dim ? Palette.slate : null,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$cost',
        style: Type.number(
          12,
          color: dim ? Palette.inkMute : Palette.inkOnLight,
        ),
      ),
    );
  }
}

/// Read-only card used by the Codex and the deck list.
class CommandTile extends StatelessWidget {
  const CommandTile({super.key, required this.command, this.count = 1});

  final Command command;
  final int count;

  @override
  Widget build(BuildContext context) {
    final tint = command.kind.tint;
    return Panel(
      padding: const EdgeInsets.all(9),
      child: Row(
        children: [
          Image.asset(command.icon, width: 30, height: 30),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        command.name,
                        overflow: TextOverflow.ellipsis,
                        style: Type.title(13),
                      ),
                    ),
                    if (count > 1) ...[
                      const SizedBox(width: 5),
                      Text(
                        '×$count',
                        style: Type.number(11, color: Palette.inkMute),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  command.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Type.text(9.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: Grads.amber,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${command.effort}',
                  style: Type.number(11, color: Palette.inkOnLight),
                ),
              ),
              const SizedBox(height: 3),
              Icon(command.kind.icon, size: 12, color: tint),
            ],
          ),
        ],
      ),
    );
  }
}
