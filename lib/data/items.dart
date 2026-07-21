import '../core/app_colors.dart';
import 'package:flutter/material.dart';

/// Which pet stat an action / food influences.
enum Stat { hunger, mood, health, energy, trust }

extension StatMeta on Stat {
  String get label => switch (this) {
        Stat.hunger => 'Fullness',
        Stat.mood => 'Mood',
        Stat.health => 'Health',
        Stat.energy => 'Energy',
        Stat.trust => 'Trust',
      };

  IconData get icon => switch (this) {
        Stat.hunger => Icons.restaurant_rounded,
        Stat.mood => Icons.sentiment_very_satisfied_rounded,
        Stat.health => Icons.favorite_rounded,
        Stat.energy => Icons.bolt_rounded,
        Stat.trust => Icons.volunteer_activism_rounded,
      };

  Color get color => switch (this) {
        Stat.hunger => AppColors.hunger,
        Stat.mood => AppColors.mood,
        Stat.health => AppColors.health,
        Stat.energy => AppColors.energy,
        Stat.trust => AppColors.trust,
      };
}

/// Accessory equip slots.
enum Slot { head, eyes, neck, aura }

extension SlotMeta on Slot {
  String get label => switch (this) {
        Slot.head => 'Head',
        Slot.eyes => 'Eyes',
        Slot.neck => 'Neck',
        Slot.aura => 'Companion',
      };
}

/// A consumable food bowl.
class FoodItem {
  final String id;
  final String name;
  final int sprite;
  final int price;
  final int unlockLevel;
  final Map<Stat, int> effects;
  const FoodItem(this.id, this.name, this.sprite, this.price, this.unlockLevel,
      this.effects);
}

/// A care action item (bath / grooming / rest).
class CareItem {
  final String id;
  final String name;
  final int sprite;
  final int price;
  final int unlockLevel;
  final Map<Stat, int> effects;
  final String verb;
  const CareItem(this.id, this.name, this.sprite, this.price, this.unlockLevel,
      this.effects, this.verb);
}

/// A toy used to raise mood.
class ToyItem {
  final String id;
  final String name;
  final int sprite;
  final int price;
  final int unlockLevel;
  final int moodGain;
  const ToyItem(
      this.id, this.name, this.sprite, this.price, this.unlockLevel, this.moodGain);
}

/// A wearable accessory.
class Accessory {
  final String id;
  final String name;
  final int sprite;
  final int price;
  final int unlockLevel;
  final Slot slot;
  const Accessory(this.id, this.name, this.sprite, this.price, this.unlockLevel,
      this.slot);
}

/// A collectible plumage colour theme ("skin").
class FeatherSkin {
  final String id;
  final String name;
  final int sprite;
  final int price;
  final Color tint;
  final double tintStrength;
  const FeatherSkin(this.id, this.name, this.sprite, this.price, this.tint,
      this.tintStrength);
}

/// A structural coop upgrade or decorative item.
class CoopItem {
  final String id;
  final String name;
  final int sprite;
  final int price;
  final int unlockLevel;
  final int comfort; // adds to coop comfort -> better egg rate & rarity
  const CoopItem(this.id, this.name, this.sprite, this.price, this.unlockLevel,
      this.comfort);
}

/// Egg rarity descriptor.
class EggType {
  final int index; // rarity ladder + sprite index
  final String name;
  final int value; // coins on sale
  final double weight; // base spawn weight
  const EggType(this.index, this.name, this.value, this.weight);
  Color get color => AppColors.rarity[index];
}
