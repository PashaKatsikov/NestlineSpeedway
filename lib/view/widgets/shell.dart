import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nestline_circuit/app/mixer.dart';
import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/cues.dart';
import 'package:nestline_circuit/app/look.dart';
import 'package:nestline_circuit/app/face.dart';

/// A dark panel with a hairline edge. The base surface for everything.
class Pane extends StatelessWidget {
  const Pane({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = Corners.rMd,
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
    final edge = selected ? (accent ?? Pigment.amber) : Pigment.slate;
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? Washes.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: edge, width: selected ? 2 : 1),
        boxShadow: selected
            ? Corners.glow(accent ?? Pigment.amber, 0.5)
            : Corners.lift(0.7),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Pressable(onTap: onTap, child: body);
  }
}

/// Tap wrapper that adds the click sound, a light haptic and a press scale.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.sound = Cue.tap,
    this.volume = 0.55,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String sound;
  final double volume;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
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
              Mixer.instance.play(widget.sound, volume: widget.volume);
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
class LeadButton extends StatelessWidget {
  const LeadButton({
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
        gradient: enabled ? (gradient ?? Washes.amber) : null,
        color: enabled ? null : Pigment.slate,
        borderRadius: BorderRadius.circular(Corners.rMd),
        boxShadow: enabled ? Corners.lift(0.8) : null,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 16 : 19,
              color: enabled ? Pigment.inkOnLight : Pigment.inkMute,
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Face.title(
                compact ? 14 : 17,
                color: enabled ? Pigment.inkOnLight : Pigment.inkMute,
              ),
            ),
          ),
        ],
      ),
    );
    return Pressable(onTap: onTap, child: body);
  }
}

/// Secondary button: outlined, quiet.
class QuietButton extends StatelessWidget {
  const QuietButton({
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
    final color = onTap == null ? Pigment.inkMute : (tint ?? Pigment.inkSoft);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 7 : 11,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Corners.rMd),
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
                style: Face.text(compact ? 12.5 : 14, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round icon button, used for back arrows and close buttons.
class OrbButton extends StatelessWidget {
  const OrbButton({
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
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Pigment.asphaltHi,
          shape: BoxShape.circle,
          border: Border.all(color: Pigment.slateHi),
        ),
        child: Icon(icon, size: size * 0.5, color: tint ?? Pigment.inkSoft),
      ),
    );
  }
}

/// A labelled value chip, the workhorse of every HUD in the game.
class StatMark extends StatelessWidget {
  const StatMark({
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
    final color = tint ?? Pigment.amber;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: Pigment.pitch.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Corners.rSm),
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
          Text(value, style: Face.number(compact ? 13 : 15, color: color)),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(label.toUpperCase(), style: Face.label(compact ? 8.5 : 9.5)),
          ],
        ],
      ),
    );
  }
}

/// Section heading with an optional trailing widget.
class PaneTitle extends StatelessWidget {
  const PaneTitle(this.text, {super.key, this.trailing, this.subtitle});

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
              Text(text, style: Face.title(19)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: Face.text(12)),
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
class Stage extends StatelessWidget {
  const Stage({
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
              decoration: BoxDecoration(gradient: Washes.screen),
            ),
          if (plate != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Pigment.pitch.withValues(alpha: 0.86),
                    Pigment.pitch.withValues(alpha: 0.94),
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
                        OrbButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: onBack,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: Face.title(23)),
                            if (subtitle != null)
                              Text(subtitle!, style: Face.text(12)),
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
class VacantNote extends StatelessWidget {
  const VacantNote(this.text, {super.key, this.icon = Icons.inbox_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: Pigment.inkMute),
          const SizedBox(height: 10),
          Text(text, style: Face.text(13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Slide-and-fade route used for every navigation in the game.
Route<T> stageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 170),
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
            begin: const Offset(0.018, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
