import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Download item model
class DownloadItem {
  final String id;
  final String url;
  final String fileName;
  final String savePath;
  final DateTime startTime;
  int totalBytes;
  int downloadedBytes;
  DownloadStatus status;
  String? error;

  DownloadItem({
    required this.id,
    required this.url,
    required this.fileName,
    required this.savePath,
    required this.startTime,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    this.error,
  });

  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0;
  
  String get progressText {
    if (totalBytes == 0) return '${_formatBytes(downloadedBytes)}';
    return '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

enum DownloadStatus { pending, downloading, completed, failed, cancelled }

/// Service for managing file downloads
class DownloadService extends ChangeNotifier {
  final List<DownloadItem> _downloads = [];
  final Map<String, http.Client> _clients = {};
  
  List<DownloadItem> get downloads => List.unmodifiable(_downloads);
  List<DownloadItem> get activeDownloads => _downloads.where((d) => d.status == DownloadStatus.downloading).toList();
  bool get hasActiveDownloads => activeDownloads.isNotEmpty;

  /// Start downloading a file
  Future<void> startDownload(String url, {String? suggestedFileName}) async {
    final fileName = suggestedFileName ?? _extractFileName(url);
    final downloadsDir = await _getDownloadsDirectory();
    final savePath = '${downloadsDir.path}\\$fileName';
    
    final item = DownloadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      fileName: fileName,
      savePath: savePath,
      startTime: DateTime.now(),
    );
    
    _downloads.insert(0, item);
    notifyListeners();
    
    await _downloadFile(item);
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final downloadsDir = Directory('$userProfile\\Downloads');
        if (await downloadsDir.exists()) return downloadsDir;
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        var name = pathSegments.last;
        // Remove query params from filename
        if (name.contains('?')) name = name.split('?').first;
        if (name.isNotEmpty && name.contains('.')) return name;
      }
    } catch (_) {}
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _downloadFile(DownloadItem item) async {
    item.status = DownloadStatus.downloading;
    notifyListeners();

    final client = http.Client();
    _clients[item.id] = client;

    try {
      final request = http.Request('GET', Uri.parse(item.url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      item.totalBytes = response.contentLength ?? 0;
      notifyListeners();

      final file = File(item.savePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        if (item.status == DownloadStatus.cancelled) {
          await sink.close();
          await file.delete();
          return;
        }
        sink.add(chunk);
        item.downloadedBytes += chunk.length;
        notifyListeners();
      }

      await sink.close();
      item.status = DownloadStatus.completed;
      notifyListeners();
    } catch (e) {
      item.status = DownloadStatus.failed;
      item.error = e.toString();
      notifyListeners();
    } finally {
      _clients.remove(item.id);
      client.close();
    }
  }

  /// Cancel a download
  void cancelDownload(String id) {
    final item = _downloads.firstWhere((d) => d.id == id, orElse: () => throw Exception('Not found'));
    if (item.status == DownloadStatus.downloading) {
      item.status = DownloadStatus.cancelled;
      _clients[id]?.close();
      _clients.remove(id);
      notifyListeners();
    }
  }

  /// Remove a download from list
  void removeDownload(String id) {
    _downloads.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  /// Open downloaded file
  Future<void> openFile(DownloadItem item) async {
    if (item.status != DownloadStatus.completed) return;
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [item.savePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [item.savePath]);
      }
    } catch (e) {
      debugPrint('Failed to open file: $e');
    }
  }

  /// Open downloads folder
  Future<void> openDownloadsFolder() async {
    try {
      final dir = await _getDownloadsDirectory();
      if (Platform.isWindows) {
        await Process.run('explorer', [dir.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [dir.path]);
      }
    } catch (e) {
      debugPrint('Failed to open folder: $e');
    }
  }

  /// Clear completed downloads from list
  void clearCompleted() {
    _downloads.removeWhere((d) => d.status == DownloadStatus.completed || d.status == DownloadStatus.failed || d.status == DownloadStatus.cancelled);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final client in _clients.values) {
      client.close();
    }
    super.dispose();
  }
}
