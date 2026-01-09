/// Model representing application settings.
///
/// Contains user preferences for search engine, theme, security level,
/// and other configurable options.

/// Available search engine options.
enum SearchEngineType {
  koleo,
  google,
  yandex,
  duckduckgo,
  bing,
}

/// Theme mode options.
enum ThemeMode {
  light,
  dark,
  system,
}

/// Security level options.
enum SecurityLevel {
  minimal,
  standard,
  strict,
}

/// Application settings model.
///
/// Stores user preferences that persist between sessions.
class AppSettings {
  final SearchEngineType searchEngine;
  final ThemeMode themeMode;
  final SecurityLevel securityLevel;
  final bool showSearchSuggestions;

  const AppSettings({
    this.searchEngine = SearchEngineType.koleo,
    this.themeMode = ThemeMode.system,
    this.securityLevel = SecurityLevel.standard,
    this.showSearchSuggestions = true,
  });

  /// Creates a copy of this settings with the given fields replaced.
  AppSettings copyWith({
    SearchEngineType? searchEngine,
    ThemeMode? themeMode,
    SecurityLevel? securityLevel,
    bool? showSearchSuggestions,
  }) {
    return AppSettings(
      searchEngine: searchEngine ?? this.searchEngine,
      themeMode: themeMode ?? this.themeMode,
      securityLevel: securityLevel ?? this.securityLevel,
      showSearchSuggestions: showSearchSuggestions ?? this.showSearchSuggestions,
    );
  }

  /// Serializes this settings to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'searchEngine': searchEngine.name,
      'themeMode': themeMode.name,
      'securityLevel': securityLevel.name,
      'showSearchSuggestions': showSearchSuggestions,
    };
  }

  /// Creates AppSettings from a JSON map.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      searchEngine: SearchEngineType.values.firstWhere(
        (e) => e.name == json['searchEngine'],
        orElse: () => SearchEngineType.koleo,
      ),
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      securityLevel: SecurityLevel.values.firstWhere(
        (e) => e.name == json['securityLevel'],
        orElse: () => SecurityLevel.standard,
      ),
      showSearchSuggestions: json['showSearchSuggestions'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.searchEngine == searchEngine &&
        other.themeMode == themeMode &&
        other.securityLevel == securityLevel &&
        other.showSearchSuggestions == showSearchSuggestions;
  }

  @override
  int get hashCode {
    return Object.hash(searchEngine, themeMode, securityLevel, showSearchSuggestions);
  }

  @override
  String toString() {
    return 'AppSettings(searchEngine: $searchEngine, themeMode: $themeMode, '
        'securityLevel: $securityLevel, showSearchSuggestions: $showSearchSuggestions)';
  }
}
