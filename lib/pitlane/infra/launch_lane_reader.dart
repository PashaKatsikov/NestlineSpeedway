import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Reads the cold-start push URL written by SceneDelegate.swift. The bridge
/// key must stay in sync with `SceneDelegate.launchLaneKey` (Swift side keeps
/// the `flutter.` prefix so UserDefaults ↔ SharedPreferences map to each other).
class LaunchLaneReader {
  static const String _dartKey = 'nsw_launch_lane';

  static Future<String?> consume() async {
    if (!Platform.isIOS) return null;
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString(_dartKey)?.trim();
      if (value == null || value.isEmpty) return null;
      await preferences.remove(_dartKey);
      return value;
    } catch (_) {
      return null;
    }
  }
}
