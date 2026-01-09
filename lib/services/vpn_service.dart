import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/vpn_server.dart';

/// VPN service using sing-box
class VpnService extends ChangeNotifier {
  static const String _subsKey = 'vpn_subscriptions';
  static const String _activeServerKey = 'vpn_active_server';
  static const int _proxyPort = 10808;
  
  final List<VpnSubscription> _subscriptions = [];
  VpnServer? _activeServer;
  Process? _singboxProcess;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _singboxPath;
  String? _lastError;
  final _uuid = const Uuid();

  List<VpnSubscription> get subscriptions => List.unmodifiable(_subscriptions);
  List<VpnServer> get allServers => _subscriptions.expand((s) => s.servers).toList();
  VpnServer? get activeServer => _activeServer;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  int get proxyPort => _proxyPort;
  String? get lastError => _lastError;

  /// Initialize service
  Future<void> init() async {
    await _ensureSingbox();
    await _loadSubscriptions();
  }

  /// Ensure sing-box is available
  Future<void> _ensureSingbox() async {
    final appDir = await getApplicationSupportDirectory();
    final singboxDir = Directory('${appDir.path}/singbox');
    if (!await singboxDir.exists()) {
      await singboxDir.create(recursive: true);
    }
    
    _singboxPath = '${singboxDir.path}/sing-box.exe';
    
    if (!await File(_singboxPath!).exists()) {
      // Download sing-box
      debugPrint('Downloading sing-box...');
      try {
        // Use direct download link with redirect following
        final client = http.Client();
        final url = 'https://github.com/SagerNet/sing-box/releases/download/v1.8.0/sing-box-1.8.0-windows-amd64.zip';
        
        final request = http.Request('GET', Uri.parse(url));
        request.followRedirects = true;
        request.maxRedirects = 5;
        
        final streamedResponse = await client.send(request);
        
        if (streamedResponse.statusCode == 200) {
          final zipPath = '${singboxDir.path}/singbox.zip';
          final bytes = await streamedResponse.stream.toBytes();
          await File(zipPath).writeAsBytes(bytes);
          
          debugPrint('Downloaded sing-box, extracting...');
          
          // Extract using PowerShell
          final extractResult = await Process.run('powershell', [
            '-Command',
            'Expand-Archive -Path "$zipPath" -DestinationPath "${singboxDir.path}" -Force'
          ]);
          
          debugPrint('Extract result: ${extractResult.exitCode}');
          if (extractResult.stderr.toString().isNotEmpty) {
            debugPrint('Extract stderr: ${extractResult.stderr}');
          }
          
          // Move exe to correct location
          final extractedExe = File('${singboxDir.path}/sing-box-1.8.0-windows-amd64/sing-box.exe');
          if (await extractedExe.exists()) {
            await extractedExe.copy(_singboxPath!);
            debugPrint('sing-box installed successfully');
          } else {
            debugPrint('sing-box.exe not found after extraction');
            // Try to find it
            final dir = Directory(singboxDir.path);
            await for (final entity in dir.list(recursive: true)) {
              debugPrint('Found: ${entity.path}');
              if (entity.path.endsWith('sing-box.exe')) {
                await File(entity.path).copy(_singboxPath!);
                debugPrint('Found and copied sing-box.exe');
                break;
              }
            }
          }
          
          // Cleanup
          try {
            await File(zipPath).delete();
          } catch (_) {}
        } else {
          debugPrint('Failed to download sing-box: ${streamedResponse.statusCode}');
        }
        
        client.close();
      } catch (e) {
        debugPrint('Failed to download sing-box: $e');
        _lastError = 'Не удалось скачать sing-box: $e';
      }
    }
  }

