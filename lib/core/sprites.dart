/// Catalog of sliced sprite assets. Each sheet was auto-sliced into individual
/// transparent PNGs living under `assets/gen/<category>/<category>_<index>.png`.
class Sprites {
  Sprites._();

  static const String _gen = 'assets/gen';
  static const String _extra = 'assets/Nestline_Speedway_additional_assets';

  // Counts per sliced category.
  static const int chickenCount = 11;
  static const int eggCount = 7;
  static const int foodCount = 8;
  static const int careCount = 9;
  static const int rewardCount = 18;
  static const int coopCount = 33;
  static const int toyCount = 15;
  static const int featherCount = 16;
  static const int plantCount = 32;
  static const int accessoryCount = 42;

  static String chicken(int i) => '$_gen/chicken/chicken_$i.png';
  static String egg(int i) => '$_gen/egg/egg_$i.png';
  static String food(int i) => '$_gen/food/food_$i.png';
  static String care(int i) => '$_gen/care/care_$i.png';
  static String reward(int i) => '$_gen/reward/reward_$i.png';
  static String coop(int i) => '$_gen/coop/coop_$i.png';
  static String toy(int i) => '$_gen/toy/toy_$i.png';
  static String feather(int i) => '$_gen/feather/feather_$i.png';
  static String plant(int i) => '$_gen/plant/plant_$i.png';
  static String accessory(int i) => '$_gen/accessory/accessory_$i.png';

  // Named chicken moods -> sprite index (see slicing montage).
  static const int moodIdle = 0;
  static const int moodHappy = 1;
  static const int moodExcited = 2;
  static const int moodSleep = 3;
  static const int moodSurprised = 4;
  static const int moodSad = 5;
  static const int moodDirty = 6;
  static const int moodNeutral = 7;
  static const int moodContent = 8;
  static const int moodJoy = 9;
  static const int moodPlay = 10;

  // Coin sprite for currency displays (single chicken coin).
  static String get coin => reward(0);
  static String get coinStack => reward(2);
  static String get coinPile => reward(4);
  static String get treasureChest => reward(14);
  static String get giftBox => reward(16);

  static const String icon = '$_extra/Icon.png';
  static const String gameName = '$_extra/Game_Name.webp';
  static const String loadingVertical = '$_extra/Vertical_Loading_Screen.webp';
  static const String loadingHorizontal =
      '$_extra/Horizontal_Loading_Screen.webp';
}

/// The unlockable coop scene backgrounds (portrait scenic art, shown with
/// BoxFit.cover behind the gameplay).
class Backgrounds {
  Backgrounds._();
  static const String _gp = 'assets/Nestline_Speedway_gameplay_assets';
  static const int count = 8;
  static String bg(int i) => '$_gp/bg${i + 1}_asset.webp';

  static const List<String> names = [
    'Winter Loft',
    'Cozy Barn',
    'Sunny Coop',
    'Meadow Gate',
    'Golden Field',
    'Autumn Farm',
    'Blossom Vale',
    'Starry Night',
  ];
}
