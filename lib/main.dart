import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nestline_circuit/app/mixer.dart';
import 'package:nestline_circuit/app/look.dart';
import 'package:nestline_circuit/session/director.dart';
import 'package:nestline_circuit/view/screens/boot_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Startup deliberately runs unlocked so the loading screen can present itself
  // in whichever way the phone is being held. BootScreen locks to landscape
  // once the game is ready, because the race HUD needs the width.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const CircuitApp());
}

class CircuitApp extends StatefulWidget {
  const CircuitApp({super.key});

  @override
  State<CircuitApp> createState() => _CircuitAppState();
}

class _CircuitAppState extends State<CircuitApp>
    with WidgetsBindingObserver {
  final Director _game = Director();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Mixer.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        Mixer.instance.pauseMusic();
      case AppLifecycleState.resumed:
        if (_game.scoreOn) Mixer.instance.resumeMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Director>.value(
      value: _game,
      child: MaterialApp(
        title: 'Nestline Speedway',
        debugShowCheckedModeBanner: false,
        theme: Look.dark,
        home: const BootScreen(),
      ),
    );
  }
}
