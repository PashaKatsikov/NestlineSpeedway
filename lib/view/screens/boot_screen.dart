import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/mixer.dart';
import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/app/cues.dart';
import 'package:nestline_circuit/app/atlas.dart';
import 'package:nestline_circuit/app/face.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/widgets/bird_view.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';
import 'package:nestline_circuit/view/screens/opening_screen.dart';
import 'package:nestline_circuit/view/screens/menu_screen.dart';

/// First screen the player sees, and the only one that works in either
/// orientation.
///
/// A phone picked up in portrait gets a portrait loading screen and rotating it
/// gives the landscape one. The game only commits to landscape once everything
/// is ready, because from that point on the race HUD needs the width.
class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  /// Art decoded up front so the first screens do not pop in piece by piece.
  static final List<String> _art = [
    Atlas.logo,
    Backdrops.trackDay,
    Backdrops.trackNight,
    Backdrops.trackAutumn,
    for (var i = 0; i < Backdrops.sceneCount; i++) Backdrops.scene(i),
    for (var i = 0; i < Atlas.birdCount; i++) Atlas.bird(i),
    for (var i = 0; i < Atlas.eggCount; i++) Atlas.egg(i),
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
    final game = context.read<Director>();
    final startedAt = DateTime.now();

    _report('Warming the engines', 0.06);
    await Mixer.instance.preload();

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

  Future<void> _handOver(Director game) async {
    if (_handedOver || !mounted) return;
    _handedOver = true;

    // Three lanes, a terrain strip and a hand of command cards do not fit in
    // portrait, so the game locks to landscape from here on.
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (game.scoreOn) Mixer.instance.startMusic(Score.theme);

    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushReplacement(stageRoute(const MenuScreen()));
    // Pushed on top of the title rather than replacing it, so closing the
    // opening leaves the player on the menu with the stack still rooted there.
    if (game.needsIntro) navigator.push(stageRoute(const OpeningScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Backdrops.trackNight, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Pigment.pitch.withValues(alpha: 0.72),
                  Pigment.pitch.withValues(alpha: 0.88),
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
        const LivingBird(pose: Atlas.poseStrut, plume: 1, size: 190),
        const Spacer(flex: 2),
        _MeterTrack(progress: _progress, label: _step),
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
                  child: LivingBird(
                    pose: Atlas.poseStrut,
                    plume: 1,
                    size: 170,
                  ),
                ),
              ),
            ],
          ),
        ),
        _MeterTrack(progress: _progress, label: _step),
      ],
    );
  }

  Widget _logo({required double maxWidth}) {
    return LayoutBuilder(
      builder: (context, box) => Image.asset(
        Atlas.logo,
        width: box.maxWidth < maxWidth ? box.maxWidth : maxWidth,
      ),
    );
  }

  Widget _tagline(TextAlign align) {
    return Text(
      'A tactical racing roguelike.',
      textAlign: align,
      style: Face.text(13, color: Pigment.inkSoft),
    );
  }

  Widget _rotateHint(TextAlign align) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.screen_rotation_rounded,
          size: 15,
          color: Pigment.inkMute,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Turn your phone sideways to race.',
            textAlign: align,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Face.text(11.5, color: Pigment.inkMute),
          ),
        ),
      ],
    );
  }
}

class _MeterTrack extends StatelessWidget {
  const _MeterTrack({required this.progress, required this.label});

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
                style: Face.text(12, color: Pigment.inkSoft),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).round()}%',
              style: Face.number(13, color: Pigment.amber),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 12,
            color: Pigment.pitch.withValues(alpha: 0.8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                widthFactor: progress.clamp(0.02, 1),
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(gradient: Washes.amber),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
