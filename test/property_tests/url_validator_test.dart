import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:koleo_browser/core/url_validator.dart';

/// **Feature: koleo-browser, Property 1: URL and Query Classification**
///
/// *For any* input string, the UrlValidator SHALL correctly classify it as
/// either a valid URL or a search query, and the classification SHALL be
/// mutually exclusive (never both).
///
/// **Validates: Requirements 1.1, 7.1**
void main() {
  group('Property 1: URL and Query Classification', () {
    // Test with valid URL patterns
    Glados(any.lowercaseLetters).test(
      'domain.com patterns are classified as URLs',
      (domain) {
        if (domain.isEmpty) return;

        final url = '$domain.com';
        final isUrl = UrlValidator.isValidUrl(url);
        final isQuery = UrlValidator.isSearchQuery(url);

        expect(isUrl, isTrue, reason: '"$url" should be a valid URL');
        expect(isQuery, isFalse, reason: '"$url" should not be a search query');
        // Mutual exclusivity
        expect(isUrl != isQuery, isTrue);
      },
    );

    Glados(any.lowercaseLetters).test(
      'https://domain.com patterns are classified as URLs',
      (domain) {
        if (domain.isEmpty) return;

        final url = 'https://$domain.com';
        final isUrl = UrlValidator.isValidUrl(url);
        final isQuery = UrlValidator.isSearchQuery(url);

        expect(isUrl, isTrue, reason: '"$url" should be a valid URL');
        expect(isQuery, isFalse, reason: '"$url" should not be a search query');
        // Mutual exclusivity
        expect(isUrl != isQuery, isTrue);
      },
    );

    Glados(any.lowercaseLetters).test(
      'strings without TLD are classified as search queries',
      (input) {
        if (input.isEmpty) return;

        // A simple word without dots should be a search query
        final isUrl = UrlValidator.isValidUrl(input);
        final isQuery = UrlValidator.isSearchQuery(input);

        expect(isUrl, isFalse, reason: '"$input" should not be a valid URL');
        expect(isQuery, isTrue, reason: '"$input" should be a search query');
        // Mutual exclusivity
        expect(isUrl != isQuery, isTrue);
      },
    );

    Glados(any.lowercaseLetters).test(
      'search phrases are classified as search queries',
      (word) {
        if (word.isEmpty) return;

        final query = 'how to $word';
        final isUrl = UrlValidator.isValidUrl(query);
        final isQuery = UrlValidator.isSearchQuery(query);

        expect(isUrl, isFalse, reason: '"$query" should not be a valid URL');
        expect(isQuery, isTrue, reason: '"$query" should be a search query');
        // Mutual exclusivity
        expect(isUrl != isQuery, isTrue);
      },
    );

    test('empty string is neither URL nor search query', () {
      expect(UrlValidator.isValidUrl(''), isFalse);
      expect(UrlValidator.isSearchQuery(''), isFalse);
    });

    test('whitespace-only string is neither URL nor search query', () {
      expect(UrlValidator.isValidUrl('   '), isFalse);
      expect(UrlValidator.isSearchQuery('   '), isFalse);
    });
  });
}
