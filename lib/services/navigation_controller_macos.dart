/// Navigation controller for macOS using webview_flutter.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'navigation_controller_interface.dart';

/// Navigation controller using webview_flutter for macOS.
class NavigationControllerImpl extends ChangeNotifier implements INavigationController {
  late WebViewController _webviewController;
  bool _isInitialized = false;
  
  NavigationState _currentState = const NavigationState();
  final StreamController<NavigationState> _stateController =
      StreamController<NavigationState>.broadcast();

  final void Function(String url)? onUrlChanged;
  final void Function(String url)? onLoadStart;
  final void Function(String url)? onLoadFinish;
  final VoidCallback? onWebViewClosed;
  final void Function(String url)? onNewWindowRequested;

  NavigationControllerImpl({
    this.onUrlChanged,
    this.onLoadStart,
    this.onLoadFinish,
    this.onWebViewClosed,
    this.onNewWindowRequested,
  });

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
      _webviewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              _updateState(_currentState.copyWith(
                currentUrl: url,
                isLoading: true,
                progress: 0.0,
              ));
              onUrlChanged?.call(url);
              onLoadStart?.call(url);
            },
            onPageFinished: (url) {
              _updateState(_currentState.copyWith(
                currentUrl: url,
                isLoading: false,
                progress: 1.0,
              ));
              onLoadFinish?.call(url);
              _updateHistoryState();
            },
            onProgress: (progress) {
              _updateState(_currentState.copyWith(
                progress: progress / 100.0,
              ));
            },
            onNavigationRequest: (request) {
              return NavigationDecision.navigate;
            },
          ),
        );
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize WebView: $e');
      return false;
    }
  }

  @override
  Future<void> injectMiddleClickHandler() async {
    // Middle-click handling is different on macOS
    // For now, we skip this as Cmd+Click is more common on Mac
  }

  @override
  Future<void> executeScript(String script) async {
    try {
      await _webviewController.runJavaScript(script);
    } catch (e) {
      debugPrint('Failed to execute script: $e');
    }
  }

  Future<void> _updateHistoryState() async {
    final canGoBack = await _webviewController.canGoBack();
    final canGoForward = await _webviewController.canGoForward();
    _updateState(_currentState.copyWith(
      canGoBack: canGoBack,
      canGoForward: canGoForward,
    ));
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
      await _webviewController.loadRequest(Uri.parse(url));
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
    // webview_flutter doesn't have stop() method
    _updateState(_currentState.copyWith(isLoading: false));
  }

  @override
  void clearHistory() {
    _updateState(const NavigationState());
  }

  @override
  Widget buildWebView() {
    return WebViewWidget(controller: _webviewController);
  }

  @override
  void dispose() {
    _stateController.close();
    super.dispose();
  }
}
