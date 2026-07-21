import 'package:flutter/material.dart';
import 'items.dart';

/// The master content catalog for the game. Everything purchasable, wearable,
/// collectible or spawnable is defined here so the rest of the app stays
/// data-driven.
class Catalog {
  Catalog._();

  // ---- Egg rarity ladder (7 sprites) --------------------------------------
  static const List<EggType> eggs = [
    EggType(0, 'Common Egg', 5, 46),
    EggType(1, 'Uncommon Egg', 13, 26),
    EggType(2, 'Rare Egg', 30, 15),
    EggType(3, 'Epic Egg', 70, 8),
    EggType(4, 'Legendary Egg', 155, 3.2),
    EggType(5, 'Mythic Egg', 340, 1.3),
    EggType(6, 'Divine Egg', 760, 0.5),
  ];

  // ---- Foods (8 sprites) --------------------------------------------------
  static const List<FoodItem> foods = [
    FoodItem('food_grain', 'Grain Mix', 0, 0, 1, {Stat.hunger: 22}),
    FoodItem('food_seeds', 'Seeds & Nuts', 1, 45, 1,
        {Stat.hunger: 30, Stat.energy: 6}),
    FoodItem('food_veggies', 'Fresh Veggies', 2, 70, 2,
        {Stat.hunger: 26, Stat.health: 14}),
    FoodItem('food_pellets', 'Health Pellets', 3, 110, 3,
        {Stat.hunger: 34, Stat.health: 10}),
    FoodItem('food_corn', 'Golden Corn', 4, 150, 4,
        {Stat.hunger: 40, Stat.mood: 8}),
    FoodItem('food_wheat', 'Wheat Bundle', 5, 200, 5,
        {Stat.hunger: 46, Stat.energy: 10}),
    FoodItem('food_trail', 'Nutty Trail Mix', 6, 280, 7,
        {Stat.hunger: 40, Stat.mood: 12, Stat.energy: 10}),
    FoodItem('food_mealworm', 'Mealworm Feast', 7, 420, 9,
        {Stat.hunger: 55, Stat.health: 16, Stat.mood: 14}),
  ];

  // ---- Care items (9 sprites) ---------------------------------------------
  static const List<CareItem> care = [
    CareItem('care_bucket', 'Water Bucket', 0, 0, 1,
        {Stat.health: 16, Stat.mood: 6}, 'Bathe'),
    CareItem('care_sponge', 'Soft Sponge', 1, 40, 1,
        {Stat.health: 20, Stat.mood: 8}, 'Scrub'),
    CareItem('care_brush', 'Grooming Brush', 2, 80, 2,
        {Stat.mood: 16, Stat.trust: 6}, 'Groom'),
    CareItem('care_towel', 'Cozy Towel', 3, 120, 3,
        {Stat.health: 14, Stat.energy: 10}, 'Dry'),
    CareItem('care_soap', 'Bubble Soap', 4, 160, 4,
        {Stat.health: 26, Stat.mood: 10}, 'Wash'),
    CareItem('care_duster', 'Feather Duster', 5, 90, 2,
        {Stat.mood: 12, Stat.trust: 8}, 'Tickle'),
    CareItem('care_comb', 'Wooden Comb', 6, 130, 3,
        {Stat.mood: 18, Stat.trust: 10}, 'Comb'),
    CareItem('care_spray', 'Fresh Spray', 7, 180, 5,
        {Stat.health: 22, Stat.mood: 12}, 'Freshen'),
    CareItem('care_pillow', 'Comfy Pillow', 8, 240, 6,
        {Stat.energy: 30, Stat.mood: 10}, 'Rest'),
  ];

