/// Sound-effect asset keys (paths relative to the assets root, as required by
/// the audioplayers AssetSource API).
class Sfx {
  Sfx._();
  static const String _s = 'Nestline_Speedway_sounds_assets';

  static const String click = '$_s/click_button_asset.mp3';
  static const String coin = '$_s/coin_collection_asset.mp3';
  static const String eggCollect = '$_s/egg_collection_asset.mp3';
  static const String eggSpawn = '$_s/egg_spawning_asset.mp3';
  static const String errorBuy = '$_s/error_buy_asset.mp3';
  static const String feeding = '$_s/feeding_chicken_asset.mp3';
  static const String happy = '$_s/happy_chicken_asset.mp3';
  static const String levelUp = '$_s/level_up_asset.mp3';
  static const String petting = '$_s/petting_chicken_asset.mp3';
  static const String purchaseUpgrade = '$_s/purchase_upgrade_asset.mp3';
  static const String questComplete = '$_s/quest_completed_asset.mp3';
  static const String rareEgg = '$_s/rare_reward_egg_asset.mp3';
  static const String award = '$_s/Receiving_an_award_asset.mp3';
  static const String sad = '$_s/sad_chicken_asset.mp3';
  static const String sleep = '$_s/sleep_chicken_asset.mp3';
  static const String sell = '$_s/successful_selling_asset.mp3';
  static const String unlock = '$_s/unlock_item_asset.mp3';
  static const String washing = '$_s/washing_chicken_asset.mp3';
}

/// Looping background music (plays continuously, in parallel with SFX).
class Music {
  Music._();
  static const String theme = 'music/bg_theme.mp3';
}
