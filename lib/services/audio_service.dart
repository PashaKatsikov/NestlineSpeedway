import 'package:audioplayers/audioplayers.dart';

/// Lightweight SFX manager. Uses a small pool of players so overlapping sounds
/// don't cut each other off. Everything is bundled, so it works fully offline.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  static const int _poolSize = 4;
  final List<AudioPlayer> _pool =
      List.generate(_poolSize, (_) => AudioPlayer());
  int _next = 0;
  bool enabled = true;

  // Dedicated looping player for background music. It runs independently from
  // the SFX pool so music keeps playing in parallel with sound effects.
  final AudioPlayer _music = AudioPlayer();
  bool _musicStarted = false;

  Future<void> preload() async {
    // Configure a global audio context. This is required on iOS so the game
    // integrates properly with the system audio session and matches Android's
    // default behaviour (respects the media volume, mixes with other apps,
    // does not force-stop the user's music).
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
    } catch (_) {
      // If setting the audio context fails for any reason, fall back to the
      // plugin defaults instead of blocking startup.
    }
    for (final p in _pool) {
      await p.setReleaseMode(ReleaseMode.stop);
    }
  }

  /// Starts the looping background music. Safe to call multiple times — it only
  /// begins playback once and keeps looping forever.
  Future<void> startMusic(String assetPath, {double volume = 0.4}) async {
    if (_musicStarted) return;
    _musicStarted = true;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(volume);
      await _music.play(AssetSource(assetPath));
    } catch (_) {
      // Never let music failures interrupt gameplay.
      _musicStarted = false;
    }
  }

  Future<void> pauseMusic() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (!_musicStarted) return;
    try {
      await _music.resume();
    } catch (_) {}
  }

  Future<void> setMusicVolume(double volume) async {
    try {
      await _music.setVolume(volume);
    } catch (_) {}
  }

  Future<void> play(String assetPath, {double volume = 1.0}) async {
    if (!enabled) return;
    final player = _pool[_next];
    _next = (_next + 1) % _poolSize;
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Never let audio failures interrupt gameplay.
    }
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _music.dispose();
  }
}