  // ---- Toys (15 sprites) --------------------------------------------------
  static const List<ToyItem> toys = [
    ToyItem('toy_0', 'Chicky Plush', 0, 60, 1, 14),
    ToyItem('toy_1', 'Duck Buddy', 1, 90, 1, 15),
    ToyItem('toy_2', 'Winky Friend', 2, 120, 2, 16),
    ToyItem('toy_3', 'Specs Pal', 3, 150, 3, 17),
    ToyItem('toy_4', 'Egg Cushion', 4, 180, 3, 18),
    ToyItem('toy_5', 'Bow Buddy', 5, 210, 4, 19),
    ToyItem('toy_6', 'Polka Ball', 6, 130, 2, 16),
    ToyItem('toy_7', 'Star Ball', 7, 160, 3, 17),
    ToyItem('toy_8', 'Beach Ball', 8, 190, 4, 18),
    ToyItem('toy_9', 'Swirl Ball', 9, 220, 5, 19),
    ToyItem('toy_10', 'Rubber Ducky', 10, 250, 5, 20),
    ToyItem('toy_11', 'Fuzzy Chick', 11, 280, 6, 21),
    ToyItem('toy_12', 'Spinning Top', 12, 320, 7, 22),
    ToyItem('toy_13', 'Feather Wand', 13, 360, 8, 24),
    ToyItem('toy_14', 'Rope Knot', 14, 400, 9, 26),
  ];

  // ---- Accessories (42 sprites) -------------------------------------------
  static const List<Accessory> accessories = [
    // hats (0-7)
    Accessory('acc_0', 'Sunflower Straw', 0, 120, 1, Slot.head),
    Accessory('acc_1', 'Sailor Straw', 1, 140, 2, Slot.head),
    Accessory('acc_2', 'Wheat Straw', 2, 160, 3, Slot.head),
    Accessory('acc_3', 'Explorer Hat', 3, 220, 4, Slot.head),
    Accessory('acc_4', 'Checkered Cap', 4, 260, 5, Slot.head),
    Accessory('acc_5', 'Top Hat', 5, 420, 8, Slot.head),
    Accessory('acc_6', 'Lady Hat', 6, 360, 7, Slot.head),
    Accessory('acc_7', 'Pink Bonnet', 7, 300, 6, Slot.head),
    // bows (8-11) -> neck
    Accessory('acc_8', 'Polka Bow', 8, 90, 1, Slot.neck),
    Accessory('acc_9', 'Sunny Bow', 9, 110, 2, Slot.neck),
    Accessory('acc_10', 'Sky Bow', 10, 130, 3, Slot.neck),
    Accessory('acc_11', 'Grape Bow', 11, 150, 4, Slot.neck),
    // flower crowns (12-15) -> head
    Accessory('acc_12', 'Rose Crown', 12, 340, 6, Slot.head),
    Accessory('acc_13', 'Bluebell Crown', 13, 360, 7, Slot.head),
    Accessory('acc_14', 'Poppy Crown', 14, 380, 8, Slot.head),
    Accessory('acc_15', 'Daisy Crown', 15, 320, 6, Slot.head),
    // glasses (16-23) -> eyes
    Accessory('acc_16', 'Nerd Glasses', 16, 150, 3, Slot.eyes),
    Accessory('acc_17', 'Gold Rounds', 17, 260, 5, Slot.eyes),
    Accessory('acc_18', 'Heart Shades', 18, 240, 5, Slot.eyes),
    Accessory('acc_19', 'Star Shades', 19, 260, 6, Slot.eyes),
    Accessory('acc_20', 'Cat-Eye', 20, 280, 6, Slot.eyes),
    Accessory('acc_21', 'Retro Specs', 21, 200, 4, Slot.eyes),
    Accessory('acc_22', 'Violet Specs', 22, 220, 5, Slot.eyes),
    Accessory('acc_23', 'Aqua Rounds', 23, 240, 5, Slot.eyes),
    // scarves + bowties (24-31) -> neck
    Accessory('acc_24', 'Polka Scarf', 24, 170, 3, Slot.neck),
    Accessory('acc_25', 'Sunny Scarf', 25, 190, 4, Slot.neck),
    Accessory('acc_26', 'Plaid Scarf', 26, 210, 5, Slot.neck),
    Accessory('acc_27', 'Grape Scarf', 27, 230, 5, Slot.neck),
    Accessory('acc_28', 'Heart Bowtie', 28, 250, 6, Slot.neck),
    Accessory('acc_29', 'Dapper Bowtie', 29, 270, 6, Slot.neck),
    Accessory('acc_30', 'Leaf Bow', 30, 220, 5, Slot.neck),
    Accessory('acc_31', 'Sweet Bow', 31, 240, 5, Slot.neck),
    // crowns & laurels (32-35) -> head
    Accessory('acc_32', 'Gold Crown', 32, 900, 12, Slot.head),
    Accessory('acc_33', 'Silver Crown', 33, 700, 10, Slot.head),
    Accessory('acc_34', 'Pink Tiara', 34, 650, 10, Slot.head),
    Accessory('acc_35', 'Laurel Wreath', 35, 560, 9, Slot.head),
    // companions & headphones (36-41) -> aura
    Accessory('acc_36', 'Pink Beats', 36, 300, 6, Slot.aura),
    Accessory('acc_37', 'Blue Beats', 37, 300, 6, Slot.aura),
    Accessory('acc_38', 'Green Beats', 38, 300, 6, Slot.aura),
    Accessory('acc_39', 'Chick Pal', 39, 480, 9, Slot.aura),
    Accessory('acc_40', 'Buzzy Bee', 40, 520, 10, Slot.aura),
    Accessory('acc_41', 'Toadstool Pal', 41, 440, 8, Slot.aura),
  ];

