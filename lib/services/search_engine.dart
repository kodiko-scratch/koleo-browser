/// Search engine service for building search URLs.
///
/// Supports multiple search engines: Google, Yandex, DuckDuckGo, and Bing.
library;

import '../models/app_settings.dart';

/// Search engine service that builds search URLs for different providers.
///
/// Handles URL encoding of search queries and generates properly formatted
/// search URLs for the selected search engine.
class SearchEngine {
  SearchEngineType _currentEngine;

  /// Creates a SearchEngine with the specified default engine.
  SearchEngine({SearchEngineType engine = SearchEngineType.koleo})
      : _currentEngine = engine;

  /// Gets the current search engine type.
  SearchEngineType get currentEngine => _currentEngine;

  /// Sets the current search engine type.
  set currentEngine(SearchEngineType engine) {
    _currentEngine = engine;
  }

  /// Builds a search URL for the given query using the current search engine.
  ///
  /// The query is properly URL-encoded to handle special characters.
  /// Returns a valid search URL for the selected search engine.
  String buildSearchUrl(String query) {
    return buildSearchUrlWithEngine(query, _currentEngine);
  }

  /// Builds a search URL for the given query using the specified search engine.
  ///
  /// The query is properly URL-encoded to handle special characters.
  /// Returns a valid search URL for the specified search engine.
  static String buildSearchUrlWithEngine(String query, SearchEngineType engine) {
    final encodedQuery = Uri.encodeQueryComponent(query);
    
    switch (engine) {
      case SearchEngineType.koleo:
        // Google Custom Search Engine for Koleo Browser with nice UI
        return 'https://cse.google.com/cse?cx=21474a14e8b3b49a8&q=$encodedQuery';
      case SearchEngineType.google:
        return 'https://www.google.com/search?q=$encodedQuery';
      case SearchEngineType.yandex:
        return 'https://yandex.ru/search/?text=$encodedQuery';
      case SearchEngineType.duckduckgo:
        return 'https://duckduckgo.com/?q=$encodedQuery';
      case SearchEngineType.bing:
        return 'https://www.bing.com/search?q=$encodedQuery';
    }
  }

  /// Returns the base domain for the specified search engine.
  static String getSearchEngineDomain(SearchEngineType engine) {
    switch (engine) {
      case SearchEngineType.koleo:
        return 'cse.google.com';
      case SearchEngineType.google:
        return 'google.com';
      case SearchEngineType.yandex:
        return 'yandex.ru';
      case SearchEngineType.duckduckgo:
        return 'duckduckgo.com';
      case SearchEngineType.bing:
        return 'bing.com';
    }
  }
}
