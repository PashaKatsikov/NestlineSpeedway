/// Registry for every bundled image. Sprite sheets were cut once into
/// individual transparent PNGs under `assets/gen/<category>/`; the sheets
/// themselves live in `tool/sheets/` and are not shipped.
class Sprites {
  Sprites._();

  static const String _gen = 'assets/gen';

  static const int birdCount = 11;
  static const int eggCount = 7;
  static const int feedCount = 8;
  static const int remedyCount = 9;
  static const int trophyCount = 18;
  static const int stableCount = 33;
  static const int trainerCount = 15;
  static const int plumeCount = 16;
  static const int herbCount = 32;
  static const int tackCount = 42;

  static String bird(int i) => '$_gen/chicken/chicken_${i % birdCount}.png';
  static String egg(int i) => '$_gen/egg/egg_${i.clamp(0, eggCount - 1)}.png';
  static String feed(int i) => '$_gen/food/food_${i % feedCount}.png';
  static String remedy(int i) => '$_gen/care/care_${i % remedyCount}.png';
  static String trophy(int i) => '$_gen/reward/reward_${i % trophyCount}.png';
  static String stable(int i) => '$_gen/coop/coop_${i % stableCount}.png';
  static String trainer(int i) => '$_gen/toy/toy_${i % trainerCount}.png';
  static String plume(int i) => '$_gen/feather/feather_${i % plumeCount}.png';
  static String herb(int i) => '$_gen/plant/plant_${i % herbCount}.png';
  static String tack(int i) => '$_gen/accessory/accessory_${i % tackCount}.png';

  static const String transparent = '$_gen/misc/transparent.png';

  /// Bird poses, mapped to the eleven cut frames.
  static const int poseIdle = 0;
  static const int poseCheer = 1;
  static const int poseSprint = 2;
  static const int poseSpent = 3;
  static const int poseStartled = 4;
  static const int poseHurt = 5;
  static const int poseSpeckled = 6;
  static const int poseReady = 7;
  static const int poseCalm = 8;
  static const int poseWin = 9;
  static const int poseStrut = 10;

  static const String grain = '$_gen/reward/reward_0.png';
  static const String grainStack = '$_gen/reward/reward_2.png';
  static const String purse = '$_gen/reward/reward_4.png';
  static const String crate = '$_gen/reward/reward_14.png';
  static const String prize = '$_gen/reward/reward_16.png';

  static const String logo = 'assets/brand/logo.png';
}

/// Track backdrops. Three purpose-drawn landscape plates for racing, plus the
/// eight portrait scene plates used for stable and menu backdrops.
class Plates {
  Plates._();

  static const String trackDay = 'assets/art/tracks/sunhill.jpg';
  static const String trackNight = 'assets/art/tracks/midnight.jpg';
  static const String trackAutumn = 'assets/art/tracks/autumn.jpg';

  static const int sceneCount = 8;
  static String scene(int i) => 'assets/art/bg${(i % sceneCount) + 1}.webp';
}
