import 'package:flutter/material.dart';
import '../../services/vpn_service.dart';
import '../theme/theme.dart';

/// Rounded address bar with modern design
class AddressBar extends StatefulWidget {
  final String currentUrl;
  final bool isLoading;
  final double loadingProgress;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onReload;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onSettings;
  final VpnService? vpnService;
  final VoidCallback? onVpnTap;

  const AddressBar({
    super.key,
    this.currentUrl = '',
    this.isLoading = false,
    this.loadingProgress = 0.0,
    this.canGoBack = false,
    this.canGoForward = false,
    this.onBack,
    this.onForward,
    this.onReload,
    this.onSubmitted,
    this.onSettings,
    this.vpnService,
    this.onVpnTap,
  });

  @override
  State<AddressBar> createState() => _AddressBarState();
}

class _AddressBarState extends State<AddressBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUrl);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AddressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUrl != widget.currentUrl && !_isEditing) {
      _controller.text = widget.currentUrl;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isEditing = _focusNode.hasFocus;
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  void _onSubmitted(String value) {
    _focusNode.unfocus();
    widget.onSubmitted?.call(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2a2a2a) : const Color(0xFFf0f0f0);
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final hintColor = isDark ? Colors.white38 : const Color(0xFF888888);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF555555);
    final disabledColor = isDark ? Colors.white24 : const Color(0xFFaaaaaa);
    final inputBgColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Navigation buttons
          _NavButton(
            icon: Icons.arrow_back_rounded,
            enabled: widget.canGoBack,
            onPressed: widget.onBack,
            tooltip: 'Назад',
            iconColor: iconColor,
            disabledColor: disabledColor,
          ),
          _NavButton(
            icon: Icons.arrow_forward_rounded,
            enabled: widget.canGoForward,
            onPressed: widget.onForward,
            tooltip: 'Вперёд',
            iconColor: iconColor,
            disabledColor: disabledColor,
          ),
          _NavButton(
            icon: widget.isLoading ? Icons.close_rounded : Icons.refresh_rounded,
            enabled: true,
            onPressed: widget.onReload,
            tooltip: widget.isLoading ? 'Остановить' : 'Обновить',
            iconColor: iconColor,
            disabledColor: disabledColor,
          ),
          const SizedBox(width: 8),
          // URL input
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? null : Border.all(color: const Color(0xFFe0e0e0)),
              ),
              child: Stack(
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: KoleoTypography.body.copyWith(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Поиск или введите адрес',
                      hintStyle: KoleoTypography.body.copyWith(color: hintColor, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: _onSubmitted,
                    textInputAction: TextInputAction.go,
                  ),
                  // Loading indicator
                  if (widget.isLoading)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        child: LinearProgressIndicator(
                          value: widget.loadingProgress > 0 ? widget.loadingProgress : null,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? KoleoColors.darkAccent : KoleoColors.lightAccent,
                          ),
                          minHeight: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // VPN indicator
          if (widget.vpnService != null)
            _VpnIndicator(
              vpnService: widget.vpnService!,
              onTap: widget.onVpnTap,
            ),
          // Settings button
          if (widget.onSettings != null)
            _NavButton(
              icon: Icons.settings_rounded,
              enabled: true,
              onPressed: widget.onSettings,
              tooltip: 'Настройки',
              iconColor: iconColor,
              disabledColor: disabledColor,
            ),
        ],
      ),
    );
  }
}

class _VpnIndicator extends StatelessWidget {
  final VpnService vpnService;
  final VoidCallback? onTap;

  const _VpnIndicator({
    required this.vpnService,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vpnService,
      builder: (context, _) {
        final isConnected = vpnService.isConnected;
        final isConnecting = vpnService.isConnecting;
        
        Color bgColor;
        Color iconColor;
        String tooltip;
        
        if (isConnecting) {
          bgColor = Colors.orange.withValues(alpha: 0.2);
          iconColor = Colors.orange;
          tooltip = 'VPN подключается...';
        } else if (isConnected) {
          bgColor = Colors.green.withValues(alpha: 0.2);
          iconColor = Colors.green;
          tooltip = 'VPN: ${vpnService.activeServer?.displayName ?? "Подключено"}';
        } else {
          bgColor = Colors.grey.withValues(alpha: 0.2);
          iconColor = Colors.grey;
          tooltip = 'VPN отключен';
        }
        
        return Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isConnecting
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isConnected ? Icons.vpn_lock : Icons.vpn_lock_outlined,
                        size: 20,
                        color: iconColor,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color iconColor;
  final Color disabledColor;

  const _NavButton({
    required this.icon,
    required this.enabled,
    this.onPressed,
    required this.tooltip,
    required this.iconColor,
    required this.disabledColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? iconColor : disabledColor,
            ),
          ),
        ),
      ),
    );
  }
}
