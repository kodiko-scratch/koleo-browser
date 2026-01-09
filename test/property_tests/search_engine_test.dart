import 'package:glados/glados.dart';
import 'package:koleo_browser/models/app_settings.dart';
import 'package:koleo_browser/services/search_engine.dart';

/// **Feature: koleo-browser, Property 10: Search URL Generation**
///
/// *For any* search query and any SearchEngineType, buildSearchUrl() SHALL
/// return a valid URL containing the encoded query string, and the URL domain
/// SHALL match the selected search engine.
///
/// **Validates: Requirements 7.2**
void main() {
  group('Property 10: Search URL Generation', () {
    // Test that generated URLs contain the encoded query
    Glados(any.lowercaseLetters).test(
      'search URL contains encoded query for all engines',
      (query) {
        if (query.isEmpty) return;

        for (final engine in SearchEngineType.values) {
          final url = SearchEngine.buildSearchUrlWithEngine(query, engine);
          final encodedQuery = Uri.encodeQueryComponent(query);

          expect(
            url.contains(encodedQuery),
            isTrue,
            reason: 'URL for $engine should contain encoded query "$encodedQuery"',
          );
        }
      },
    );

    // Test that URLs start with https://
    Glados(any.lowercaseLetters).test(
      'search URL starts with https:// for all engines',
      (query) {
        if (query.isEmpty) return;

        for (final engine in SearchEngineType.values) {
          final url = SearchEngine.buildSearchUrlWithEngine(query, engine);

          expect(
            url.startsWith('https://'),
            isTrue,
            reason: 'URL for $engine should start with https://',
          );
        }
      },
    );

    // Test that URL domain matches the search engine
    Glados(any.lowercaseLetters).test(
      'search URL domain matches selected engine',
      (query) {
        if (query.isEmpty) return;

        for (final engine in SearchEngineType.values) {
          final url = SearchEngine.buildSearchUrlWithEngine(query, engine);
          final expectedDomain = SearchEngine.getSearchEngineDomain(engine);

          expect(
            url.contains(expectedDomain),
            isTrue,
            reason: 'URL for $engine should contain domain "$expectedDomain"',
          );
        }
      },
    );

    // Test that special characters are properly encoded
    Glados2(any.lowercaseLetters, any.lowercaseLetters).test(
      'search URL properly encodes spaces in queries',
      (word1, word2) {
        if (word1.isEmpty || word2.isEmpty) return;

        final query = '$word1 $word2';
        for (final engine in SearchEngineType.values) {
          final url = SearchEngine.buildSearchUrlWithEngine(query, engine);

          // Space should be encoded as + or %20
          expect(
            !url.contains(' ') || url.contains('+') || url.contains('%20'),
            isTrue,
            reason: 'URL for $engine should encode spaces properly',
          );
        }
      },
    );

    // Test that the generated URL is parseable
    Glados(any.lowercaseLetters).test(
      'search URL is a valid parseable URI',
      (query) {
        if (query.isEmpty) return;

        for (final engine in SearchEngineType.values) {
          final url = SearchEngine.buildSearchUrlWithEngine(query, engine);

          expect(
            () => Uri.parse(url),
            returnsNormally,
            reason: 'URL for $engine should be parseable',
          );

          final uri = Uri.parse(url);
          expect(uri.hasScheme, isTrue);
          expect(uri.scheme, equals('https'));
        }
      },
    );

    // Test instance method consistency with static method
    Glados(any.lowercaseLetters).test(
      'instance buildSearchUrl matches static buildSearchUrlWithEngine',
      (query) {
        if (query.isEmpty) return;

        for (final engine in SearchEngineType.values) {
          final searchEngine = SearchEngine(engine: engine);
          final instanceUrl = searchEngine.buildSearchUrl(query);
          final staticUrl = SearchEngine.buildSearchUrlWithEngine(query, engine);

          expect(
            instanceUrl,
            equals(staticUrl),
            reason: 'Instance and static methods should produce same URL',
          );
        }
      },
    );
  });
}
