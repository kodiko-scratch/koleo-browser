import 'package:flutter/material.dart';
import '../theme/koleo_typography.dart';

/// Beautiful Koleo Search page HTML generator
class KoleoSearchPage {
  static const String cseId = '21474a14e8b3b49a8';
  
  /// Generates HTML for Koleo Search page with custom styling
  static String generateSearchPageHtml(String query) {
    final encodedQuery = Uri.encodeComponent(query);
    
    return '''
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Koleo Search - $query</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
      background: linear-gradient(135deg, #0a1628 0%, #1a3a5c 50%, #2d5a87 100%);
      min-height: 100vh;
      color: #fff;
    }
    
    .header {
      padding: 24px 40px;
      display: flex;
      align-items: center;
      gap: 20px;
      background: rgba(0,0,0,0.2);
      backdrop-filter: blur(10px);
    }
    
    .logo {
      font-size: 28px;
      font-weight: 700;
      background: linear-gradient(135deg, #64b5f6, #42a5f5);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      letter-spacing: 2px;
    }
    
    .search-box {
      flex: 1;
      max-width: 700px;
    }
    
    .search-input {
      width: 100%;
      padding: 14px 24px;
      font-size: 16px;
      border: none;
      border-radius: 28px;
      background: rgba(255,255,255,0.1);
      color: #fff;
      outline: none;
      transition: all 0.3s ease;
    }
    
    .search-input:focus {
      background: rgba(255,255,255,0.15);
      box-shadow: 0 0 0 2px rgba(100,181,246,0.5);
    }
    
    .search-input::placeholder {
      color: rgba(255,255,255,0.5);
    }
    
    .results-container {
      max-width: 900px;
      margin: 0 auto;
      padding: 30px 40px;
    }
    
    .query-info {
      margin-bottom: 24px;
      padding-bottom: 16px;
      border-bottom: 1px solid rgba(255,255,255,0.1);
    }
    
    .query-info h1 {
      font-size: 24px;
      font-weight: 400;
      color: rgba(255,255,255,0.9);
    }
    
    .query-info span {
      color: #64b5f6;
      font-weight: 600;
    }
    
    /* Google CSE Styling Override */
    .gsc-control-cse {
      background: transparent !important;
      border: none !important;
      padding: 0 !important;
    }
    
    .gsc-results-wrapper-overlay {
      background: transparent !important;
    }
    
    .gsc-webResult.gsc-result {
      background: rgba(255,255,255,0.05) !important;
      border: 1px solid rgba(255,255,255,0.1) !important;
      border-radius: 16px !important;
      padding: 20px !important;
      margin-bottom: 16px !important;
      transition: all 0.3s ease !important;
    }
    
    .gsc-webResult.gsc-result:hover {
      background: rgba(255,255,255,0.1) !important;
      transform: translateY(-2px) !important;
    }
    
    .gs-title, .gs-title * {
      color: #64b5f6 !important;
      font-size: 18px !important;
      text-decoration: none !important;
    }
    
    .gs-title:hover, .gs-title *:hover {
      color: #90caf9 !important;
    }
    
    .gs-snippet {
      color: rgba(255,255,255,0.8) !important;
      font-size: 14px !important;
      line-height: 1.6 !important;
    }
    
    .gs-visibleUrl, .gs-visibleUrl-short {
      color: rgba(100,181,246,0.7) !important;
      font-size: 13px !important;
    }
    
    .gsc-cursor-page {
      background: rgba(255,255,255,0.1) !important;
      color: #fff !important;
      border-radius: 8px !important;
      padding: 8px 14px !important;
      margin: 4px !important;
    }
    
    .gsc-cursor-current-page {
      background: #64b5f6 !important;
      color: #0a1628 !important;
    }
    
    .gsc-above-wrapper-area {
      border: none !important;
      padding: 0 !important;
    }
    
    .gsc-result-info {
      color: rgba(255,255,255,0.6) !important;
      padding: 0 0 16px 0 !important;
    }
    
    .gsc-orderby-container {
      display: none !important;
    }
    
    .gcsc-find-more-on-google {
      display: none !important;
    }
    
    .gsc-table-result {
      background: transparent !important;
    }
    
    td.gsc-table-cell-snippet-close {
      padding: 0 !important;
    }
    
    .gs-image-box {
      display: none !important;
    }
    
    .gsc-input-box {
      display: none !important;
    }
    
    .gsc-search-box {
      display: none !important;
    }
    
    .gsc-above-wrapper-area-container {
      margin: 0 !important;
    }
    
    .gsc-wrapper {
      margin: 0 !important;
    }
    
    .loading {
      text-align: center;
      padding: 60px;
      color: rgba(255,255,255,0.6);
    }
    
    .loading-spinner {
      width: 40px;
      height: 40px;
      border: 3px solid rgba(255,255,255,0.1);
      border-top-color: #64b5f6;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin: 0 auto 20px;
    }
    
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo">KOLEO</div>
    <div class="search-box">
      <input type="text" class="search-input" value="$query" placeholder="Поиск в интернете..." id="searchInput">
    </div>
  </div>
  
  <div class="results-container">
    <div class="query-info">
      <h1>Результаты поиска: <span>$query</span></h1>
    </div>
    
    <div class="loading" id="loading">
      <div class="loading-spinner"></div>
      <p>Загрузка результатов...</p>
    </div>
    
    <div class="gcse-searchresults-only" data-queryParameterName="q"></div>
  </div>
  
  <script async src="https://cse.google.com/cse.js?cx=$cseId"></script>
  <script>
    // Handle search input
    document.getElementById('searchInput').addEventListener('keypress', function(e) {
      if (e.key === 'Enter') {
        var query = this.value.trim();
        if (query) {
          window.location.href = 'koleo-search://' + encodeURIComponent(query);
        }
      }
    });
    
    // Hide loading when results appear
    var checkResults = setInterval(function() {
      var results = document.querySelector('.gsc-results');
      if (results) {
        document.getElementById('loading').style.display = 'none';
        clearInterval(checkResults);
      }
    }, 100);
    
    // Timeout for loading
    setTimeout(function() {
      document.getElementById('loading').style.display = 'none';
    }, 5000);
  </script>
</body>
</html>
''';
  }
  
  /// Returns the URL for Koleo Search
  static String getSearchUrl(String query) {
    final encodedQuery = Uri.encodeQueryComponent(query);
    return 'https://cse.google.com/cse?cx=$cseId&q=$encodedQuery';
  }
}
