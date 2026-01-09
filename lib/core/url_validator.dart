/// Utility class for URL validation and normalization.
///
/// Provides methods to check if a string is a valid URL, normalize URLs,
/// and determine if input should be treated as a search query.
class UrlValidator {
  /// Regular expression pattern for validating URLs.
  ///
  /// Matches URLs with optional protocol, domain with TLD, and optional path.
  static final RegExp _urlPattern = RegExp(
    r'^(https?:\/\/)?'
    r'([\da-z\.-]+)\.'
    r'([a-z\.]{2,6})'
    r'([\/\w\.\-\?\=\&\%\#]*)*\/?$',
    caseSensitive: false,
  );

  /// Pattern for localhost URLs.
  static final RegExp _localhostPattern = RegExp(
    r'^(https?:\/\/)?localhost(:\d+)?(\/.*)?$',
    caseSensitive: false,
  );

  /// Pattern for IP address URLs.
  static final RegExp _ipPattern = RegExp(
    r'^(https?:\/\/)?'
    r'(\d{1,3}\.){3}\d{1,3}'
    r'(:\d+)?'
    r'(\/.*)?$',
    caseSensitive: false,
  );

  /// Checks if the given input is a valid URL.
  ///
  /// Returns true if the input matches a URL pattern (with or without protocol),
  /// including localhost and IP addresses.
  static bool isValidUrl(String input) {
    if (input.isEmpty) return false;

    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    // Check for localhost
    if (_localhostPattern.hasMatch(trimmed)) return true;

    // Check for IP address
    if (_ipPattern.hasMatch(trimmed)) return true;

    // Check for standard URL pattern
    return _urlPattern.hasMatch(trimmed);
  }

  /// Normalizes a URL by adding https:// protocol if missing.
  ///
  /// If the URL already has http:// or https://, it is returned unchanged.
  /// Otherwise, https:// is prepended.
  static String normalizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return 'https://$trimmed';
  }

  /// Checks if the given input should be treated as a search query.
  ///
  /// Returns true if the input is not empty and is not a valid URL.
  /// This is mutually exclusive with isValidUrl - a string is either
  /// a valid URL or a search query, never both.
  static bool isSearchQuery(String input) {
    if (input.isEmpty) return false;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    return !isValidUrl(trimmed);
  }
}
