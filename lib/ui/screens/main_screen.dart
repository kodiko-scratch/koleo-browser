import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../services/tab_manager.dart';
import '../../services/search_engine.dart';
import '../../services/security_system.dart';
import '../../services/navigation_controller.dart';
import '../../services/vpn_service.dart';
import '../../services/download_service.dart';
import '../../services/settings_manager.dart';
import '../../core/url_validator.dart';
import '../widgets/widgets.dart';
import '../widgets/downloads_panel.dart';
import '../theme/theme.dart';
import 'home_screen.dart';

/// Main browser screen with embedded WebView, tab bar, and address bar.
class MainScreen extends StatefulWidget {
  final TabManager tabManager;
  final SearchEngine searchEngine;
  final SecuritySystem securitySystem;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenVpn;
  final String? initialUrl;

  const MainScreen({
    super.key,
    required this.tabManager,
    required this.searchEngine,
    required this.securitySystem,
    this.onOpenSettings,
    this.onOpenVpn,
    this.initialUrl,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late INavigationController _navigationController;
  String _currentUrl = '';
  bool _webViewReady = false;
  bool _showWebView = false;
  bool _showDownloads = false;
  bool _initialUrlLoaded = false;

  @override
  void initState() {
    super.initState();
    _initNavigationController();
    widget.tabManager.addListener(_onTabManagerChanged);
    
    if (widget.tabManager.tabs.isEmpty) {
      widget.tabManager.createTab();
    }
  }

  Future<void> _initNavigationController() async {
    final downloadService = context.read<DownloadService>();
    
    _navigationController = createNavigationController(
      onUrlChanged: _onUrlChanged,
      onLoadStart: _onLoadStart,
      onLoadFinish: _onLoadFinish,
      onNewWindowRequested: _onNewWindowRequested,
      onDownloadRequested: (url, fileName) {
        downloadService.startDownload(url, suggestedFileName: fileName);
        setState(() => _showDownloads = true);
      },
    );

    _navigationController.stateStream.listen((state) {
      if (mounted) setState(() {});
    });

    final success = await _navigationController.initialize();
    if (mounted) {
      setState(() => _webViewReady = success);
      
      // Load initial URL if provided
      if (success && widget.initialUrl != null && !_initialUrlLoaded) {
        _initialUrlLoaded = true;
        _loadUrl(widget.initialUrl!);
      }
    }
  }

  void _onNewWindowRequested(String url) {
    widget.tabManager.createTab();
    final newTab = widget.tabManager.activeTab;
    if (newTab != null) {
      widget.tabManager.updateTabInfo(newTab.id, url: url);
      setState(() {
        _currentUrl = url;
        _showWebView = true;
      });
      _navigationController.loadUrl(url);
    }
  }

  void _onUrlChanged(String url) {
    setState(() => _currentUrl = url);
    _updateTabUrl(url);
  }

  void _onLoadStart(String url) {
    final activeTab = widget.tabManager.activeTab;
    if (activeTab != null) {
      widget.tabManager.updateTabLoadingState(activeTab.id, isLoading: true, progress: 0.0);
    }
  }

  void _onLoadFinish(String url) {
    final activeTab = widget.tabManager.activeTab;
    if (activeTab != null) {
      widget.tabManager.updateTabLoadingState(activeTab.id, isLoading: false, progress: 1.0);
    }
    _injectScrollScript();
    _navigationController.injectMiddleClickHandler();
    _injectDownloadHandler();
    if (url.contains('cse.google.com')) {
      _injectKoleoSearchStyles();
    }
  }

  void _injectDownloadHandler() {
    const script = '''
      (function() {
        if (window._koleoDownloadHandler) return;
        window._koleoDownloadHandler = true;
        
        // Common download file extensions
        var downloadExts = ['.zip', '.rar', '.7z', '.tar', '.gz', '.exe', '.msi', '.dmg', '.pkg', 
          '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
          '.mp3', '.mp4', '.avi', '.mkv', '.mov', '.wav', '.flac',
          '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp',
          '.apk', '.ipa', '.deb', '.rpm', '.iso', '.img'];
        
        function isDownloadLink(href) {
          if (!href) return false;
          var lowerHref = href.toLowerCase();
          for (var i = 0; i < downloadExts.length; i++) {
            if (lowerHref.includes(downloadExts[i])) return true;
          }
          // Check for download query params
          if (lowerHref.includes('download=') || lowerHref.includes('action=download')) return true;
          return false;
        }
        
        function getFileName(href) {
          try {
            var url = new URL(href);
            var path = url.pathname;
            var parts = path.split('/');
            var name = parts[parts.length - 1];
            if (name && name.includes('.')) return decodeURIComponent(name);
          } catch(e) {}
          return null;
        }
        
        document.addEventListener('click', function(e) {
          var el = e.target;
          while (el && el.tagName !== 'A') {
            el = el.parentElement;
          }
          
          if (el && el.href && isDownloadLink(el.href)) {
            e.preventDefault();
            e.stopPropagation();
            window.chrome.webview.postMessage(JSON.stringify({
              type: 'download',
              url: el.href,
              fileName: getFileName(el.href) || el.download || null
            }));
            return false;
          }
        }, true);
        
        // Also handle download attribute
        document.querySelectorAll('a[download]').forEach(function(a) {
          a.addEventListener('click', function(e) {
            e.preventDefault();
            window.chrome.webview.postMessage(JSON.stringify({
              type: 'download',
              url: a.href,
              fileName: a.download || getFileName(a.href) || null
            }));
          });
        });
      })();
    ''';
    _navigationController.executeScript(script);
  }
  
  void _injectKoleoSearchStyles() {
    final script = '''
      (function() {
        if (document.getElementById('koleo-search-style')) return;
        var style = document.createElement('style');
        style.id = 'koleo-search-style';
        style.textContent = `
          * { box-sizing: border-box; }
          body { background: #1a1a1a !important; min-height: 100vh; }
          .gsc-control-cse { background: transparent !important; border: none !important; padding: 20px 40px !important; max-width: 900px !important; margin: 0 auto !important; }
          .gsc-search-box { background: #2a2a2a !important; border-radius: 30px !important; padding: 8px !important; margin-bottom: 30px !important; border: 2px solid #3a3a3a !important; }
          .gsc-input-box { background: transparent !important; border: none !important; border-radius: 25px !important; padding: 5px 15px !important; }
          input.gsc-input { color: #fff !important; background: transparent !important; font-size: 16px !important; }
          .gsib_a { padding: 0 !important; }
          .gsib_b { display: none !important; }
          .gsc-search-button { background: #4a9eff !important; border: none !important; border-radius: 25px !important; padding: 0 25px !important; height: 45px !important; }
          .gsc-tabsArea, .gsc-above-wrapper-area, .gsc-result-info { display: none !important; }
          .gsc-webResult.gsc-result { background: #f5f5f5 !important; border: none !important; border-radius: 24px !important; padding: 24px 28px !important; margin-bottom: 20px !important; }
          .gs-title, .gs-title * { color: #1a73e8 !important; font-size: 18px !important; font-weight: 600 !important; text-decoration: none !important; }
          .gs-visibleUrl { color: #666 !important; font-size: 14px !important; margin: 6px 0 !important; }
          .gs-snippet { color: #333 !important; font-size: 15px !important; line-height: 1.6 !important; margin-top: 8px !important; }
          .gcsc-find-more-on-google, .gcsc-branding { display: none !important; }
        `;
        document.head.appendChild(style);
      })();
    ''';
    _navigationController.executeScript(script);
  }
  
  void _injectScrollScript() {
    const script = '''
      if (!window._koleoScrollFixed) {
        window._koleoScrollFixed = true;
        document.addEventListener('wheel', function(e) {
          if (e.ctrlKey) return;
          e.preventDefault();
          window.scrollBy({ top: e.deltaY * 0.4, left: e.deltaX * 0.4, behavior: 'auto' });
        }, { passive: false });
      }
    ''';
    _navigationController.executeScript(script);
  }

  @override
  void dispose() {
    widget.tabManager.removeListener(_onTabManagerChanged);
    _navigationController.dispose();
    super.dispose();
  }

  void _onTabManagerChanged() => setState(() {});

  void _updateTabUrl(String url) {
    final activeTab = widget.tabManager.activeTab;
    if (activeTab != null) {
      final uri = Uri.tryParse(url);
      final title = uri?.host ?? url;
      widget.tabManager.updateTabInfo(activeTab.id, title: title, url: url);
    }
  }

  Future<void> _onUrlSubmitted(String input) async {
    if (input.isEmpty) return;
    String url;
    if (UrlValidator.isValidUrl(input)) {
      url = UrlValidator.normalizeUrl(input);
    } else {
      url = widget.searchEngine.buildSearchUrl(input);
    }
    final securityResult = widget.securitySystem.checkUrl(url);
    if (!securityResult.isSafe) {
      final shouldContinue = await SecurityWarningDialog.show(
        context: context,
        url: url,
        result: securityResult,
      );
      if (shouldContinue != true) return;
    }
    await _loadUrl(url);
  }

  Future<void> _loadUrl(String url) async {
    final activeTab = widget.tabManager.activeTab;
    if (activeTab == null) return;
    setState(() {
      _currentUrl = url;
      _showWebView = true;
    });
    widget.tabManager.updateTabInfo(activeTab.id, url: url);
    await _navigationController.loadUrl(url);
  }

  void _goBack() => _navigationController.goBack();
  void _goForward() => _navigationController.goForward();
  
  void _reload() {
    if (_navigationController.currentState.isLoading) {
      _navigationController.stopLoading();
    } else {
      _navigationController.reload();
    }
  }

  void _createNewTab() {
    widget.tabManager.createTab();
    _navigationController.clearHistory();
    setState(() {
      _currentUrl = '';
      _showWebView = false;
    });
  }

  void _switchToTab(String tabId) {
    widget.tabManager.switchToTab(tabId);
    final tab = widget.tabManager.activeTab;
    if (tab != null) {
      setState(() {
        _currentUrl = tab.url;
        _showWebView = tab.url.isNotEmpty;
      });
      if (tab.url.isNotEmpty) {
        _navigationController.loadUrl(tab.url);
      }
    }
  }

  void _closeTab(String tabId) {
    widget.tabManager.closeTab(tabId);
    if (widget.tabManager.tabs.isEmpty) {
      widget.tabManager.createTab();
      setState(() {
        _currentUrl = '';
        _showWebView = false;
      });
    }
  }

  Color _getAccentColor(AccentColor accent) => switch (accent) {
    AccentColor.blue => const Color(0xFF4a9eff),
    AccentColor.purple => const Color(0xFF9c27b0),
    AccentColor.green => const Color(0xFF4caf50),
    AccentColor.orange => const Color(0xFFff9800),
    AccentColor.red => const Color(0xFFf44336),
    AccentColor.pink => const Color(0xFFe91e63),
    AccentColor.teal => const Color(0xFF009688),
  };

  double _getBlurSigma(BackgroundBlur blur) => switch (blur) {
    BackgroundBlur.none => 0.0,
    BackgroundBlur.light => 5.0,
    BackgroundBlur.medium => 10.0,
    BackgroundBlur.heavy => 20.0,
  };

  @override
  Widget build(BuildContext context) {
    final settingsManager = context.watch<SettingsManager>();
    final settings = settingsManager.currentSettings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _getAccentColor(settings.accentColor);
    final cornerRadius = settings.cornerRadius;
    final compactMode = settings.compactMode;
    final blurSigma = _getBlurSigma(settings.backgroundBlur);
    final transparentHeader = settings.transparentHeader;
    
    final backgroundColor = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf0f0f0);
    final contentBgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
    final headerBgColor = transparentHeader 
        ? (isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8))
        : (isDark ? const Color(0xFF151515) : const Color(0xFFfafafa));
    final navState = _navigationController.currentState;
    
    final headerPadding = compactMode ? 4.0 : 6.0;
    final tabHeight = compactMode ? 36.0 : 40.0;
    final addressBarHeight = compactMode ? 40.0 : 44.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // Floating Island Header
              Container(
                margin: EdgeInsets.fromLTRB(8, headerPadding, 8, 0),
                decoration: BoxDecoration(
                  color: blurSigma > 0 ? headerBgColor : headerBgColor,
                  borderRadius: BorderRadius.circular(cornerRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.06) 
                        : Colors.black.withValues(alpha: 0.04),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: blurSigma > 0
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(cornerRadius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                          child: _buildHeaderContent(
                            isDark, accentColor, cornerRadius, compactMode, 
                            tabHeight, addressBarHeight, navState, settings,
                          ),
                        ),
                      )
                    : _buildHeaderContent(
                        isDark, accentColor, cornerRadius, compactMode,
                        tabHeight, addressBarHeight, navState, settings,
                      ),
              ),
              SizedBox(height: compactMode ? 4 : 6),
              // Content
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(8, 0, 8, compactMode ? 4 : 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    color: contentBgColor,
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.06) 
                          : const Color(0xFFe0e0e0),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
          // Downloads panel overlay
          if (_showDownloads)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showDownloads = false),
                child: Container(color: Colors.transparent),
              ),
            ),
          if (_showDownloads)
            Positioned(
              top: 100,
              right: 16,
              child: DownloadsPanel(
                downloadService: context.watch<DownloadService>(),
                onClose: () => setState(() => _showDownloads = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(
    bool isDark, Color accentColor, double cornerRadius, bool compactMode,
    double tabHeight, double addressBarHeight, dynamic navState, AppSettings settings,
  ) {
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab bar row
        BrowserTabBar(
          tabs: widget.tabManager.tabs,
          groups: widget.tabManager.groups,
          activeTabId: widget.tabManager.activeTabId,
          onTabSelected: _switchToTab,
          onTabClosed: _closeTab,
          onNewTab: _createNewTab,
          tabManager: widget.tabManager,
          accentColor: accentColor,
          cornerRadius: cornerRadius,
          compactMode: compactMode,
          tabHeight: tabHeight,
          showTabIcons: settings.showTabIcons,
          tabWidth: settings.tabWidth,
        ),
        // Divider
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: borderColor,
        ),
        // Address bar
        Padding(
          padding: EdgeInsets.all(compactMode ? 6 : 8),
          child: AddressBar(
            currentUrl: _currentUrl,
            isLoading: navState.isLoading,
            loadingProgress: navState.progress,
            canGoBack: _navigationController.canGoBack,
            canGoForward: _navigationController.canGoForward,
            onBack: _navigationController.canGoBack ? _goBack : null,
            onForward: _navigationController.canGoForward ? _goForward : null,
            onReload: _reload,
            onSubmitted: _onUrlSubmitted,
            onSettings: widget.onOpenSettings,
            vpnService: context.watch<VpnService>(),
            onVpnTap: widget.onOpenVpn,
            downloadService: context.watch<DownloadService>(),
            onDownloadsTap: () => setState(() => _showDownloads = !_showDownloads),
            accentColor: accentColor,
            cornerRadius: cornerRadius - 4,
            height: addressBarHeight,
            compactMode: compactMode,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (!_showWebView || _currentUrl.isEmpty) {
      return HomeScreen(
        onSearch: _onUrlSubmitted,
        onQuickLinkTap: _loadUrl,
      );
    }
    if (!_webViewReady) {
      return _buildLoadingWebView();
    }
    return _navigationController.buildWebView();
  }

  Widget _buildLoadingWebView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? KoleoColors.darkText : KoleoColors.lightText;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Загрузка WebView...', style: KoleoTypography.body.copyWith(color: textColor)),
        ],
      ),
    );
  }
}
