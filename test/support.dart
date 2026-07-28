import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestline_speedway/meta/save.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An empty save, on an empty store, with the audio plugin stubbed out.
void freshSave() {
  silenceAudio();
  SharedPreferences.setMockInitialValues({});
  SaveService.instance.forgetStore();
}

/// Stubs the audio plugin so a test can boot the game.
///
/// `audioplayers` talks to the platform as soon as a player is constructed, and
/// there is no platform under `flutter test`. Left alone it surfaces as an
/// unhandled async error, which the runner reports against whichever test
/// happens to be running at the time.
void silenceAudio() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in const [
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.global',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(channel),
      (call) async => null,
    );
  }
}
