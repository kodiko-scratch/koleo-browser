/// Navigation controller for managing embedded WebView.
///
/// Provides navigation controls (back, forward, reload) and tracks
/// navigation state including loading progress.
/// Requirements: 1.1-1.5
library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'navigation_controller_interface.dart';

// Conditional imports
import 'navigation_controller_windows.dart' as windows;
import 'navigation_controller_macos.dart' as macos;

export 'navigation_controller_interface.dart';

/// Factory function to create platform-specific navigation controller.
INavigationController createNavigationController({
  void Function(String url)? onUrlChanged,
  void Function(String url)? onLoadStart,
  void Function(String url)? onLoadFinish,
  VoidCallback? onWebViewClosed,
  void Function(String url)? onNewWindowRequested,
}) {
  if (Platform.isWindows) {
    return windows.NavigationControllerImpl(
      onUrlChanged: onUrlChanged,
      onLoadStart: onLoadStart,
      onLoadFinish: onLoadFinish,
      onWebViewClosed: onWebViewClosed,
      onNewWindowRequested: onNewWindowRequested,
    );
  } else if (Platform.isMacOS) {
    return macos.NavigationControllerImpl(
      onUrlChanged: onUrlChanged,
      onLoadStart: onLoadStart,
      onLoadFinish: onLoadFinish,
      onWebViewClosed: onWebViewClosed,
      onNewWindowRequested: onNewWindowRequested,
    );
  } else {
    throw UnsupportedError('Platform not supported');
  }
}

// Keep old class name for backward compatibility
typedef NavigationController = INavigationController;
