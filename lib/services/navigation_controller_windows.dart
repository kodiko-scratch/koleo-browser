/// Navigation controller for Windows using webview_windows.
library;

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:webview_windows/webview_windows.dart';
import 'navigation_controller_interface.dart';

/// Navigation controller using webview_windows for embedded WebView.
class NavigationControllerImpl extends ChangeNotifier implements INavigationController {
  final WebviewController _webviewController = WebviewController();
  bool _isInitialized = false;
  
  NavigationState _currentState = const NavigationState();
  final StreamController<NavigationState> _stateController =
      StreamController<NavigationState>.broadcast();

  final void Function(String url)? onUrlChanged;
  final void Function(String url)? onLoadStart;
  final void Function(String url)? onLoadFinish;
  final VoidCallback? onWebViewClosed;
  final void Function(String url)? onNewWindowRequested;
  final void Function(String url, String? suggestedFileName)? onDownloadRequested;

  NavigationControllerImpl({
    this.onUrlChanged,
    this.onLoadStart,
    this.onLoadFinish,
    this.onWebViewClosed,
    this.onNewWindowRequested,
    this.onDownloadRequested,
  });

  /// The WebView controller for embedding in widgets.
  WebviewController get webviewController => _webviewController;

  @override
  bool get isInitialized => _isInitialized;

  @override
  NavigationState get currentState => _currentState;

  @override
  Stream<NavigationState> get stateStream => _stateController.stream;

  @override
  bool get canGoBack => _currentState.canGoBack;

  @override
  bool get canGoForward => _currentState.canGoForward;

  void _updateState(NavigationState newState) {
    _currentState = newState;
    _stateController.add(newState);
    notifyListeners();
  }

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _webviewController.initialize();
      await _webviewController.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      _setupCallbacks();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize WebView: $e');
      return false;
    }
  }

  void _setupCallbacks() {
    _webviewController.url.listen((url) {
      _updateState(_currentState.copyWith(currentUrl: url));
      onUrlChanged?.call(url);
    });

    _webviewController.loadingState.listen((state) {
      final isLoading = state == LoadingState.loading;
      _updateState(_currentState.copyWith(
        isLoading: isLoading,
        progress: isLoading ? 0.5 : 1.0,
      ));
      
      if (isLoading) {
        onLoadStart?.call(_currentState.currentUrl);
      } else {
        onLoadFinish?.call(_currentState.currentUrl);
        _updateHistoryState();
      }
    });

    _webviewController.historyChanged.listen((_) {
      _updateHistoryState();
    });

    _webviewController.webMessage.listen((message) {
      try {
        if (message is String) {
          if (message.contains('openInNewTab')) {
            final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(message);
            if (urlMatch != null) {
              final url = urlMatch.group(1);
              if (url != null && url.isNotEmpty) {
                onNewWindowRequested?.call(url);
              }
            }
          } else if (message.contains('"type":"download"') || message.contains('"type": "download"')) {
            final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(message);
            final fileNameMatch = RegExp(r'"fileName"\s*:\s*"([^"]*)"').firstMatch(message);
            if (urlMatch != null) {
              final url = urlMatch.group(1);
              final fileName = fileNameMatch?.group(1);
              if (url != null && url.isNotEmpty) {
                onDownloadRequested?.call(url, fileName?.isNotEmpty == true ? fileName : null);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing web message: $e');
      }
    });
  }
  
  @override
  Future<void> injectMiddleClickHandler() async {
    const script = '''
      (function() {
        if (window._koleoMiddleClick) return;
        window._koleoMiddleClick = true;
        
        document.addEventListener('pointerdown', function(e) {
          if (e.button !== 1) return;
          
          var el = e.target;
          while (el && el.tagName !== 'A') {
            el = el.parentElement;
          }
          
          if (el && el.href && el.href.indexOf('javascript:') !== 0) {
            e.preventDefault();
            e.stopPropagation();
            window.chrome.webview.postMessage(JSON.stringify({
              type: 'openInNewTab',
              url: el.href
            }));
          }
        }, true);
      })();
    ''';
    try {
      await _webviewController.executeScript(script);
    } catch (e) {
      debugPrint('Failed to inject middle-click handler: $e');
    }
  }

  @override
  Future<void> executeScript(String script) async {
    try {
      await _webviewController.executeScript(script);
    } catch (e) {
      debugPrint('Failed to execute script: $e');
    }
  }

  Future<void> _updateHistoryState() async {
    if (_currentState.currentUrl.isNotEmpty) {
      _updateState(_currentState.copyWith(
        canGoBack: true,
        canGoForward: false,
      ));
    }
  }

  @override
  Future<void> loadUrl(String url) async {
    if (url.isEmpty) return;

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('Cannot load URL: WebView initialization failed');
        return;
      }
    }

    _updateState(_currentState.copyWith(
      isLoading: true,
      progress: 0.0,
    ));

    try {
      await _webviewController.loadUrl(url);
    } catch (e) {
      debugPrint('Failed to load URL: $e');
      _updateState(_currentState.copyWith(isLoading: false));
    }
  }

  @override
  Future<void> goBack() async {
    if (!_isInitialized) return;
    try {
      await _webviewController.goBack();
    } catch (e) {
      debugPrint('Failed to go back: $e');
    }
  }

  @override
  Future<void> goForward() async {
    if (!_isInitialized) return;
    try {
      await _webviewController.goForward();
    } catch (e) {
      debugPrint('Failed to go forward: $e');
    }
  }

  @override
  Future<void> reload() async {
    if (!_isInitialized) return;
    try {
      await _webviewController.reload();
    } catch (e) {
      debugPrint('Failed to reload: $e');
    }
  }

  @override
  Future<void> stopLoading() async {
    if (!_isInitialized) return;
    try {
      await _webviewController.stop();
      _updateState(_currentState.copyWith(isLoading: false));
    } catch (e) {
      debugPrint('Failed to stop loading: $e');
    }
  }

  @override
  void clearHistory() {
    _updateState(const NavigationState());
  }

  @override
  Widget buildWebView() {
    return Webview(_webviewController);
  }

  @override
  void dispose() {
    _webviewController.dispose();
    _stateController.close();
    super.dispose();
  }
}
