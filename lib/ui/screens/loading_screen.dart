import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_service.dart';
import '../../core/palette.dart';
import '../../core/sfx.dart';
import '../../core/sprites.dart';
import '../../core/typography.dart';
import '../../state/game.dart';
import '../widgets/bird_view.dart';
import '../widgets/ui_kit.dart';
import 'intro_screen.dart';
import 'title_screen.dart';

/// First screen the player sees, and the only one that works in either
/// orientation.
///
/// A phone picked up in portrait gets a portrait loading screen and rotating it
/// gives the landscape one. The game only commits to landscape once everything
/// is ready, because from that point on the race HUD needs the width.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  /// Art decoded up front so the first screens do not pop in piece by piece.
  static final List<String> _art = [
    Sprites.logo,
    Plates.trackDay,
    Plates.trackNight,
    Plates.trackAutumn,
    for (var i = 0; i < Plates.sceneCount; i++) Plates.scene(i),
    for (var i = 0; i < Sprites.birdCount; i++) Sprites.bird(i),
    for (var i = 0; i < Sprites.eggCount; i++) Sprites.egg(i),
  ];

  /// A bar that flashes past reads as a glitch, so the screen sticks around.
  /// The launch image cross-fades over roughly the first half of this, which is
  /// why it is longer than the work usually takes.
  static const Duration _minimumOnScreen = Duration(milliseconds: 1900);

  double _progress = 0;
  String _step = 'Waking the stable';
  bool _handedOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final game = context.read<Game>();
    final startedAt = DateTime.now();

    _report('Warming the engines', 0.06);
    await AudioService.instance.preload();

    _report('Reading the stud book', 0.2);
    await game.boot();

    await _precacheArt(from: 0.24, to: 0.97);

    _report('Rolling out', 1);

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minimumOnScreen) {
      await Future<void>.delayed(_minimumOnScreen - elapsed);
    }

    await _handOver(game);
  }

  Future<void> _precacheArt({required double from, required double to}) async {
    for (var i = 0; i < _art.length; i++) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(_art[i]), context);
      } catch (_) {
        // One undecodable frame is not a reason to refuse to start.
      }
      _report(
        'Painting the circuit',
        from + (to - from) * ((i + 1) / _art.length),
      );
    }
  }

  void _report(String step, double progress) {
    if (!mounted) return;
    setState(() {
      _step = step;
      _progress = progress;
    });
  }

  Future<void> _handOver(Game game) async {
    if (_handedOver || !mounted) return;
    _handedOver = true;

    // Three lanes, a terrain strip and a hand of command cards do not fit in
    // portrait, so the game locks to landscape from here on.
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (game.musicOn) AudioService.instance.startMusic(Music.theme);

    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushReplacement(gameRoute(const TitleScreen()));
    // Pushed on top of the title rather than replacing it, so closing the
    // opening leaves the player on the menu with the stack still rooted there.
    if (game.needsIntro) navigator.push(gameRoute(const IntroScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Plates.trackNight, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Palette.pitch.withValues(alpha: 0.72),
                  Palette.pitch.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
              child: OrientationBuilder(
                builder: (context, orientation) =>
                    orientation == Orientation.portrait
                    ? _portrait()
                    : _landscape(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _portrait() {
    return Column(
      children: [
        const Spacer(flex: 2),
        _logo(maxWidth: 380),
        const SizedBox(height: 10),
        _tagline(TextAlign.center),
        const Spacer(),
        const BreathingBird(pose: Sprites.poseStrut, plume: 1, size: 190),
        const Spacer(flex: 2),
        _ProgressBar(progress: _progress, label: _step),
        const SizedBox(height: 12),
        _rotateHint(TextAlign.center),
      ],
    );
  }

  Widget _landscape() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _logo(maxWidth: 340),
                    const SizedBox(height: 10),
                    _tagline(TextAlign.start),
                  ],
                ),
              ),
              const Expanded(
                flex: 4,
                child: Center(
                  child: BreathingBird(
                    pose: Sprites.poseStrut,
                    plume: 1,
                    size: 170,
                  ),
                ),
              ),
            ],
          ),
        ),
        _ProgressBar(progress: _progress, label: _step),
      ],
    );
  }

  Widget _logo({required double maxWidth}) {
    return LayoutBuilder(
      builder: (context, box) => Image.asset(
        Sprites.logo,
        width: box.maxWidth < maxWidth ? box.maxWidth : maxWidth,
      ),
    );
  }

  Widget _tagline(TextAlign align) {
    return Text(
      'A tactical racing roguelike.',
      textAlign: align,
      style: Type.text(13, color: Palette.inkSoft),
    );
  }

  Widget _rotateHint(TextAlign align) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.screen_rotation_rounded,
          size: 15,
          color: Palette.inkMute,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Turn your phone sideways to race.',
            textAlign: align,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Type.text(11.5, color: Palette.inkMute),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Type.text(12, color: Palette.inkSoft),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).round()}%',
              style: Type.number(13, color: Palette.amber),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 12,
            color: Palette.pitch.withValues(alpha: 0.8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                widthFactor: progress.clamp(0.02, 1),
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(gradient: Grads.amber),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
