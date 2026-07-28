/// Sound keys, relative to the assets root as the audioplayers AssetSource API
/// expects.
class Sfx {
  Sfx._();
  static const String _s = 'sfx';

  static const String tap = '$_s/ui_tap.mp3';
  static const String denied = '$_s/denied.mp3';
  static const String grain = '$_s/grain.mp3';
  static const String trade = '$_s/trade.mp3';
  static const String unlock = '$_s/unlock.mp3';
  static const String build = '$_s/build.mp3';
  static const String objective = '$_s/objective.mp3';
  static const String rankUp = '$_s/rank_up.mp3';
  static const String victory = '$_s/victory.mp3';

  // Race feedback.
  static const String surge = '$_s/cluck_happy.mp3';
  static const String hurt = '$_s/hen_hurt.mp3';
  static const String blown = '$_s/hen_down.mp3';
  static const String feed = '$_s/feed.mp3';
  static const String cleanse = '$_s/cleanse.mp3';
  static const String soothe = '$_s/soothe.mp3';

  // Hatchery.
  static const String hatch = '$_s/hatch.mp3';
  static const String rareHatch = '$_s/rare_hatch.mp3';
  static const String egg = '$_s/egg_gain.mp3';
}

class Music {
  Music._();
  static const String theme = 'music/bg_theme.mp3';
}