  // ---- Feather skins (16 sprites) -----------------------------------------
  static const List<FeatherSkin> skins = [
    FeatherSkin('skin_white', 'Classic White', 0, 0, Colors.transparent, 0),
    FeatherSkin('skin_gold', 'Golden Plume', 1, 400,
        Color(0xFFFFC94D), 0.30),
    FeatherSkin('skin_rainbow', 'Rainbow Fluff', 2, 1200,
        Color(0xFFFF7AC8), 0.22),
    FeatherSkin('skin_pearl', 'Pearl Down', 3, 250,
        Color(0xFFEAD9FF), 0.20),
    FeatherSkin('skin_cocoa', 'Cocoa Speckle', 4, 300,
        Color(0xFFA9714B), 0.28),
    FeatherSkin('skin_peacock', 'Peacock Blue', 5, 900,
        Color(0xFF2E7BE0), 0.30),
    FeatherSkin('skin_violet', 'Violet Streak', 6, 700,
        Color(0xFF9B59D0), 0.30),
    FeatherSkin('skin_emerald', 'Emerald Tip', 7, 800,
        Color(0xFF2FBd8f), 0.28),
    FeatherSkin('skin_snow', 'Snow Fluff', 8, 200,
        Color(0xFFDDEEFF), 0.18),
    FeatherSkin('skin_cream', 'Cream Silk', 9, 220,
        Color(0xFFFFE9B0), 0.22),
    FeatherSkin('skin_sky', 'Sky Feather', 10, 500,
        Color(0xFF6EC6FF), 0.28),
    FeatherSkin('skin_blush', 'Blush Pink', 11, 550,
        Color(0xFFFF9EC4), 0.28),
    FeatherSkin('skin_amber', 'Amber Glow', 12, 600,
        Color(0xFFFFA23D), 0.30),
    FeatherSkin('skin_lime', 'Lime Zest', 13, 620,
        Color(0xFF8FD44A), 0.28),
    FeatherSkin('skin_lilac', 'Soft Lilac', 14, 640,
        Color(0xFFC9A6FF), 0.26),
    FeatherSkin('skin_honey', 'Honey Beam', 15, 680,
        Color(0xFFFFD24A), 0.30),
  ];

