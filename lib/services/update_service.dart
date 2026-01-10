import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for checking and applying updates
class UpdateService extends ChangeNotifier {
  static const String _currentVersion = '1.0.3';
  static const String _githubRepo = 'kodiko-scratch/koleo-browser';
  static const String _releasesUrl = 'https://api.github.com/repos/$_githubRepo/releases/latest';
  
  String? _latestVersion;
  String? _downloadUrl;
  String? _releaseNotes;
  bool _updateAvailable = false;
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadedFilePath;

  String get currentVersion => _currentVersion;
  String? get latestVersion => _latestVersion;
  String? get releaseNotes => _releaseNotes;
  bool get updateAvailable => _updateAvailable;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  /// Check for updates from GitHub releases
  Future<bool> checkForUpdates() async {
    if (_isChecking) return false;
    
    _isChecking = true;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse(_releasesUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tagName = data['tag_name'] as String? ?? '';
        _latestVersion = tagName.replaceFirst('v', '');
        _releaseNotes = data['body'] as String?;
        
        // Find download URL for current platform
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (Platform.isWindows && name.endsWith('.exe')) {
            _downloadUrl = asset['browser_download_url'] as String?;
            break;
          } else if (Platform.isMacOS && name.endsWith('.dmg')) {
            _downloadUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
        
        _updateAvailable = _isNewerVersion(_latestVersion!, _currentVersion);
        debugPrint('Current: $_currentVersion, Latest: $_latestVersion, Update available: $_updateAvailable');
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
    
    _isChecking = false;
    notifyListeners();
    return _updateAvailable;
  }

  /// Compare version strings (e.g., "1.0.0" vs "1.0.1")
  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    for (int i = 0; i < 3; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  /// Download and install update
  Future<void> downloadAndInstall() async {
    if (_downloadUrl == null || _isDownloading) return;
    
    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();
    
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = Platform.isWindows ? 'KoleoBrowserSetup.exe' : 'KoleoBrowser.dmg';
      final filePath = '${tempDir.path}/$fileName';
      
      // Download with progress
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_downloadUrl!));
      final response = await client.send(request);
      
      final contentLength = response.contentLength ?? 0;
      final file = File(filePath);
      final sink = file.openWrite();
      
      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          _downloadProgress = received / contentLength;
          notifyListeners();
        }
      }
      
      await sink.close();
      client.close();
      
      _downloadedFilePath = filePath;
      _isDownloading = false;
      notifyListeners();
      
      // Install
      await _installUpdate(filePath);
    } catch (e) {
      debugPrint('Error downloading update: $e');
      _isDownloading = false;
      notifyListeners();
    }
  }

  /// Install the downloaded update
  Future<void> _installUpdate(String filePath) async {
    if (Platform.isWindows) {
      // Run installer silently with auto-launch flag and exit app
      await Process.start(filePath, ['/S', '/LAUNCH'], mode: ProcessStartMode.detached);
      exit(0);
    } else if (Platform.isMacOS) {
      // Mount DMG and open it
      await Process.run('hdiutil', ['attach', filePath]);
      // Open Finder to show the mounted volume
      await Process.run('open', ['/Volumes/Koleo Browser']);
    }
  }

  /// Open releases page in browser
  Future<void> openReleasesPage() async {
    final url = Uri.parse('https://github.com/$_githubRepo/releases/latest');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
