import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/sfx.dart';
import 'pitlane/config/pitwall_config.dart';
import 'pitlane/infra/gate_exchange.dart';
import 'pitlane/infra/garage_vault.dart';
import 'pitlane/infra/paddock_attribution.dart';
import 'pitlane/infra/pulse_hub.dart';
import 'pitlane/infra/signal_probe.dart';
import 'pitlane/infra/track_agent.dart';
import 'pitlane/race_coordinator.dart';
import 'screens/loading_screen.dart';
import 'services/audio_service.dart';
import 'state/game_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loading screen may be portrait or landscape; gameplay locks to landscape
  // once the game begins (see lockLandscape()).
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final vault = GarageVault();
  final agent = TrackAgent();
  await Future.wait<void>(<Future<void>>[
    vault.initialize(),
    agent.prepare(),
  ]);

  assert(() {
    debugPrint(
      '[NSW.BOOT] credentialsReady=${PitwallConfig.grayCredentialsReady} '
      'endpoint=${PitwallConfig.endpoint} '
      'afKeyLen=${PitwallConfig.appsFlyerKey.length} '
      'fbNum=${PitwallConfig.firebaseProjectNumber}',
    );
    return true;
  }());

  var productionServicesReady = false;
  if (PitwallConfig.grayCredentialsReady) {
    try {
      await Firebase.initializeApp();
      productionServicesReady = true;
    } catch (error) {
      assert(() {
        debugPrint('[NSW.BOOT] Firebase.initializeApp failed: $error');
        return true;
      }());
    }
    if (productionServicesReady) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      } catch (error) {
        // App Check must never block FCM / gray routing.
        assert(() {
          debugPrint('[NSW.BOOT] AppCheck skipped: $error');
          return true;
        }());
      }
    }
  }

  final probe = SignalProbe();
  // Attribution + config POST run even if Firebase failed; only push needs
  // productionServicesReady.
  final notifications = PulseHub(vault, enabled: productionServicesReady);
  final attribution = PaddockAttribution(agent);
  final coordinator = RaceCoordinator(
    vault: vault,
    probe: probe,
    attribution: attribution,
    exchange: GateExchange(agent, vault),
    notifications: notifications,
    agent: agent,
    runtimeEnabled: PitwallConfig.grayCredentialsReady,
  );

  runApp(NestlineApp(coordinator: coordinator));
}

class NestlineApp extends StatefulWidget {
  const NestlineApp({super.key, this.coordinator});

  final RaceCoordinator? coordinator;

  @override
  State<NestlineApp> createState() => _NestlineAppState();
}

class _NestlineAppState extends State<NestlineApp> with WidgetsBindingObserver {
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
        home: LoadingScreen(coordinator: widget.coordinator),
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
  AudioService.instance.startMusic(Music.theme);
}
