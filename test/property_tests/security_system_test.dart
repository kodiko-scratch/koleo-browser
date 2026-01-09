import 'package:glados/glados.dart';
import 'package:koleo_browser/services/security_system.dart';

/// **Feature: koleo-browser, Property 6: Security Check Consistency**
///
/// *For any* URL, the SecuritySystem SHALL return a consistent result
/// (same URL always produces same safety classification), and dangerous
/// URLs SHALL always have isSafe=false with a non-null threatType.
///
/// **Validates: Requirements 3.1, 3.5**
void main() {
  group('Property 6: Security Check Consistency', () {
    final securitySystem = SecuritySystem();

    Glados(any.lowercaseLetters).test(
      'same URL always produces same result (consistency)',
      (domain) {
        if (domain.isEmpty) return;

        final url = 'https://$domain.com/page';

        // Check the same URL multiple times
        final result1 = securitySystem.checkUrl(url);
        final result2 = securitySystem.checkUrl(url);
        final result3 = securitySystem.checkUrl(url);

        // All results should be identical
        expect(result1.isSafe, equals(result2.isSafe));
        expect(result2.isSafe, equals(result3.isSafe));
        expect(result1.threatType, equals(result2.threatType));
        expect(result2.threatType, equals(result3.threatType));
      },
    );

    Glados(any.lowercaseLetters).test(
      'URL variations produce consistent results',
      (domain) {
        if (domain.isEmpty) return;

        final baseUrl = '$domain.com';
        final httpUrl = 'http://$baseUrl';
        final httpsUrl = 'https://$baseUrl';
        final wwwUrl = 'https://www.$baseUrl';

        final baseResult = securitySystem.checkUrl(baseUrl);
        final httpResult = securitySystem.checkUrl(httpUrl);
        final httpsResult = securitySystem.checkUrl(httpsUrl);
        final wwwResult = securitySystem.checkUrl(wwwUrl);

        // All variations of the same domain should have same safety status
        expect(baseResult.isSafe, equals(httpResult.isSafe));
        expect(httpResult.isSafe, equals(httpsResult.isSafe));
        expect(httpsResult.isSafe, equals(wwwResult.isSafe));
      },
    );

    test('known dangerous URLs have isSafe=false and non-null threatType', () {
      // Test all known dangerous patterns
      for (final entry in SecuritySystem.dangerousPatterns.entries) {
        final expectedThreat = entry.key;
        final patterns = entry.value;

        for (final pattern in patterns) {
          final result = securitySystem.checkUrl('https://$pattern');

          expect(
            result.isSafe,
            isFalse,
            reason: 'Pattern "$pattern" should be marked as dangerous',
          );
          expect(
            result.threatType,
            isNotNull,
            reason: 'Dangerous URL "$pattern" must have a threatType',
          );
          expect(
            result.threatType,
            equals(expectedThreat),
            reason: 'Pattern "$pattern" should be classified as $expectedThreat',
          );
          expect(
            result.warningMessage,
            isNotNull,
            reason: 'Dangerous URL "$pattern" must have a warning message',
          );
        }
      }
    });

    test('known suspicious keywords trigger danger classification', () {
      for (final entry in SecuritySystem.suspiciousKeywords.entries) {
        final expectedThreat = entry.key;
        final keywords = entry.value;

        for (final keyword in keywords) {
          final url = 'https://example.com/$keyword/page';
          final result = securitySystem.checkUrl(url);

          expect(
            result.isSafe,
            isFalse,
            reason: 'URL with keyword "$keyword" should be marked as dangerous',
          );
          expect(
            result.threatType,
            isNotNull,
            reason: 'URL with keyword "$keyword" must have a threatType',
          );
          expect(
            result.threatType,
            equals(expectedThreat),
            reason: 'Keyword "$keyword" should be classified as $expectedThreat',
          );
        }
      }
    });

    Glados(any.lowercaseLetters).test(
      'safe URLs have isSafe=true and null threatType',
      (domain) {
        if (domain.isEmpty) return;

        // Generate a safe-looking URL that doesn't match any patterns
        final safeUrl = 'https://$domain-safe-site.org/normal-page';
        final result = securitySystem.checkUrl(safeUrl);

        if (result.isSafe) {
          expect(
            result.threatType,
            isNull,
            reason: 'Safe URLs must have null threatType',
          );
          expect(
            result.warningMessage,
            isNull,
            reason: 'Safe URLs must have null warningMessage',
          );
        } else {
          // If marked dangerous, must have threatType
          expect(
            result.threatType,
            isNotNull,
            reason: 'Dangerous URLs must have non-null threatType',
          );
        }
      },
    );

    test('empty URL is considered safe', () {
      final result = securitySystem.checkUrl('');

      expect(result.isSafe, isTrue);
      expect(result.threatType, isNull);
      expect(result.warningMessage, isNull);
    });

    test('dangerous result invariants hold', () {
      // For each threat type, verify the factory creates valid results
      for (final threatType in SecurityThreatType.values) {
        final result = SecurityCheckResult.dangerous(threatType);

        expect(result.isSafe, isFalse);
        expect(result.threatType, equals(threatType));
        expect(result.warningMessage, isNotNull);
        expect(result.warningMessage!.isNotEmpty, isTrue);
      }
    });
  });
}
