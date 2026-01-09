import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:koleo_browser/core/url_validator.dart';

/// **Feature: koleo-browser, Property 2: URL Normalization Round-Trip**
///
/// *For any* valid URL string, normalizing it and then checking validity
/// SHALL always return true, and the normalized URL SHALL always start
/// with "http://" or "https://".
///
/// **Validates: Requirements 1.1**
void main() {
  group('Property 2: URL Normalization Round-Trip', () {
    Glados(any.lowercaseLetters).test(
      'normalized URLs always start with http:// or https://',
      (domain) {
        if (domain.isEmpty) return;

        final url = '$domain.com';
        final normalized = UrlValidator.normalizeUrl(url);

        expect(
          normalized.startsWith('http://') || normalized.startsWith('https://'),
          isTrue,
          reason: 'Normalized URL "$normalized" should start with http:// or https://',
        );
      },
    );

    Glados(any.lowercaseLetters).test(
      'URLs with https:// remain unchanged after normalization',
      (domain) {
        if (domain.isEmpty) return;

        final url = 'https://$domain.com';
        final normalized = UrlValidator.normalizeUrl(url);

        expect(normalized, equals(url),
            reason: 'URL with https:// should remain unchanged');
      },
    );

    Glados(any.lowercaseLetters).test(
      'URLs with http:// remain unchanged after normalization',
      (domain) {
        if (domain.isEmpty) return;

        final url = 'http://$domain.com';
        final normalized = UrlValidator.normalizeUrl(url);

        expect(normalized, equals(url),
            reason: 'URL with http:// should remain unchanged');
      },
    );

    Glados(any.lowercaseLetters).test(
      'normalized valid URLs are still valid',
      (domain) {
        if (domain.isEmpty) return;

        final url = '$domain.com';
        final normalized = UrlValidator.normalizeUrl(url);
        final isValid = UrlValidator.isValidUrl(normalized);

        expect(isValid, isTrue,
            reason: 'Normalized URL "$normalized" should be valid');
      },
    );

    Glados(any.lowercaseLetters).test(
      'normalization is idempotent',
      (domain) {
        if (domain.isEmpty) return;

        final url = '$domain.com';
        final normalized1 = UrlValidator.normalizeUrl(url);
        final normalized2 = UrlValidator.normalizeUrl(normalized1);

        expect(normalized1, equals(normalized2),
            reason: 'Normalizing twice should produce the same result');
      },
    );

    test('empty string normalization returns empty string', () {
      expect(UrlValidator.normalizeUrl(''), equals(''));
    });

    test('whitespace-only string normalization returns trimmed empty', () {
      expect(UrlValidator.normalizeUrl('   '), equals(''));
    });
  });
}
