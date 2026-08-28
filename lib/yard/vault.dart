import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence. One JSON blob under one key, versioned so a future schema change
/// can migrate instead of wiping a player's pedigree.
class Vault {
  Vault._();
  static final Vault instance = Vault._();

  static const String _key = 'circuit_yard_vault';
  static const String _legacyKey = 'nestline_speedway_save';
  static const int schemaVersion = 2;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Drops the cached store.
  ///
  /// This service is a singleton that outlives any one game, so a test that
  /// wants an empty save has to clear the handle as well as the backing store.
  @visibleForTesting
  void forgetStore() => _prefs = null;

  Future<Map<String, dynamic>?> read() async {
    try {
      final store = await _store;
      var raw = store.getString(_key);
      raw ??= store.getString(_legacyKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final version = map['version'] as int? ?? 0;
      if (version > schemaVersion) return null;
      return map;
    } catch (_) {
      // A corrupt save should start a fresh stable rather than crash the app.
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> payload) async {
    try {
      final store = await _store;
      await store.setString(
        _key,
        jsonEncode({'version': schemaVersion, ...payload}),
      );
    } catch (_) {
      // Losing one autosave is survivable; crashing on it is not.
    }
  }

  Future<void> wipe() async {
    try {
      final store = await _store;
      await store.remove(_key);
      await store.remove(_legacyKey);
    } catch (_) {}
  }

  Future<bool> readBool(String key, bool fallback) async {
    try {
      final store = await _store;
      final mapped = switch (key) {
        'cues' => store.getBool('cues') ?? store.getBool('sfx'),
        'score' => store.getBool('score') ?? store.getBool('music'),
        _ => store.getBool(key),
      };
      return mapped ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> writeBool(String key, bool value) async {
    try {
      final store = await _store;
      await store.setBool(key, value);
    } catch (_) {}
  }
}
