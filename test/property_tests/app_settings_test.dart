import 'package:glados/glados.dart';
import 'package:koleo_browser/models/app_settings.dart';

/// **Feature: koleo-browser, Property 7: Settings Serialization Round-Trip**
///
/// *For any* valid AppSettings object, serializing to JSON and deserializing
/// back SHALL produce an equivalent AppSettings object with all fields preserved.
///
/// **Validates: Requirements 5.2, 5.4**
void main() {
  group('Property 7: Settings Serialization Round-Trip', () {
    // Test with all combinations of enum values
    for (final searchEngine in SearchEngineType.values) {
      for (final themeMode in ThemeMode.values) {
        for (final securityLevel in SecurityLevel.values) {
          Glados(any.bool).test(
            'round-trip preserves settings: $searchEngine, $themeMode, $securityLevel',
            (showSuggestions) {
              final settings = AppSettings(
                searchEngine: searchEngine,
                themeMode: themeMode,
                securityLevel: securityLevel,
                showSearchSuggestions: showSuggestions,
              );

              final json = settings.toJson();
              final restored = AppSettings.fromJson(json);

              expect(restored.searchEngine, equals(settings.searchEngine),
                  reason: 'searchEngine should be preserved');
              expect(restored.themeMode, equals(settings.themeMode),
                  reason: 'themeMode should be preserved');
              expect(restored.securityLevel, equals(settings.securityLevel),
                  reason: 'securityLevel should be preserved');
              expect(restored.showSearchSuggestions,
                  equals(settings.showSearchSuggestions),
                  reason: 'showSearchSuggestions should be preserved');

              // Full equality check
              expect(restored, equals(settings),
                  reason: 'Round-trip should produce equivalent object');
            },
          );
        }
      }
    }

    Glados(any.bool).test(
      'toJson produces valid JSON with all required fields',
      (showSuggestions) {
        final settings = AppSettings(showSearchSuggestions: showSuggestions);
        final json = settings.toJson();

        expect(json.containsKey('searchEngine'), isTrue);
        expect(json.containsKey('themeMode'), isTrue);
        expect(json.containsKey('securityLevel'), isTrue);
        expect(json.containsKey('showSearchSuggestions'), isTrue);

        expect(json['searchEngine'], isA<String>());
        expect(json['themeMode'], isA<String>());
        expect(json['securityLevel'], isA<String>());
        expect(json['showSearchSuggestions'], isA<bool>());
      },
    );

    test('fromJson handles missing fields with defaults', () {
      final settings = AppSettings.fromJson({});

      expect(settings.searchEngine, equals(SearchEngineType.google));
      expect(settings.themeMode, equals(ThemeMode.system));
      expect(settings.securityLevel, equals(SecurityLevel.standard));
      expect(settings.showSearchSuggestions, isTrue);
    });

    test('fromJson handles invalid enum values with defaults', () {
      final settings = AppSettings.fromJson({
        'searchEngine': 'invalid_engine',
        'themeMode': 'invalid_mode',
        'securityLevel': 'invalid_level',
      });

      expect(settings.searchEngine, equals(SearchEngineType.google));
      expect(settings.themeMode, equals(ThemeMode.system));
      expect(settings.securityLevel, equals(SecurityLevel.standard));
    });
  });
}
