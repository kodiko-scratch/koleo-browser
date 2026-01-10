/// Model representing application settings.
///
/// Contains user preferences for search engine, theme, security level,
/// and other configurable options.
library;

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

/// Accent color options.
enum AccentColor {
  blue,
  purple,
  green,
  orange,
  red,
  pink,
  teal,
}

/// Tab bar style options.
enum TabBarStyle {
  standard,
  compact,
  floating,
}

/// Background blur options.
enum BackgroundBlur {
  none,
  light,
  medium,
  heavy,
}

/// Home background type options.
enum HomeBackgroundType {
  animatedGradient,
  staticGradient,
  image,
}

/// Application settings model.
///
/// Stores user preferences that persist between sessions.
class AppSettings {
  final SearchEngineType searchEngine;
  final ThemeMode themeMode;
  final SecurityLevel securityLevel;
  final bool showSearchSuggestions;
  final AccentColor accentColor;
  final TabBarStyle tabBarStyle;
  final double cornerRadius;
  final bool compactMode;
  final bool showTabIcons;
  final double tabWidth;
  final BackgroundBlur backgroundBlur;
  final bool transparentHeader;
  final HomeBackgroundType homeBackground;
  final int gradientThemeIndex;
  final int backgroundImageIndex;

  const AppSettings({
    this.searchEngine = SearchEngineType.koleo,
    this.themeMode = ThemeMode.system,
    this.securityLevel = SecurityLevel.standard,
    this.showSearchSuggestions = true,
    this.accentColor = AccentColor.blue,
    this.tabBarStyle = TabBarStyle.floating,
    this.cornerRadius = 16.0,
    this.compactMode = false,
    this.showTabIcons = true,
    this.tabWidth = 180.0,
    this.backgroundBlur = BackgroundBlur.none,
    this.transparentHeader = false,
    this.homeBackground = HomeBackgroundType.animatedGradient,
    this.gradientThemeIndex = 0,
    this.backgroundImageIndex = 0,
  });

  /// Creates a copy of this settings with the given fields replaced.
  AppSettings copyWith({
    SearchEngineType? searchEngine,
    ThemeMode? themeMode,
    SecurityLevel? securityLevel,
    bool? showSearchSuggestions,
    AccentColor? accentColor,
    TabBarStyle? tabBarStyle,
    double? cornerRadius,
    bool? compactMode,
    bool? showTabIcons,
    double? tabWidth,
    BackgroundBlur? backgroundBlur,
    bool? transparentHeader,
    HomeBackgroundType? homeBackground,
    int? gradientThemeIndex,
    int? backgroundImageIndex,
  }) {
    return AppSettings(
      searchEngine: searchEngine ?? this.searchEngine,
      themeMode: themeMode ?? this.themeMode,
      securityLevel: securityLevel ?? this.securityLevel,
      showSearchSuggestions: showSearchSuggestions ?? this.showSearchSuggestions,
      accentColor: accentColor ?? this.accentColor,
      tabBarStyle: tabBarStyle ?? this.tabBarStyle,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      compactMode: compactMode ?? this.compactMode,
      showTabIcons: showTabIcons ?? this.showTabIcons,
      tabWidth: tabWidth ?? this.tabWidth,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
      transparentHeader: transparentHeader ?? this.transparentHeader,
      homeBackground: homeBackground ?? this.homeBackground,
      gradientThemeIndex: gradientThemeIndex ?? this.gradientThemeIndex,
      backgroundImageIndex: backgroundImageIndex ?? this.backgroundImageIndex,
    );
  }

  /// Serializes this settings to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'searchEngine': searchEngine.name,
      'themeMode': themeMode.name,
      'securityLevel': securityLevel.name,
      'showSearchSuggestions': showSearchSuggestions,
      'accentColor': accentColor.name,
      'tabBarStyle': tabBarStyle.name,
      'cornerRadius': cornerRadius,
      'compactMode': compactMode,
      'showTabIcons': showTabIcons,
      'tabWidth': tabWidth,
      'backgroundBlur': backgroundBlur.name,
      'transparentHeader': transparentHeader,
      'homeBackground': homeBackground.name,
      'gradientThemeIndex': gradientThemeIndex,
      'backgroundImageIndex': backgroundImageIndex,
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
      accentColor: AccentColor.values.firstWhere(
        (e) => e.name == json['accentColor'],
        orElse: () => AccentColor.blue,
      ),
      tabBarStyle: TabBarStyle.values.firstWhere(
        (e) => e.name == json['tabBarStyle'],
        orElse: () => TabBarStyle.floating,
      ),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 16.0,
      compactMode: json['compactMode'] as bool? ?? false,
      showTabIcons: json['showTabIcons'] as bool? ?? true,
      tabWidth: (json['tabWidth'] as num?)?.toDouble() ?? 180.0,
      backgroundBlur: BackgroundBlur.values.firstWhere(
        (e) => e.name == json['backgroundBlur'],
        orElse: () => BackgroundBlur.none,
      ),
      transparentHeader: json['transparentHeader'] as bool? ?? false,
      homeBackground: HomeBackgroundType.values.firstWhere(
        (e) => e.name == json['homeBackground'],
        orElse: () => HomeBackgroundType.animatedGradient,
      ),
      gradientThemeIndex: json['gradientThemeIndex'] as int? ?? 0,
      backgroundImageIndex: json['backgroundImageIndex'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.searchEngine == searchEngine &&
        other.themeMode == themeMode &&
        other.securityLevel == securityLevel &&
        other.showSearchSuggestions == showSearchSuggestions &&
        other.accentColor == accentColor &&
        other.tabBarStyle == tabBarStyle &&
        other.cornerRadius == cornerRadius &&
        other.compactMode == compactMode &&
        other.showTabIcons == showTabIcons &&
        other.tabWidth == tabWidth &&
        other.backgroundBlur == backgroundBlur &&
        other.transparentHeader == transparentHeader &&
        other.homeBackground == homeBackground &&
        other.gradientThemeIndex == gradientThemeIndex &&
        other.backgroundImageIndex == backgroundImageIndex;
  }

  @override
  int get hashCode {
    return Object.hash(searchEngine, themeMode, securityLevel, showSearchSuggestions,
        accentColor, tabBarStyle, cornerRadius, compactMode, showTabIcons, tabWidth,
        backgroundBlur, transparentHeader, homeBackground, gradientThemeIndex, backgroundImageIndex);
  }

  @override
  String toString() {
    return 'AppSettings(searchEngine: $searchEngine, themeMode: $themeMode, '
        'securityLevel: $securityLevel, showSearchSuggestions: $showSearchSuggestions, '
        'accentColor: $accentColor, tabBarStyle: $tabBarStyle, cornerRadius: $cornerRadius, '
        'compactMode: $compactMode, showTabIcons: $showTabIcons, tabWidth: $tabWidth, '
        'backgroundBlur: $backgroundBlur, transparentHeader: $transparentHeader, '
        'homeBackground: $homeBackground, gradientThemeIndex: $gradientThemeIndex, '
        'backgroundImageIndex: $backgroundImageIndex)';
  }
}
