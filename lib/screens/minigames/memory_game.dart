import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/sfx.dart';
import '../../core/sprites.dart';
import '../../services/audio_service.dart';
import '../../widgets/common.dart';
import 'game_result.dart';

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _Card {
  final int rarity;
  bool faceUp = false;
  bool matched = false;
  _Card(this.rarity);
}

class _MemoryGameState extends State<MemoryGame> {
  static const int pairs = 6;
  late List<_Card> _cards;
  int? _first;
  bool _busy = false;
  int _moves = 0;
  int _matched = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _cards = [
      for (int r = 0; r < pairs; r++) ...[_Card(r), _Card(r)]
    ]..shuffle();
    _first = null;
    _moves = 0;
    _matched = 0;
  }

  void _flip(int i) {
    if (_busy || _cards[i].faceUp || _cards[i].matched) return;
    setState(() => _cards[i].faceUp = true);
    AudioService.instance.play(Sfx.click, volume: 0.5);
    if (_first == null) {
      _first = i;
    } else {
      _moves++;
      final a = _cards[_first!];
      final b = _cards[i];
      if (a.rarity == b.rarity) {
        a.matched = true;
        b.matched = true;
        _matched++;
        _first = null;
        AudioService.instance.play(Sfx.eggCollect, volume: 0.6);
        if (_matched == pairs) _end();
      } else {
        _busy = true;
        Timer(const Duration(milliseconds: 700), () {
          setState(() {
            a.faceUp = false;
            b.faceUp = false;
            _first = null;
            _busy = false;
          });
        });
      }
    }
  }

  void _end() {
    final coins = (60 - _moves * 3).clamp(10, 60);
    Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      showGameResult(
        context,
        title: 'All Matched!',
        score: _moves,
        scoreLabel: 'Moves used',
        coins: coins,
        mood: 22,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFCDB8FF), Color(0xFF9E86F0)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        GameHudChip(
                            icon: Icons.style_rounded,
                            value: 'Moves $_moves',
                            color: const Color(0xFF8A79F0)),
                        const SizedBox(width: 8),
                        GameHudChip(
                            icon: Icons.check_circle_rounded,
                            value: '$_matched/$pairs',
                            color: AppColors.success),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: _cards.length,
                        itemBuilder: (context, i) => _CardView(
                          card: _cards[i],
                          onTap: () => _flip(i),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_started)
                Positioned.fill(
                  child: GameStartOverlay(
                    title: 'Memory Match',
                    hint: 'Flip two cards to find matching eggs.\nMatch all pairs in as few moves as possible!',
                    onStart: () => setState(() => _started = true),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  final _Card card;
  final VoidCallback onTap;
  const _CardView({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final up = card.faceUp || card.matched;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: up
              ? const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF3D6)])
              : AppGradients.gold,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: card.matched ? AppColors.success : Colors.white,
              width: card.matched ? 3 : 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.woodDark.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: up
            ? Sprite(Sprites.egg(card.rarity))
            : const Icon(Icons.egg_alt_rounded,
                color: Colors.white, size: 34),
      ),
    );
  }
}
