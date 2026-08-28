import 'package:audioplayers/audioplayers.dart';

/// Sound playback. A small pool of players keeps overlapping effects from
/// cutting each other off, and music runs on its own player so the two never
/// interfere. Everything is bundled, so audio works with no network at all.
class Mixer {
  Mixer._();
  static final Mixer instance = Mixer._();

  static const int _poolSize = 4;

  final List<AudioPlayer> _pool = List.generate(
    _poolSize,
    (_) => AudioPlayer(),
  );
  final AudioPlayer _music = AudioPlayer();

  int _next = 0;
  bool enabled = true;
  bool _musicStarted = false;

  Future<void> preload() async {
    // iOS needs an explicit ambient session so the game mixes with whatever the
    // player is already listening to instead of stopping it.
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
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
      // Fall back to plugin defaults rather than blocking startup.
    }
    for (final p in _pool) {
      await p.setReleaseMode(ReleaseMode.stop);
    }
  }

  Future<void> startMusic(String assetPath, {double volume = 0.32}) async {
    if (_musicStarted) return;
    _musicStarted = true;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(volume);
      await _music.play(AssetSource(assetPath));
    } catch (_) {
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

  Future<void> play(String assetPath, {double volume = 1.0}) async {
    if (!enabled) return;
    final player = _pool[_next];
    _next = (_next + 1) % _poolSize;
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Audio failures must never interrupt a race.
    }
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _music.dispose();
  }
}
