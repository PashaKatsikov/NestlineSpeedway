import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/sfx.dart';
import '../../core/sprites.dart';
import '../../services/audio_service.dart';
import '../../widgets/common.dart';
import 'game_result.dart';

class TapGame extends StatefulWidget {
  const TapGame({super.key});

  @override
  State<TapGame> createState() => _TapGameState();
}

class _TapGameState extends State<TapGame> with TickerProviderStateMixin {
  static const int duration = 15;
  final _rng = Random();
  Timer? _clock;
  int _taps = 0;
  int _timeLeft = duration;
  bool _started = false;
  bool _over = false;
  final List<_Pop> _pops = [];

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    lowerBound: 0,
    upperBound: 1,
  );

  void _begin() {
    setState(() => _started = true);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _end();
    });
  }

  void _tap() {
    if (_over || !_started) return;
    setState(() {
      _taps++;
      _bounce.forward(from: 0);
      _pops.add(_Pop(
        0.3 + _rng.nextDouble() * 0.4,
        0.3 + _rng.nextDouble() * 0.3,
        _rng.nextBool(),
      ));
    });
    if (_taps % 5 == 0) {
      AudioService.instance.play(Sfx.happy, volume: 0.5);
    } else {
      AudioService.instance.play(Sfx.feeding, volume: 0.4);
    }
    Timer(const Duration(milliseconds: 650), () {
      if (mounted && _pops.isNotEmpty) setState(() => _pops.removeAt(0));
    });
  }

  void _end() {
    if (_over) return;
    _over = true;
    _clock?.cancel();
    final coins = (_taps * 0.3).round().clamp(5, 90);
    showGameResult(
      context,
      title: 'Feed Frenzy!',
      score: _taps,
      scoreLabel: 'Taps',
      coins: coins,
      mood: 28,
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chickenSize = MediaQuery.of(context).size.height * 0.5;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.leaf),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => _tap(),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _bounce,
                      builder: (context, child) {
                        final s =
                            1 + 0.12 * sin(_bounce.value * pi);
                        return Transform.scale(scale: s, child: child);
                      },
                      child: Sprite(
                        Sprites.chicken(Sprites.moodExcited),
                        width: chickenSize,
                        height: chickenSize,
                      ),
                    ),
                  ),
                ),
              ),
              for (final p in _pops)
                Positioned(
                  left: MediaQuery.of(context).size.width * p.x,
                  top: MediaQuery.of(context).size.height * p.y,
                  child: _PopWidget(coin: p.coin),
                ),
              Positioned(
                top: 8,
                left: 8,
                child: RoundIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
              Positioned(
                top: 8,
                right: 12,
                child: Row(
                  children: [
                    GameHudChip(
                        icon: Icons.touch_app_rounded,
                        value: '$_taps',
                        color: AppColors.leafDeep),
                    const SizedBox(width: 8),
                    GameHudChip(
                        icon: Icons.timer_rounded,
                        value: '$_timeLeft',
                        color: AppColors.orange),
                  ],
                ),
              ),
              if (!_started)
                Positioned.fill(
                  child: GameStartOverlay(
                    title: 'Feed Frenzy',
                    hint: 'Tap the chicken as fast as you can\nbefore the timer runs out!',
                    onStart: _begin,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pop {
  final double x;
  final double y;
  final bool coin;
  _Pop(this.x, this.y, this.coin);
}

class _PopWidget extends StatefulWidget {
  final bool coin;
  const _PopWidget({required this.coin});

  @override
  State<_PopWidget> createState() => _PopWidgetState();
}

class _PopWidgetState extends State<_PopWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

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
        return Opacity(
          opacity: (1 - _c.value).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -40 * _c.value),
            child: widget.coin
                ? Sprite(Sprites.coin, width: 34, height: 34)
                : const Icon(Icons.favorite_rounded,
                    color: AppColors.health, size: 30),
          ),
        );
      },
    );
  }
}
