/// Security system for checking URL safety.
///
/// Provides URL security checking against a local database of dangerous patterns.
library;

/// Types of security threats that can be detected.
enum SecurityThreatType {
  /// Malware distribution sites
  malware,
  /// Phishing attempts to steal credentials
  phishing,
  /// Sites distributing unwanted software
  unwantedSoftware,
  /// Social engineering attacks
  socialEngineering,
}

/// Result of a security check on a URL.
class SecurityCheckResult {
  /// Whether the URL is considered safe.
  final bool isSafe;

  /// The type of threat detected, if any.
  final SecurityThreatType? threatType;

  /// A warning message to display to the user.
  final String? warningMessage;

  /// Creates a SecurityCheckResult.
  const SecurityCheckResult({
    required this.isSafe,
    this.threatType,
    this.warningMessage,
  });

  /// Creates a safe result.
  const SecurityCheckResult.safe()
      : isSafe = true,
        threatType = null,
        warningMessage = null;

  /// Creates a dangerous result with the specified threat type.
  factory SecurityCheckResult.dangerous(SecurityThreatType threat) {
    return SecurityCheckResult(
      isSafe: false,
      threatType: threat,
      warningMessage: _getWarningMessage(threat),
    );
  }

  static String _getWarningMessage(SecurityThreatType threat) {
    switch (threat) {
      case SecurityThreatType.malware:
        return 'Этот сайт может содержать вредоносное ПО';
      case SecurityThreatType.phishing:
        return 'Этот сайт может пытаться украсть ваши данные';
      case SecurityThreatType.unwantedSoftware:
        return 'Этот сайт может распространять нежелательное ПО';
      case SecurityThreatType.socialEngineering:
        return 'Этот сайт может использовать методы социальной инженерии';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityCheckResult &&
        other.isSafe == isSafe &&
        other.threatType == threatType &&
        other.warningMessage == warningMessage;
  }

  @override
  int get hashCode => Object.hash(isSafe, threatType, warningMessage);

  @override
  String toString() =>
      'SecurityCheckResult(isSafe: $isSafe, threatType: $threatType, warningMessage: $warningMessage)';
}


/// Security system that checks URLs against a local database of dangerous patterns.
///
/// Provides consistent security classification for URLs based on known
/// malicious patterns, domains, and threat indicators.
class SecuritySystem {
  /// Local database of dangerous URL patterns organized by threat type.
  static const Map<SecurityThreatType, List<String>> _dangerousPatterns = {
    SecurityThreatType.malware: [
      'malware-download.com',
      'virus-free-download.net',
      'free-crack-software.com',
      'download-keygen.net',
      'warez-download.org',
      'trojan-installer.com',
      'ransomware-decrypt.net',
    ],
    SecurityThreatType.phishing: [
      'secure-login-verify.com',
      'account-verify-now.net',
      'paypa1-secure.com',
      'g00gle-login.com',
      'amaz0n-verify.net',
      'bank-secure-login.com',
      'password-reset-verify.net',
      'apple-id-verify.com',
      'microsoft-account-verify.net',
    ],
    SecurityThreatType.unwantedSoftware: [
      'free-toolbar-download.com',
      'browser-extension-free.net',
      'speed-up-pc-free.com',
      'clean-registry-now.net',
      'free-vpn-unlimited.com',
      'adware-bundle.net',
    ],
    SecurityThreatType.socialEngineering: [
      'you-won-prize.com',
      'claim-your-reward.net',
      'urgent-action-required.com',
      'your-computer-infected.net',
      'call-tech-support-now.com',
      'lottery-winner-claim.net',
      'inheritance-claim.com',
    ],
  };

  /// Additional suspicious keywords that indicate potential threats.
  static const Map<SecurityThreatType, List<String>> _suspiciousKeywords = {
    SecurityThreatType.malware: [
      'free-crack',
      'keygen-download',
      'serial-key-free',
      'patch-download',
      'activator-free',
    ],
    SecurityThreatType.phishing: [
      'verify-account',
      'confirm-identity',
      'suspended-account',
      'unusual-activity',
      'security-alert',
    ],
    SecurityThreatType.unwantedSoftware: [
      'free-cleaner',
      'pc-optimizer',
      'driver-update-free',
      'registry-fix',
    ],
    SecurityThreatType.socialEngineering: [
      'congratulations-winner',
      'claim-prize-now',
      'urgent-response',
      'act-now-limited',
    ],
  };

  /// Creates a SecuritySystem instance.
  const SecuritySystem();

  /// Checks if the given URL is safe.
  ///
  /// Returns a [SecurityCheckResult] indicating whether the URL is safe
  /// and, if not, what type of threat was detected.
  ///
  /// The check is deterministic - the same URL will always produce
  /// the same result.
  SecurityCheckResult checkUrl(String url) {
    if (url.isEmpty) {
      return const SecurityCheckResult.safe();
    }

    final normalizedUrl = _normalizeUrl(url);

    // Check against known dangerous domains
    for (final entry in _dangerousPatterns.entries) {
      final threatType = entry.key;
      final patterns = entry.value;

      for (final pattern in patterns) {
        if (_urlMatchesPattern(normalizedUrl, pattern)) {
          return SecurityCheckResult.dangerous(threatType);
        }
      }
    }

    // Check for suspicious keywords in URL
    for (final entry in _suspiciousKeywords.entries) {
      final threatType = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        if (normalizedUrl.contains(keyword)) {
          return SecurityCheckResult.dangerous(threatType);
        }
      }
    }

    return const SecurityCheckResult.safe();
  }

  /// Normalizes a URL for consistent pattern matching.
  String _normalizeUrl(String url) {
    var normalized = url.toLowerCase().trim();

    // Remove protocol
    normalized = normalized.replaceFirst(RegExp(r'^https?://'), '');

    // Remove www prefix
    normalized = normalized.replaceFirst(RegExp(r'^www\.'), '');

    // Remove trailing slash
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// Checks if a normalized URL matches a dangerous pattern.
  bool _urlMatchesPattern(String normalizedUrl, String pattern) {
    // Check if the URL contains the pattern as a domain or subdomain
    if (normalizedUrl.startsWith(pattern) ||
        normalizedUrl.contains('.$pattern') ||
        normalizedUrl == pattern) {
      return true;
    }

    // Check if pattern appears in the path
    if (normalizedUrl.contains('/$pattern')) {
      return true;
    }

    return false;
  }

  /// Reports a dangerous site (for future implementation with external API).
  void reportDangerousSite(String url) {
    // This would send the URL to a security service in a real implementation
    // For now, this is a placeholder for the interface requirement
  }

  /// Gets all known dangerous patterns for testing purposes.
  static Map<SecurityThreatType, List<String>> get dangerousPatterns =>
      Map.unmodifiable(_dangerousPatterns);

  /// Gets all suspicious keywords for testing purposes.
  static Map<SecurityThreatType, List<String>> get suspiciousKeywords =>
      Map.unmodifiable(_suspiciousKeywords);
}
