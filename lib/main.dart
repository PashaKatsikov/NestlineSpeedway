import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/sfx.dart';
import 'screens/loading_screen.dart';
import 'services/audio_service.dart';
import 'state/game_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loading screen may be portrait or landscape; gameplay locks to landscape
  // later (handled when leaving the loading screen).
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const NestlineApp());
}

class NestlineApp extends StatefulWidget {
  const NestlineApp({super.key});

  @override
  State<NestlineApp> createState() => _NestlineAppState();
}

class _NestlineAppState extends State<NestlineApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      AudioService.instance.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      AudioService.instance.resumeMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        title: 'Nestline Speedway',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const LoadingScreen(),
      ),
    );
  }
}

/// Locks the app to landscape once gameplay begins.
Future<void> lockLandscape() async {
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

/// Warm up the audio players and start the looping background music once
/// (safe to call from the loading screen).
Future<void> warmUpAudio() async {
  await AudioService.instance.preload();
  // Fire-and-forget: background music loops forever, in parallel with SFX.
  AudioService.instance.startMusic(Music.theme);
}
