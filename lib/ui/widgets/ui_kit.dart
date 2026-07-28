import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/audio_service.dart';
import '../../core/palette.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../../core/typography.dart';

/// A dark panel with a hairline edge. The base surface for everything.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = Shape.rMd,
    this.accent,
    this.gradient,
    this.onTap,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? accent;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final edge = selected ? (accent ?? Palette.amber) : Palette.slate;
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? Grads.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: edge, width: selected ? 2 : 1),
        boxShadow: selected
            ? Shape.glow(accent ?? Palette.amber, 0.5)
            : Shape.lift(0.7),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Tappable(onTap: onTap, child: body);
  }
}

/// Tap wrapper that adds the click sound, a light haptic and a press scale.
class Tappable extends StatefulWidget {
  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.sound = Sfx.tap,
    this.volume = 0.55,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String sound;
  final double volume;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _down = true),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              setState(() => _down = false);
              HapticFeedback.selectionClick();
              AudioService.instance.play(widget.sound, volume: widget.volume);
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

/// The primary button: a chunky amber slab.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.gradient,
    this.compact = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Gradient? gradient;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final body = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 22,
        vertical: compact ? 8 : 13,
      ),
      decoration: BoxDecoration(
        gradient: enabled ? (gradient ?? Grads.amber) : null,
        color: enabled ? null : Palette.slate,
        borderRadius: BorderRadius.circular(Shape.rMd),
        boxShadow: enabled ? Shape.lift(0.8) : null,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 16 : 19,
              color: enabled ? Palette.inkOnLight : Palette.inkMute,
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Type.title(
                compact ? 14 : 17,
                color: enabled ? Palette.inkOnLight : Palette.inkMute,
              ),
            ),
          ),
        ],
      ),
    );
    return Tappable(onTap: onTap, child: body);
  }
}

/// Secondary button: outlined, quiet.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.tint,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? tint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? Palette.inkMute : (tint ?? Palette.inkSoft);
    return Tappable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 7 : 11,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Shape.rMd),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 15 : 17, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Type.text(compact ? 12.5 : 14, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round icon button, used for back arrows and close buttons.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tint,
    this.size = 38,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Palette.asphaltHi,
          shape: BoxShape.circle,
          border: Border.all(color: Palette.slateHi),
        ),
        child: Icon(icon, size: size * 0.5, color: tint ?? Palette.inkSoft),
      ),
    );
  }
}

/// A labelled value chip, the workhorse of every HUD in the game.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tint,
    this.iconAsset,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? iconAsset;
  final Color? tint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? Palette.amber;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: Palette.pitch.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Shape.rSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Image.asset(iconAsset!, width: compact ? 15 : 19),
            )
          else if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(icon, size: compact ? 14 : 16, color: color),
            ),
          Text(value, style: Type.number(compact ? 13 : 15, color: color)),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(label.toUpperCase(), style: Type.label(compact ? 8.5 : 9.5)),
          ],
        ],
      ),
    );
  }
}

/// Section heading with an optional trailing widget.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.subtitle});

  final String text;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: Type.title(19)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: Type.text(12)),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Screen scaffold: backdrop plate, dark scrim, a header row and a body.
class GameScreen extends StatelessWidget {
  const GameScreen({
    super.key,
    required this.title,
    required this.child,
    this.plate,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 14),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String? plate;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (plate != null)
            Image.asset(plate!, fit: BoxFit.cover)
          else
            const DecoratedBox(
              decoration: BoxDecoration(gradient: Grads.screen),
            ),
          if (plate != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Palette.pitch.withValues(alpha: 0.86),
                    Palette.pitch.withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (onBack != null) ...[
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: onBack,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: Type.title(23)),
                            if (subtitle != null)
                              Text(subtitle!, style: Type.text(12)),
                          ],
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty-state message used wherever a list can legitimately be empty.
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key, this.icon = Icons.inbox_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: Palette.inkMute),
          const SizedBox(height: 10),
          Text(text, style: Type.text(13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Slide-and-fade route used for every navigation in the game.
Route<T> gameRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 190),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