  // ---- Coop upgrades (33 sprites) -----------------------------------------
  // Grouped by tier so the coop screen shows meaningful progression.
  static const List<CoopItem> coop = [
    CoopItem('coop_0', 'Straw Nest', 0, 0, 1, 2),
    CoopItem('coop_1', 'Comfy Nest', 1, 150, 2, 4),
    CoopItem('coop_2', 'Wide Roost', 2, 260, 3, 6),
    CoopItem('coop_3', 'Green Coop', 3, 420, 4, 9),
    CoopItem('coop_4', 'Shingle Coop', 4, 640, 6, 12),
    CoopItem('coop_5', 'Manor Coop', 5, 980, 8, 16),
    CoopItem('coop_6', 'Royal Coop', 6, 1500, 11, 22),
    CoopItem('coop_7', 'Simple Perch', 7, 120, 2, 3),
    CoopItem('coop_8', 'Twine Perch', 8, 200, 3, 5),
    CoopItem('coop_9', 'Ivy Perch', 9, 320, 4, 7),
    CoopItem('coop_10', 'Party Perch', 10, 460, 5, 9),
    CoopItem('coop_11', 'Carved Perch', 11, 620, 7, 12),
    CoopItem('coop_12', 'Ornate Perch', 12, 900, 9, 16),
    CoopItem('coop_13', 'Feed Trough', 13, 140, 2, 4),
    CoopItem('coop_14', 'Iron Trough', 14, 240, 3, 6),
    CoopItem('coop_15', 'Painted Trough', 15, 360, 4, 8),
    CoopItem('coop_16', 'Grand Trough', 16, 520, 6, 11),
    CoopItem('coop_17', 'Green Feeder', 17, 380, 5, 8),
    CoopItem('coop_18', 'Ruby Feeder', 18, 560, 7, 12),
    CoopItem('coop_19', 'Glass Waterer', 19, 300, 4, 7),
    CoopItem('coop_20', 'Gold Waterer', 20, 700, 8, 14),
    CoopItem('coop_21', 'Hay Pile', 21, 90, 1, 2),
    CoopItem('coop_22', 'Hay Crate', 22, 160, 2, 4),
    CoopItem('coop_23', 'Hay Basket', 23, 240, 3, 6),
    CoopItem('coop_24', 'Wood Fence', 24, 130, 2, 3),
    CoopItem('coop_25', 'Heart Fence', 25, 220, 3, 5),
    CoopItem('coop_26', 'Stone Fence', 26, 340, 4, 7),
    CoopItem('coop_27', 'Ivory Fence', 27, 500, 6, 10),
    CoopItem('coop_28', 'Ribbon Fence', 28, 680, 7, 13),
    CoopItem('coop_29', 'Sign Post', 29, 110, 2, 3),
    CoopItem('coop_30', 'Lantern Post', 30, 260, 4, 6),
    CoopItem('coop_31', 'Nest House', 31, 800, 9, 15),
    CoopItem('coop_32', 'Windmill', 32, 1200, 12, 20),
  ];

  // ---- Decorative plants (32 sprites) -------------------------------------
  static List<CoopItem> get decor => List.generate(32, (i) {
        final price = 80 + i * 45;
        final level = 1 + (i ~/ 4);
        final comfort = 2 + i ~/ 3;
        return CoopItem('decor_$i', _decorNames[i], i, price, level, comfort);
      });

  static const List<String> _decorNames = [
    'Pink Hydrangea', 'Blue Hydrangea', 'Daisy Barrel', 'Lavender Pot',
    'Tulip Vase', 'Pansy Basket', 'Marigold Sack', 'Blossom Barrel',
    'Lily Pot', 'Rose Bush', 'Hydrangea Bush', 'Daisy Bush',
    'Lavender Bush', 'Peony Bush', 'Bluebell Bush', 'Buttercup Bush',
    'Wheat Sheaf', 'Golden Sheaf', 'Lavender Sheaf', 'Sunflower Trio',
    'Sunflower Pair', 'Sunflower Row', 'Tall Grass', 'Reed Grass',
    'Wild Grass', 'Meadow Grass', 'Clover Patch', 'Pink Bloom Bed',
    'Green Bed', 'Daisy Bed', 'Wildflower Bed', 'Meadow Bed',
  ];

  static FoodItem foodById(String id) => foods.firstWhere((f) => f.id == id);
  static CareItem careById(String id) => care.firstWhere((c) => c.id == id);
  static Accessory accById(String id) =>
      accessories.firstWhere((a) => a.id == id);
  static FeatherSkin skinById(String id) => skins.firstWhere((s) => s.id == id);
}
