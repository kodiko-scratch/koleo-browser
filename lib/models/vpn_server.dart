/// VPN server model
class VpnServer {
  final String id;
  final String name;
  final String address;
  final int port;
  final String protocol; // vless, vmess, trojan, ss
  final String rawConfig;
  final Map<String, dynamic> config;
  int? ping; // ms, null if not tested
  bool isActive;

  VpnServer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.protocol,
    required this.rawConfig,
    required this.config,
    this.ping,
    this.isActive = false,
  });

  String get displayName => name.isNotEmpty ? name : '$address:$port';
  
  String get pingDisplay {
    if (ping == null) return '-';
    if (ping! < 0) return 'Timeout';
    return '${ping}ms';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'port': port,
    'protocol': protocol,
    'rawConfig': rawConfig,
    'config': config,
    'ping': ping,
    'isActive': isActive,
  };

  factory VpnServer.fromJson(Map<String, dynamic> json) => VpnServer(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    address: json['address'] as String,
    port: json['port'] as int,
    protocol: json['protocol'] as String,
    rawConfig: json['rawConfig'] as String,
    config: json['config'] as Map<String, dynamic>? ?? {},
    ping: json['ping'] as int?,
    isActive: json['isActive'] as bool? ?? false,
  );
}

/// VPN subscription model
class VpnSubscription {
  final String id;
  final String name;
  final String url;
  DateTime? lastUpdate;
  List<VpnServer> servers;

  VpnSubscription({
    required this.id,
    required this.name,
    required this.url,
    this.lastUpdate,
    List<VpnServer>? servers,
  }) : servers = servers ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'lastUpdate': lastUpdate?.toIso8601String(),
    'servers': servers.map((s) => s.toJson()).toList(),
  };

  factory VpnSubscription.fromJson(Map<String, dynamic> json) => VpnSubscription(
    id: json['id'] as String,
    name: json['name'] as String,
    url: json['url'] as String,
    lastUpdate: json['lastUpdate'] != null 
        ? DateTime.parse(json['lastUpdate'] as String) 
        : null,
    servers: (json['servers'] as List<dynamic>?)
        ?.map((s) => VpnServer.fromJson(s as Map<String, dynamic>))
        .toList() ?? [],
  );
}
