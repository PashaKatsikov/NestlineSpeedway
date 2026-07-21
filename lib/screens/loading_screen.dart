import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/sprites.dart';
import '../main.dart';
import '../state/game_state.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0;
  bool _initDone = false;
  bool _navigated = false;
  Timer? _ticker;
  final Stopwatch _watch = Stopwatch()..start();
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _startInit();
    // ~25 fps smooth driver.
    _ticker = Timer.periodic(const Duration(milliseconds: 40), (_) => _drive());
  }

  Future<void> _startInit() async {
    final game = context.read<GameState>();
    try {
      await Future.wait([
        game.init(),
        warmUpAudio(),
        Future.delayed(const Duration(milliseconds: 500)),
      ]);
    } catch (_) {
      // Never block startup on init errors — the game must open offline.
    }
    // Safety: even if something stalled, proceed.
    _initDone = true;
  }

  void _drive() {
    final ms = _watch.elapsedMilliseconds;
    // Nominal eased climb to 0.92 across ~2.4s so the bar fills in stages.
    final t = (ms / 2400).clamp(0.0, 1.0);
    final nominal = Curves.easeInOut.transform(t) * 0.92;
    // Hard safety: force completion path by 8s no matter what.
    final forced = ms > 8000;
    final target = (_initDone || forced) ? 1.0 : nominal;
    setState(() {
      _progress += (target - _progress) * 0.16;
      if (_progress > target) _progress = target;
      if ((_initDone || forced) && _progress > 0.992) {
        _progress = 1.0;
      }
    });
    if (_progress >= 1.0 && !_navigated) {
      _navigated = true;
      _ticker?.cancel();
      _finish();
    }
  }

  Future<void> _finish() async {
    await lockLandscape();
    // Brief beat at 100% so the full bar is visible right before launch.
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, a, _) =>
            FadeTransition(opacity: a, child: const HomeScreen()),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      precacheImage(const AssetImage(Sprites.loadingVertical), context);
      precacheImage(const AssetImage(Sprites.loadingHorizontal), context);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3D9A6),
      body: LayoutBuilder(
        builder: (context, c) {
          final portrait = c.maxHeight >= c.maxWidth;
          final bg = portrait
              ? Sprites.loadingVertical
              : Sprites.loadingHorizontal;
          final pct = (_progress * 100).round();
          return Stack(
            fit: StackFit.expand,
            children: [
              Sprite(bg, fit: BoxFit.cover),
              // Soft scrim at the bottom for text legibility.
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: c.maxHeight * (portrait ? 0.34 : 0.42),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.woodDark.withValues(alpha: 0.32),
                      ],
                    ),
                  ),
                ),
              ),
              _buildOverlay(c, portrait, pct),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverlay(BoxConstraints c, bool portrait, int pct) {
    final barWidth =
        portrait ? c.maxWidth * 0.72 : c.maxWidth * 0.42;
    final barHeight = portrait ? 22.0 : 15.0;
    final loadingSize = portrait ? 30.0 : 22.0;
    final pctSize = portrait ? 22.0 : 17.0;
    final bottomPad = portrait ? c.maxHeight * 0.13 : c.maxHeight * 0.09;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LoadingLabel(fontSize: loadingSize),
            SizedBox(height: portrait ? 16 : 10),
            _LoadingBar(
                width: barWidth, height: barHeight, progress: _progress),
            SizedBox(height: portrait ? 12 : 8),
            Text(
              '$pct%',
              style: AppText.heading(pctSize, color: Colors.white).copyWith(
                shadows: const [
                  Shadow(
                      color: Color(0x99000000),
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Loading" with animated trailing dots.
class _LoadingLabel extends StatefulWidget {
  final double fontSize;
  const _LoadingLabel({required this.fontSize});

  @override
  State<_LoadingLabel> createState() => _LoadingLabelState();
}

class _LoadingLabelState extends State<_LoadingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final dots = '.' * (1 + (_c.value * 3).floor() % 3);
        return Text(
          'Loading$dots',
          style: AppText.heading(widget.fontSize, color: Colors.white).copyWith(
            shadows: const [
              Shadow(color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
        );
      },
    );
  }
}

/// The horizontal progress bar that fills strictly left -> right.
class _LoadingBar extends StatelessWidget {
  final double width;
  final double height;
  final double progress;
  const _LoadingBar(
      {required this.width, required this.height, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDark.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: LayoutBuilder(builder: (context, c) {
          return Container(
            width: c.maxWidth * progress.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE58A), Color(0xFFFFB121)],
              ),
              borderRadius: BorderRadius.circular(height),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.7),
                  blurRadius: 6,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
