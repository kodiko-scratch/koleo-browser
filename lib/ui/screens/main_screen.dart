import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/tab_manager.dart';
import '../../services/search_engine.dart';
import '../../services/security_system.dart';
import '../../services/navigation_controller.dart';
import '../../services/vpn_service.dart';
import '../../core/url_validator.dart';
import '../widgets/widgets.dart';
import '../theme/theme.dart';
import 'home_screen.dart';

/// Main browser screen with embedded WebView, tab bar, and address bar.
/// Requirements: 1.1-1.5
class MainScreen extends StatefulWidget {
  final TabManager tabManager;
  final SearchEngine searchEngine;
  final SecuritySystem securitySystem;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenVpn;

  const MainScreen({
    super.key,
    required this.tabManager,
    required this.searchEngine,
    required this.securitySystem,
    this.onOpenSettings,
    this.onOpenVpn,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late INavigationController _navigationController;
  String _currentUrl = '';
  bool _webViewReady = false;
  bool _showWebView = false;

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
    _navigationController = createNavigationController(
      onUrlChanged: _onUrlChanged,
      onLoadStart: _onLoadStart,
      onLoadFinish: _onLoadFinish,
      onNewWindowRequested: _onNewWindowRequested,
    );

    _navigationController.stateStream.listen((state) {
      if (mounted) setState(() {});
    });

    final success = await _navigationController.initialize();
    if (mounted) {
      setState(() => _webViewReady = success);
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
    
    if (url.contains('cse.google.com')) {
      _injectKoleoSearchStyles();
    }
  }
  
  void _injectKoleoSearchStyles() {
    final script = '''
      (function() {
        if (document.getElementById('koleo-search-style')) return;
        var style = document.createElement('style');
        style.id = 'koleo-search-style';
        style.textContent = \`
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
        \`;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf5f5f5);
    final contentBgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
    final islandColor = isDark ? const Color(0xFF1a1a1a) : const Color(0xFFe8e8e8);
    final navState = _navigationController.currentState;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Floating Island - combined tab bar and address bar
          Container(
            margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            decoration: BoxDecoration(
              color: islandColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tab bar
                BrowserTabBar(
                  tabs: widget.tabManager.tabs,
                  groups: widget.tabManager.groups,
                  activeTabId: widget.tabManager.activeTabId,
                  onTabSelected: _switchToTab,
                  onTabClosed: _closeTab,
                  onNewTab: _createNewTab,
                  tabManager: widget.tabManager,
                ),
                // Address bar inside island
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
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
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: contentBgColor,
                border: isDark ? null : Border.all(color: const Color(0xFFe0e0e0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_showWebView || _currentUrl.isEmpty) {
      return HomeScreen(onSearch: _onUrlSubmitted);
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
