import 'package:flutter/material.dart';
import '../../models/vpn_server.dart';
import '../../services/vpn_service.dart';
import '../theme/theme.dart';

/// VPN settings screen
class VpnScreen extends StatefulWidget {
  final VpnService vpnService;
  final VoidCallback onClose;

  const VpnScreen({
    super.key,
    required this.vpnService,
    required this.onClose,
  });

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  bool _isPinging = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.vpnService.addListener(_onVpnChanged);
  }

  @override
  void dispose() {
    widget.vpnService.removeListener(_onVpnChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onVpnChanged() => setState(() {});

  Future<void> _pingAll() async {
    setState(() => _isPinging = true);
    await widget.vpnService.pingAllServers();
    widget.vpnService.sortByPing();
    setState(() => _isPinging = false);
  }

  void _showAddSubscriptionDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить подписку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Моя подписка',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL подписки',
                hintText: 'https://...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                widget.vpnService.addSubscription(
                  nameController.text.isEmpty ? 'Подписка' : nameController.text,
                  urlController.text,
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf5f5f5);
    final cardColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
        title: Text('VPN', style: TextStyle(color: textColor)),
        actions: [
          if (_isPinging)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.speed),
              tooltip: 'Проверить пинг',
              onPressed: _pingAll,
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить подписку',
            onPressed: _showAddSubscriptionDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          _buildConnectionStatus(cardColor, textColor),
          // Search bar
          _buildSearchBar(cardColor, textColor),
          const SizedBox(height: 8),
          // Server list
          Expanded(
            child: _buildServerList(cardColor, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color cardColor, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: 'Поиск серверов...',
          hintStyle: TextStyle(color: hintColor),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: hintColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: hintColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildConnectionStatus(Color cardColor, Color textColor) {
    final isConnected = widget.vpnService.isConnected;
    final isConnecting = widget.vpnService.isConnecting;
    final activeServer = widget.vpnService.activeServer;
    final lastError = widget.vpnService.lastError;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? Colors.green : (lastError != null ? Colors.red : Colors.grey.withValues(alpha: 0.3)),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isConnected 
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.vpn_lock : Icons.vpn_lock_outlined,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnecting 
                          ? 'Подключение...'
                          : isConnected 
                              ? 'Подключено'
                              : 'Отключено',
                      style: KoleoTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (activeServer != null)
                      Text(
                        activeServer.displayName,
                        style: KoleoTypography.caption.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              if (isConnected)
                ElevatedButton(
                  onPressed: () => widget.vpnService.disconnect(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Отключить'),
                ),
            ],
          ),
          // Error message
          if (lastError != null && !isConnected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lastError,
                      style: TextStyle(color: Colors.red[300], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServerList(Color cardColor, Color textColor) {
    final subscriptions = widget.vpnService.subscriptions;

    if (subscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Нет подписок',
              style: KoleoTypography.body.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showAddSubscriptionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Добавить подписку'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final sub = subscriptions[index];
        return _buildSubscriptionCard(sub, cardColor, textColor);
      },
    );
  }

  Widget _buildSubscriptionCard(VpnSubscription sub, Color cardColor, Color textColor) {
    // Filter servers by search query
    final filteredServers = _searchQuery.isEmpty
        ? sub.servers
        : sub.servers.where((s) =>
            s.displayName.toLowerCase().contains(_searchQuery) ||
            s.address.toLowerCase().contains(_searchQuery) ||
            s.protocol.toLowerCase().contains(_searchQuery)
          ).toList();
    
    // Don't show subscription if no servers match
    if (_searchQuery.isNotEmpty && filteredServers.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: KoleoTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _searchQuery.isEmpty 
                            ? '${sub.servers.length} серверов'
                            : '${filteredServers.length} из ${sub.servers.length} серверов',
                        style: KoleoTypography.caption.copyWith(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Обновить',
                  onPressed: () => widget.vpnService.updateSubscription(sub.id),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Удалить',
                  onPressed: () => widget.vpnService.removeSubscription(sub.id),
                ),
              ],
            ),
          ),
          // Servers
          ...filteredServers.map((server) => _buildServerTile(server, textColor)),
        ],
      ),
    );
  }

  Widget _buildServerTile(VpnServer server, Color textColor) {
    final isActive = widget.vpnService.activeServer?.id == server.id;
    final isConnected = widget.vpnService.isConnected && isActive;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getProtocolColor(server.protocol).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            server.protocol.toUpperCase().substring(0, 2),
            style: TextStyle(
              color: _getProtocolColor(server.protocol),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
      title: Text(
        server.displayName,
        style: TextStyle(
          color: textColor,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${server.address}:${server.port}',
        style: TextStyle(
          color: textColor.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ping
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPingColor(server.ping).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              server.pingDisplay,
              style: TextStyle(
                color: _getPingColor(server.ping),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Connect button
          if (isConnected)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => widget.vpnService.connect(server),
            ),
        ],
      ),
    );
  }

  Color _getProtocolColor(String protocol) {
    switch (protocol) {
      case 'vless':
        return Colors.blue;
      case 'vmess':
        return Colors.purple;
      case 'trojan':
        return Colors.orange;
      case 'shadowsocks':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPingColor(int? ping) {
    if (ping == null) return Colors.grey;
    if (ping < 0) return Colors.red;
    if (ping < 100) return Colors.green;
    if (ping < 300) return Colors.orange;
    return Colors.red;
  }
}
