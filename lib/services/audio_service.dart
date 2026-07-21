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
