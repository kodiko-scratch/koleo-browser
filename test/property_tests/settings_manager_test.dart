import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;
import 'package:glados/glados.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koleo_browser/models/app_settings.dart';
import 'package:koleo_browser/services/settings_manager.dart';

/// **Feature: koleo-browser, Property 8: Settings Update Propagation**
///
/// *For any* AppSettings change, saving the settings and then loading them
/// SHALL return the updated values, and the securityLevel field SHALL
/// correctly reflect the user's choice.
///
/// **Validates: Requirements 5.5**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 8: Settings Update Propagation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // Test with all combinations of enum values
    for (final searchEngine in SearchEngineType.values) {
      for (final themeMode in ThemeMode.values) {
        for (final securityLevel in SecurityLevel.values) {
          Glados(any.bool).test(
            'save then load returns same settings: $searchEngine, $themeMode, $securityLevel',
            (showSuggestions) async {
              final prefs = await SharedPreferences.getInstance();
              final manager = await SettingsManager.createWithPrefs(prefs);

              final settings = AppSettings(
                searchEngine: searchEngine,
                themeMode: themeMode,
                securityLevel: securityLevel,
                showSearchSuggestions: showSuggestions,
              );

              await manager.saveSettings(settings);
              final loaded = await manager.loadSettings();

              expect(loaded.searchEngine, equals(settings.searchEngine),
                  reason: 'searchEngine should be preserved after save/load');
              expect(loaded.themeMode, equals(settings.themeMode),
                  reason: 'themeMode should be preserved after save/load');
              expect(loaded.securityLevel, equals(settings.securityLevel),
                  reason: 'securityLevel should correctly reflect user choice');
              expect(loaded.showSearchSuggestions,
                  equals(settings.showSearchSuggestions),
                  reason: 'showSearchSuggestions should be preserved');

              expect(loaded, equals(settings),
                  reason: 'Loaded settings should equal saved settings');

              manager.dispose();
            },
          );
        }
      }
    }

    test('currentSettings reflects saved settings', () async {
      final prefs = await SharedPreferences.getInstance();
      final manager = await SettingsManager.createWithPrefs(prefs);

      final settings = const AppSettings(
        searchEngine: SearchEngineType.duckduckgo,
        themeMode: ThemeMode.dark,
        securityLevel: SecurityLevel.strict,
        showSearchSuggestions: false,
      );

      await manager.saveSettings(settings);

      expect(manager.currentSettings, equals(settings));

      manager.dispose();
    });

    test('settingsStream emits on save', () async {
      final prefs = await SharedPreferences.getInstance();
      final manager = await SettingsManager.createWithPrefs(prefs);

      final settings = const AppSettings(
        searchEngine: SearchEngineType.yandex,
        securityLevel: SecurityLevel.minimal,
      );

      expectLater(
        manager.settingsStream,
        emits(equals(settings)),
      );

      await manager.saveSettings(settings);

      manager.dispose();
    });

    test('new manager loads previously saved settings', () async {
      final prefs = await SharedPreferences.getInstance();
      final manager1 = await SettingsManager.createWithPrefs(prefs);

      final settings = const AppSettings(
        searchEngine: SearchEngineType.bing,
        themeMode: ThemeMode.light,
        securityLevel: SecurityLevel.strict,
      );

      await manager1.saveSettings(settings);
      manager1.dispose();

      // Create new manager with same prefs
      final manager2 = await SettingsManager.createWithPrefs(prefs);
      final loaded = await manager2.loadSettings();

      expect(loaded, equals(settings),
          reason: 'New manager should load previously saved settings');

      manager2.dispose();
    });
  });
}
