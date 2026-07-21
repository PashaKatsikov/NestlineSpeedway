import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/sfx.dart';
import '../../core/sprites.dart';
import '../../services/audio_service.dart';
import '../../widgets/common.dart';
import 'game_result.dart';

class EggCatchGame extends StatefulWidget {
  const EggCatchGame({super.key});

  @override
  State<EggCatchGame> createState() => _EggCatchGameState();
}

class _FallingEgg {
  double x; // 0..1
  double y; // px from top
  double speed;
  int rarity;
  bool caught = false;
  _FallingEgg(this.x, this.y, this.speed, this.rarity);
}

class _EggCatchGameState extends State<EggCatchGame> {
  static const int duration = 30;
  final _rng = Random();
  final List<_FallingEgg> _eggs = [];
  Timer? _loop;
  Timer? _spawner;
  Timer? _clock;

  double _basketX = 0.5;
  int _coins = 0;
  int _caught = 0;
  int _timeLeft = duration;
  Size _size = Size.zero;
  bool _started = false;
  bool _over = false;

  void _begin() {
    setState(() => _started = true);
    _loop = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    _spawn();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _end();
    });
  }

  void _spawn() {
    if (_over) return;
    _eggs.add(_FallingEgg(
      0.08 + _rng.nextDouble() * 0.84,
      -60,
      1.8 + _rng.nextDouble() * 2.0 + (duration - _timeLeft) * 0.05,
      _weightedRarity(),
    ));
    final next = 420 + _rng.nextInt(360);
    _spawner = Timer(Duration(milliseconds: next), _spawn);
  }

  int _weightedRarity() {
    final r = _rng.nextDouble();
    if (r > 0.96) return 5;
    if (r > 0.88) return 4;
    if (r > 0.72) return 3;
    if (r > 0.5) return 2;
    if (r > 0.25) return 1;
    return 0;
  }

  void _tick() {
    if (_size == Size.zero) return;
    final basketY = _size.height - 110;
    for (final e in _eggs) {
      if (e.caught) continue;
      e.y += e.speed;
      final ex = e.x * _size.width;
      if (e.y >= basketY && e.y <= basketY + 70) {
        if ((ex - _basketX * _size.width).abs() < 60) {
          e.caught = true;
          _caught++;
          final gain = 1 + e.rarity * 2;
          _coins += gain;
          AudioService.instance.play(
              e.rarity >= 4 ? Sfx.rareEgg : Sfx.coin,
              volume: 0.6);
        }
      }
    }
    _eggs.removeWhere((e) => e.caught || e.y > _size.height + 40);
    setState(() {});
  }

  void _end() {
    if (_over) return;
    _over = true;
    _loop?.cancel();
    _spawner?.cancel();
    _clock?.cancel();
    final mood = (10 + _caught).clamp(10, 34);
    showGameResult(
      context,
      title: 'Nice Catch!',
      score: _caught,
      scoreLabel: 'Eggs caught',
      coins: _coins,
      mood: mood,
    );
  }

  @override
  void dispose() {
    _loop?.cancel();
    _spawner?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.sky),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, c) {
            _size = Size(c.maxWidth, c.maxHeight);
            final basketY = c.maxHeight - 110;
            return Stack(
              children: [
                // Draggable play area.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) {
                      setState(() {
                        _basketX =
                            (d.localPosition.dx / c.maxWidth).clamp(0.05, 0.95);
                      });
                    },
                    onTapDown: (d) {
                      setState(() {
                        _basketX =
                            (d.localPosition.dx / c.maxWidth).clamp(0.05, 0.95);
                      });
                    },
                  ),
                ),
                for (final e in _eggs)
                  Positioned(
                    left: e.x * c.maxWidth - 22,
                    top: e.y,
                    child: Sprite(Sprites.egg(e.rarity), width: 44, height: 48),
                  ),
                // Basket.
                Positioned(
                  left: _basketX * c.maxWidth - 55,
                  top: basketY,
                  child: IgnorePointer(
                    child: Sprite(Sprites.coop(23), width: 110, height: 90),
                  ),
                ),
                // HUD.
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
                          icon: Icons.egg_rounded,
                          value: '$_caught',
                          color: AppColors.amber),
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
                      title: 'Egg Catch',
                      hint: 'Drag left and right to move the basket\nand catch the falling eggs!',
                      onStart: _begin,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