  /// Load subscriptions from storage
  Future<void> _loadSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_subsKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _subscriptions.clear();
        for (final item in list) {
          _subscriptions.add(VpnSubscription.fromJson(item as Map<String, dynamic>));
        }
      }
      
      final activeId = prefs.getString(_activeServerKey);
      if (activeId != null) {
        _activeServer = allServers.where((s) => s.id == activeId).firstOrNull;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
    }
  }

  /// Save subscriptions to storage
  Future<void> _saveSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_subscriptions.map((s) => s.toJson()).toList());
      await prefs.setString(_subsKey, json);
      
      if (_activeServer != null) {
        await prefs.setString(_activeServerKey, _activeServer!.id);
      } else {
        await prefs.remove(_activeServerKey);
      }
    } catch (e) {
      debugPrint('Error saving subscriptions: $e');
    }
  }

  /// Add subscription
  Future<void> addSubscription(String name, String url) async {
    final sub = VpnSubscription(
      id: _uuid.v4(),
      name: name,
      url: url,
    );
    _subscriptions.add(sub);
    await updateSubscription(sub.id);
    notifyListeners();
  }

  /// Remove subscription
  Future<void> removeSubscription(String id) async {
    _subscriptions.removeWhere((s) => s.id == id);
    await _saveSubscriptions();
    notifyListeners();
  }

  /// Update subscription (fetch servers)
  Future<void> updateSubscription(String id) async {
    final subIndex = _subscriptions.indexWhere((s) => s.id == id);
    if (subIndex == -1) return;
    
    final sub = _subscriptions[subIndex];
    
    try {
      final response = await http.get(Uri.parse(sub.url));
      if (response.statusCode == 200) {
        String content = response.body;
        
        // Try base64 decode
        try {
          content = utf8.decode(base64Decode(content.trim()));
        } catch (_) {}
        
        final servers = _parseServers(content);
        sub.servers = servers;
        sub.lastUpdate = DateTime.now();
        
        await _saveSubscriptions();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating subscription: $e');
    }
  }

  /// Parse servers from subscription content
  List<VpnServer> _parseServers(String content) {
    final servers = <VpnServer>[];
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty);
    
    for (final line in lines) {
      try {
        final server = _parseServerLine(line.trim());
        if (server != null) {
          servers.add(server);
        }
      } catch (e) {
        debugPrint('Error parsing line: $e');
      }
    }
    
    return servers;
  }

  /// Parse single server line
  VpnServer? _parseServerLine(String line) {
    if (line.startsWith('vless://')) {
      return _parseVless(line);
    } else if (line.startsWith('vmess://')) {
      return _parseVmess(line);
    } else if (line.startsWith('trojan://')) {
      return _parseTrojan(line);
    } else if (line.startsWith('ss://')) {
      return _parseShadowsocks(line);
    }
    return null;
  }

  VpnServer? _parseVless(String uri) {
    try {
      final parsed = Uri.parse(uri);
      final uuid = parsed.userInfo;
      final address = parsed.host;
      final port = parsed.port;
      final name = Uri.decodeComponent(parsed.fragment);
      final params = parsed.queryParameters;
      
      return VpnServer(
        id: _uuid.v4(),
        name: name,
        address: address,
        port: port,
        protocol: 'vless',
        rawConfig: uri,
        config: {
          'uuid': uuid,
          'type': params['type'] ?? 'tcp',
          'security': params['security'] ?? 'none',
          'sni': params['sni'] ?? '',
          'fp': params['fp'] ?? '',
          'pbk': params['pbk'] ?? '',
          'sid': params['sid'] ?? '',
          'flow': params['flow'] ?? '',
          'path': params['path'] ?? '',
          'host': params['host'] ?? '',
        },
      );
    } catch (e) {
      return null;
    }
  }

  VpnServer? _parseVmess(String uri) {
    try {
      final base64Part = uri.substring(8);
      final json = jsonDecode(utf8.decode(base64Decode(base64Part)));
      
      return VpnServer(
        id: _uuid.v4(),
        name: json['ps'] ?? '',
        address: json['add'] ?? '',
        port: int.tryParse(json['port'].toString()) ?? 443,
        protocol: 'vmess',
        rawConfig: uri,
        config: {
          'uuid': json['id'] ?? '',
          'alterId': int.tryParse(json['aid'].toString()) ?? 0,
          'security': json['scy'] ?? 'auto',
          'network': json['net'] ?? 'tcp',
          'type': json['type'] ?? '',
          'host': json['host'] ?? '',
          'path': json['path'] ?? '',
          'tls': json['tls'] ?? '',
          'sni': json['sni'] ?? '',
        },
      );
    } catch (e) {
      return null;
    }
  }

  VpnServer? _parseTrojan(String uri) {
    try {
      final parsed = Uri.parse(uri);
      final password = parsed.userInfo;
      final address = parsed.host;
      final port = parsed.port;
      final name = Uri.decodeComponent(parsed.fragment);
      final params = parsed.queryParameters;
      
      return VpnServer(
        id: _uuid.v4(),
        name: name,
        address: address,
        port: port,
        protocol: 'trojan',
        rawConfig: uri,
        config: {
          'password': password,
          'sni': params['sni'] ?? address,
          'type': params['type'] ?? 'tcp',
          'security': params['security'] ?? 'tls',
        },
      );
    } catch (e) {
      return null;
    }
  }

  VpnServer? _parseShadowsocks(String uri) {
    try {
      final parsed = Uri.parse(uri);
      String userInfo = parsed.userInfo;
      
      // Decode base64 if needed
      if (!userInfo.contains(':')) {
        userInfo = utf8.decode(base64Decode(userInfo));
      }
      
      final parts = userInfo.split(':');
      final method = parts[0];
      final password = parts.length > 1 ? parts[1] : '';
      
      return VpnServer(
        id: _uuid.v4(),
        name: Uri.decodeComponent(parsed.fragment),
        address: parsed.host,
        port: parsed.port,
        protocol: 'shadowsocks',
        rawConfig: uri,
        config: {
          'method': method,
          'password': password,
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// Ping server
  Future<int> pingServer(VpnServer server) async {
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(
        server.address,
        server.port,
        timeout: const Duration(seconds: 5),
      );
      stopwatch.stop();
      await socket.close();
      
      server.ping = stopwatch.elapsedMilliseconds;
      notifyListeners();
      return server.ping!;
    } catch (e) {
      server.ping = -1;
      notifyListeners();
      return -1;
    }
  }

  /// Ping all servers (parallel)
  Future<void> pingAllServers() async {
    final futures = <Future>[];
    for (final server in allServers) {
      futures.add(pingServer(server));
    }
    await Future.wait(futures);
    await _saveSubscriptions();
  }

  /// Sort servers by ping
  void sortByPing() {
    for (final sub in _subscriptions) {
      sub.servers.sort((a, b) {
        if (a.ping == null && b.ping == null) return 0;
        if (a.ping == null) return 1;
        if (b.ping == null) return -1;
        if (a.ping! < 0 && b.ping! < 0) return 0;
        if (a.ping! < 0) return 1;
        if (b.ping! < 0) return -1;
        return a.ping!.compareTo(b.ping!);
      });
    }
    notifyListeners();
  }

  /// Generate sing-box config
  String _generateConfig(VpnServer server) {
    final outbound = _generateOutbound(server);
    
    return jsonEncode({
      "log": {"level": "warn"},
      "inbounds": [
        {
          "type": "http",
          "tag": "http-in",
          "listen": "127.0.0.1",
          "listen_port": _proxyPort
        }
      ],
      "outbounds": [
        outbound,
        {"type": "direct", "tag": "direct"}
      ]
    });
  }

  Map<String, dynamic> _generateOutbound(VpnServer server) {
    switch (server.protocol) {
      case 'vless':
        final outbound = <String, dynamic>{
          "type": "vless",
          "tag": "proxy",
          "server": server.address,
          "server_port": server.port,
          "uuid": server.config['uuid'],
        };
        
        final flow = server.config['flow'];
        if (flow != null && flow.toString().isNotEmpty) {
          outbound['flow'] = flow;
        }
        
        final security = server.config['security'];
        if (security == 'tls' || security == 'reality') {
          final tls = <String, dynamic>{
            "enabled": true,
            "server_name": server.config['sni'] ?? server.address,
          };
          
          // uTLS is REQUIRED for reality, optional for tls
          final fp = server.config['fp'];
          if (security == 'reality') {
            // Reality requires utls
            tls['utls'] = {
              "enabled": true,
              "fingerprint": (fp != null && fp.toString().isNotEmpty) ? fp : "chrome"
            };
            tls['reality'] = {
              "enabled": true,
              "public_key": server.config['pbk'] ?? '',
              "short_id": server.config['sid'] ?? '',
            };
          } else if (fp != null && fp.toString().isNotEmpty) {
            tls['utls'] = {"enabled": true, "fingerprint": fp};
          }
          
          outbound['tls'] = tls;
        }
        
        final transportType = server.config['type'];
        if (transportType == 'ws') {
          outbound['transport'] = {
            "type": "ws",
            "path": server.config['path'] ?? '/',
            "headers": {"Host": server.config['host'] ?? server.address}
          };
        } else if (transportType == 'grpc') {
          outbound['transport'] = {
            "type": "grpc",
            "service_name": server.config['path'] ?? ''
          };
        } else if (transportType == 'http') {
          outbound['transport'] = {
            "type": "http",
            "host": [server.config['host'] ?? server.address],
            "path": server.config['path'] ?? '/'
          };
        }
        
        return outbound;
      
      case 'vmess':
        final outbound = <String, dynamic>{
          "type": "vmess",
          "tag": "proxy",
          "server": server.address,
          "server_port": server.port,
          "uuid": server.config['uuid'],
          "alter_id": server.config['alterId'] ?? 0,
          "security": server.config['security'] ?? 'auto',
        };
        
        if (server.config['tls'] == 'tls') {
          outbound['tls'] = {
            "enabled": true,
            "server_name": server.config['sni'] ?? server.address,
          };
        }
        
        if (server.config['network'] == 'ws') {
          outbound['transport'] = {
            "type": "ws",
            "path": server.config['path'] ?? '/',
            "headers": {"Host": server.config['host'] ?? server.address}
          };
        } else if (server.config['network'] == 'grpc') {
          outbound['transport'] = {
            "type": "grpc",
            "service_name": server.config['path'] ?? ''
          };
        }
        
        return outbound;
      
      case 'trojan':
        final outbound = <String, dynamic>{
          "type": "trojan",
          "tag": "proxy",
          "server": server.address,
          "server_port": server.port,
          "password": server.config['password'],
          "tls": {
            "enabled": true,
            "server_name": server.config['sni'] ?? server.address,
          },
        };
        
        final transportType = server.config['type'];
        if (transportType == 'ws') {
          outbound['transport'] = {
            "type": "ws",
            "path": server.config['path'] ?? '/',
          };
        } else if (transportType == 'grpc') {
          outbound['transport'] = {
            "type": "grpc",
            "service_name": server.config['serviceName'] ?? ''
          };
        }
        
        return outbound;
      
      case 'shadowsocks':
        return {
          "type": "shadowsocks",
          "tag": "proxy",
          "server": server.address,
          "server_port": server.port,
          "method": server.config['method'],
          "password": server.config['password'],
        };
      
      default:
        return {"type": "direct", "tag": "proxy"};
    }
  }

  /// Connect to server
  Future<bool> connect(VpnServer server) async {
    if (_isConnecting) return false;
    
    _isConnecting = true;
    _lastError = null;
    notifyListeners();
    
    try {
      // Disconnect if already connected
      await disconnect();
      
      if (_singboxPath == null || !await File(_singboxPath!).exists()) {
        await _ensureSingbox();
      }
      
      if (_singboxPath == null || !await File(_singboxPath!).exists()) {
        _lastError = 'sing-box не найден. Проверьте интернет-соединение.';
        debugPrint('sing-box not found');
        _isConnecting = false;
        notifyListeners();
        return false;
      }
      
      // Write config
      final appDir = await getApplicationSupportDirectory();
      final configPath = '${appDir.path}/singbox/config.json';
      final configContent = _generateConfig(server);
      debugPrint('Config: $configContent');
      await File(configPath).writeAsString(configContent);
      
      // Start sing-box
      debugPrint('Starting sing-box: $_singboxPath');
      _singboxProcess = await Process.start(
        _singboxPath!,
        ['run', '-c', configPath],
      );
      
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();
      
      // Listen to output for debugging
      _singboxProcess!.stdout.transform(utf8.decoder).listen((data) {
        debugPrint('sing-box stdout: $data');
        stdoutBuffer.write(data);
      });
      _singboxProcess!.stderr.transform(utf8.decoder).listen((data) {
        debugPrint('sing-box stderr: $data');
        stderrBuffer.write(data);
      });
      
      // Wait for startup
      await Future.delayed(const Duration(seconds: 3));
      
      // Check if process is still running
      final exitCode = await _singboxProcess?.exitCode.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => -999, // Still running
      );
      
      if (exitCode != null && exitCode != -999) {
        final errorMsg = stderrBuffer.toString();
        _lastError = 'sing-box завершился с кодом $exitCode: $errorMsg';
        debugPrint('sing-box exited with code: $exitCode');
        _isConnecting = false;
        notifyListeners();
        return false;
      }
      
      // Test proxy connection
      final proxyWorks = await _testProxyConnection();
      if (!proxyWorks) {
        _lastError = 'Прокси не отвечает. Сервер может быть недоступен.';
        await disconnect();
        _isConnecting = false;
        notifyListeners();
        return false;
      }
      
      // Set system proxy
      await _setSystemProxy(true);
      
      _activeServer = server;
      _isConnected = true;
      _isConnecting = false;
      
      await _saveSubscriptions();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Ошибка подключения: $e';
      debugPrint('Error connecting: $e');
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Test if proxy is working
  Future<bool> _testProxyConnection() async {
    try {
      final client = HttpClient();
      client.findProxy = (uri) => 'PROXY 127.0.0.1:$_proxyPort';
      
      final request = await client.getUrl(Uri.parse('https://www.google.com/generate_204'))
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      
      client.close();
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Proxy test failed: $e');
      return false;
    }
  }

  /// Set system proxy
  Future<void> _setSystemProxy(bool enable) async {
    if (Platform.isWindows) {
      if (enable) {
        // Enable proxy
        await Process.run('reg', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
          '/v', 'ProxyEnable',
          '/t', 'REG_DWORD',
          '/d', '1',
          '/f'
        ]);
        await Process.run('reg', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
          '/v', 'ProxyServer',
          '/t', 'REG_SZ',
          '/d', '127.0.0.1:$_proxyPort',
          '/f'
        ]);
      } else {
        // Disable proxy
        await Process.run('reg', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
          '/v', 'ProxyEnable',
          '/t', 'REG_DWORD',
          '/d', '0',
          '/f'
        ]);
      }
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    try {
      // Disable system proxy first
      await _setSystemProxy(false);
      
      _singboxProcess?.kill();
      _singboxProcess = null;
      
      // Kill any remaining sing-box processes
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/F', '/IM', 'sing-box.exe']);
      }
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
    
    _activeServer = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
