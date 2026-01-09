import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_settings.dart';
import 'services/services.dart';
import 'services/vpn_service.dart';
import 'ui/screens/screens.dart';
import 'ui/screens/vpn_screen.dart';
import 'ui/theme/theme.dart';

/// Alias for Flutter's ThemeMode to avoid conflict with AppSettings.ThemeMode
typedef MaterialThemeMode = material.ThemeMode;

void main() async {
  material.WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize SettingsManager
  final settingsManager = await SettingsManager.createWithPrefs(prefs);
  
  material.runApp(KoleoApp(settingsManager: settingsManager));
}

/// Main application widget for Koleo Browser.
///
/// Initializes all services and provides them to the widget tree.
/// Requirements: all
class KoleoApp extends material.StatefulWidget {
  final SettingsManager settingsManager;

  const KoleoApp({
    super.key,
    required this.settingsManager,
  });

  @override
  material.State<KoleoApp> createState() => _KoleoAppState();
}

class _KoleoAppState extends material.State<KoleoApp> {
  late TabManager _tabManager;
  late SearchEngine _searchEngine;
  late SecuritySystem _securitySystem;
  late WallpaperService _wallpaperService;
  late VpnService _vpnService;
  late AppSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _listenToSettingsChanges();
  }

  void _initializeServices() {
    _currentSettings = widget.settingsManager.currentSettings;
    
    // Initialize TabManager and load saved tabs
    _tabManager = TabManager();
    _tabManager.loadSavedTabs();
    
    // Initialize SearchEngine with current settings
    _searchEngine = SearchEngine(engine: _currentSettings.searchEngine);
    
    // Initialize SecuritySystem
    _securitySystem = const SecuritySystem();
    
    // Initialize WallpaperService
    _wallpaperService = WallpaperService();
    
    // Initialize VPN Service
    _vpnService = VpnService();
    _vpnService.init();
  }

  void _listenToSettingsChanges() {
    widget.settingsManager.settingsStream.listen((settings) {
      setState(() {
        _currentSettings = settings;
        // Update search engine when settings change
        _searchEngine.currentEngine = settings.searchEngine;
      });
    });
  }

  @override
  void dispose() {
    _tabManager.dispose();
    _vpnService.dispose();
    widget.settingsManager.dispose();
    super.dispose();
  }

  /// Converts AppSettings ThemeMode to Flutter ThemeMode
  MaterialThemeMode _getFlutterThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return MaterialThemeMode.light;
      case ThemeMode.dark:
        return MaterialThemeMode.dark;
      case ThemeMode.system:
        return MaterialThemeMode.system;
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TabManager>.value(value: _tabManager),
        Provider<SearchEngine>.value(value: _searchEngine),
        Provider<SecuritySystem>.value(value: _securitySystem),
        Provider<WallpaperService>.value(value: _wallpaperService),
        ChangeNotifierProvider<VpnService>.value(value: _vpnService),
        Provider<SettingsManager>.value(value: widget.settingsManager),
      ],
      child: material.MaterialApp(
        title: 'Koleo Browser',
        debugShowCheckedModeBanner: false,
        theme: KoleoTheme.light,
        darkTheme: KoleoTheme.dark,
        themeMode: _getFlutterThemeMode(_currentSettings.themeMode),
        home: KoleoBrowserShell(
          tabManager: _tabManager,
          searchEngine: _searchEngine,
          securitySystem: _securitySystem,
          wallpaperService: _wallpaperService,
          vpnService: _vpnService,
          settingsManager: widget.settingsManager,
        ),
      ),
    );
  }
}

/// Main browser shell that manages navigation between screens.
///
/// Provides the main structure with MainScreen and handles
/// navigation to SettingsScreen.
class KoleoBrowserShell extends material.StatefulWidget {
  final TabManager tabManager;
  final SearchEngine searchEngine;
  final SecuritySystem securitySystem;
  final WallpaperService wallpaperService;
  final VpnService vpnService;
  final SettingsManager settingsManager;

  const KoleoBrowserShell({
    super.key,
    required this.tabManager,
    required this.searchEngine,
    required this.securitySystem,
    required this.wallpaperService,
    required this.vpnService,
    required this.settingsManager,
  });

  @override
  material.State<KoleoBrowserShell> createState() => _KoleoBrowserShellState();
}

class _KoleoBrowserShellState extends material.State<KoleoBrowserShell> {
  bool _showSettings = false;
  bool _showVpn = false;

  void _openSettings() {
    setState(() {
      _showSettings = true;
      _showVpn = false;
    });
  }

  void _closeSettings() {
    setState(() {
      _showSettings = false;
    });
  }

  void _openVpn() {
    setState(() {
      _showVpn = true;
      _showSettings = false;
    });
  }

  void _closeVpn() {
    setState(() {
      _showVpn = false;
    });
  }

  @override
  material.Widget build(material.BuildContext context) {
    if (_showVpn) {
      return VpnScreen(
        vpnService: widget.vpnService,
        onClose: _closeVpn,
      );
    }

    if (_showSettings) {
      return SettingsScreen(
        settingsManager: widget.settingsManager,
        onClose: _closeSettings,
        onOpenVpn: _openVpn,
      );
    }

    return MainScreenWithSettings(
      tabManager: widget.tabManager,
      searchEngine: widget.searchEngine,
      securitySystem: widget.securitySystem,
      vpnService: widget.vpnService,
      onOpenSettings: _openSettings,
      onOpenVpn: _openVpn,
    );
  }
}

/// Extended MainScreen with settings button.
class MainScreenWithSettings extends material.StatelessWidget {
  final TabManager tabManager;
  final SearchEngine searchEngine;
  final SecuritySystem securitySystem;
  final VpnService vpnService;
  final material.VoidCallback onOpenSettings;
  final material.VoidCallback onOpenVpn;

  const MainScreenWithSettings({
    super.key,
    required this.tabManager,
    required this.searchEngine,
    required this.securitySystem,
    required this.vpnService,
    required this.onOpenSettings,
    required this.onOpenVpn,
  });

  @override
  material.Widget build(material.BuildContext context) {
    return MainScreen(
      tabManager: tabManager,
      searchEngine: searchEngine,
      securitySystem: securitySystem,
      onOpenSettings: onOpenSettings,
      onOpenVpn: onOpenVpn,
    );
  }
}
