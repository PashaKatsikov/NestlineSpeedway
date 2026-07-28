import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'audio/audio_service.dart';
import 'core/theme.dart';
import 'state/game.dart';
import 'ui/screens/loading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Startup deliberately runs unlocked so the loading screen can present itself
  // in whichever way the phone is being held. LoadingScreen locks to landscape
  // once the game is ready, because the race HUD needs the width.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const NestlineSpeedwayApp());
}

class NestlineSpeedwayApp extends StatefulWidget {
  const NestlineSpeedwayApp({super.key});

  @override
  State<NestlineSpeedwayApp> createState() => _NestlineSpeedwayAppState();
}

class _NestlineSpeedwayAppState extends State<NestlineSpeedwayApp>
    with WidgetsBindingObserver {
  final Game _game = Game();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        AudioService.instance.pauseMusic();
      case AppLifecycleState.resumed:
        if (_game.musicOn) AudioService.instance.resumeMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Game>.value(
      value: _game,
      child: MaterialApp(
        title: 'Nestline Speedway',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const LoadingScreen(),
      ),
    );
  }
}
