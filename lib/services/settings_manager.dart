import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Interface for settings management.
abstract class ISettingsManager {
  /// Loads settings from storage.
  Future<AppSettings> loadSettings();

  /// Saves settings to storage.
  Future<void> saveSettings(AppSettings settings);

  /// Stream of settings changes.
  Stream<AppSettings> get settingsStream;

  /// Current settings value.
  AppSettings get currentSettings;
}

/// Settings manager implementation using shared_preferences.
///
/// Manages user preferences with persistence to local storage.
class SettingsManager implements ISettingsManager {
  static const String _settingsKey = 'koleo_app_settings';

  final SharedPreferences _prefs;
  final StreamController<AppSettings> _settingsController =
      StreamController<AppSettings>.broadcast();

  AppSettings _currentSettings = const AppSettings();

  SettingsManager._(this._prefs);

  /// Creates a SettingsManager instance.
  ///
  /// Must be initialized with [create] factory method.
  static Future<SettingsManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    final manager = SettingsManager._(prefs);
    await manager._initialize();
    return manager;
  }

  /// Creates a SettingsManager with a provided SharedPreferences instance.
  ///
  /// Useful for testing.
  static Future<SettingsManager> createWithPrefs(SharedPreferences prefs) async {
    final manager = SettingsManager._(prefs);
    await manager._initialize();
    return manager;
  }

  Future<void> _initialize() async {
    _currentSettings = await loadSettings();
  }

  @override
  AppSettings get currentSettings => _currentSettings;

  @override
  Stream<AppSettings> get settingsStream => _settingsController.stream;

  @override
  Future<AppSettings> loadSettings() async {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) {
      return const AppSettings();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      // If parsing fails, return default settings
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final jsonString = jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, jsonString);
    _currentSettings = settings;
    _settingsController.add(settings);
  }

  /// Disposes resources used by the manager.
  void dispose() {
    _settingsController.close();
  }
}
