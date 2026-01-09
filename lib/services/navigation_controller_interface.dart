/// Navigation controller interface for cross-platform WebView support.
library;

import 'dart:async';
import 'package:flutter/widgets.dart';

/// Navigation state representing the current state of the WebView.
class NavigationState {
  final String currentUrl;
  final bool isLoading;
  final double progress;
  final bool canGoBack;
  final bool canGoForward;

  const NavigationState({
    this.currentUrl = '',
    this.isLoading = false,
    this.progress = 0.0,
    this.canGoBack = false,
    this.canGoForward = false,
  });

  NavigationState copyWith({
    String? currentUrl,
    bool? isLoading,
    double? progress,
    bool? canGoBack,
    bool? canGoForward,
  }) {
    return NavigationState(
      currentUrl: currentUrl ?? this.currentUrl,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationState &&
        other.currentUrl == currentUrl &&
        other.isLoading == isLoading &&
        other.progress == progress &&
        other.canGoBack == canGoBack &&
        other.canGoForward == canGoForward;
  }

  @override
  int get hashCode {
    return Object.hash(currentUrl, isLoading, progress, canGoBack, canGoForward);
  }
}

/// Abstract interface for navigation control.
abstract class INavigationController extends ChangeNotifier {
  Future<bool> initialize();
  Future<void> loadUrl(String url);
  Future<void> goBack();
  Future<void> goForward();
  Future<void> reload();
  Future<void> stopLoading();
  void clearHistory();
  bool get canGoBack;
  bool get canGoForward;
  bool get isInitialized;
  Stream<NavigationState> get stateStream;
  NavigationState get currentState;
  Widget buildWebView();
  Future<void> injectMiddleClickHandler();
  Future<void> executeScript(String script);
}
