import 'package:flutter/material.dart';
import '../../services/vpn_service.dart';
import '../../services/download_service.dart';
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
  final DownloadService? downloadService;
  final VoidCallback? onDownloadsTap;
  final Color accentColor;
  final double cornerRadius;
  final double height;
  final bool compactMode;

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
    this.downloadService,
    this.onDownloadsTap,
    this.accentColor = const Color(0xFF4a9eff),
    this.cornerRadius = 12.0,
    this.height = 44.0,
    this.compactMode = false,
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
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
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
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final hintColor = isDark ? Colors.white38 : const Color(0xFF888888);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF555555);
    final disabledColor = isDark ? Colors.white24 : const Color(0xFFaaaaaa);
    final inputBgColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;
    final buttonSize = widget.compactMode ? 32.0 : 36.0;
    final iconSize = widget.compactMode ? 18.0 : 20.0;

    return Container(
      height: widget.height,
      padding: EdgeInsets.symmetric(horizontal: widget.compactMode ? 4 : 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.cornerRadius),
      ),
      child: Row(
        children: [
          _NavButton(
            icon: Icons.arrow_back_rounded,
            enabled: widget.canGoBack,
            onPressed: widget.onBack,
            tooltip: 'Назад',
            iconColor: iconColor,
            disabledColor: disabledColor,
            size: buttonSize,
            iconSize: iconSize,
            cornerRadius: widget.cornerRadius - 4,
          ),
          _NavButton(
            icon: Icons.arrow_forward_rounded,
            enabled: widget.canGoForward,
            onPressed: widget.onForward,
            tooltip: 'Вперёд',
            iconColor: iconColor,
            disabledColor: disabledColor,
            size: buttonSize,
            iconSize: iconSize,
            cornerRadius: widget.cornerRadius - 4,
          ),
          _NavButton(
            icon: widget.isLoading ? Icons.close_rounded : Icons.refresh_rounded,
            enabled: true,
            onPressed: widget.onReload,
            tooltip: widget.isLoading ? 'Остановить' : 'Обновить',
            iconColor: iconColor,
            disabledColor: disabledColor,
            size: buttonSize,
            iconSize: iconSize,
            cornerRadius: widget.cornerRadius - 4,
          ),
          SizedBox(width: widget.compactMode ? 6 : 8),
          Expanded(
            child: Container(
              height: widget.height - 8,
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(widget.cornerRadius - 2),
                border: _isEditing 
                    ? Border.all(color: widget.accentColor.withValues(alpha: 0.5), width: 1.5)
                    : (isDark ? null : Border.all(color: Colors.black.withValues(alpha: 0.06))),
              ),
              child: Stack(
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: KoleoTypography.body.copyWith(
                      color: textColor, 
                      fontSize: widget.compactMode ? 13 : 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Поиск или введите адрес',
                      hintStyle: KoleoTypography.body.copyWith(
                        color: hintColor, 
                        fontSize: widget.compactMode ? 13 : 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: widget.compactMode ? 12 : 14, 
                        vertical: widget.compactMode ? 8 : 10,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: _onSubmitted,
                    textInputAction: TextInputAction.go,
                  ),
                  if (widget.isLoading)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(widget.cornerRadius - 2)),
                        child: LinearProgressIndicator(
                          value: widget.loadingProgress > 0 ? widget.loadingProgress : null,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                          minHeight: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: widget.compactMode ? 6 : 8),
          if (widget.downloadService != null)
            _DownloadsIndicator(
              downloadService: widget.downloadService!,
              onTap: widget.onDownloadsTap,
              size: buttonSize,
              cornerRadius: widget.cornerRadius - 4,
            ),
          if (widget.vpnService != null)
            _VpnIndicator(
              vpnService: widget.vpnService!,
              onTap: widget.onVpnTap,
              size: buttonSize,
              cornerRadius: widget.cornerRadius - 4,
            ),
          if (widget.onSettings != null)
            _NavButton(
              icon: Icons.settings_rounded,
              enabled: true,
              onPressed: widget.onSettings,
              tooltip: 'Настройки',
              iconColor: iconColor,
              disabledColor: disabledColor,
              size: buttonSize,
              iconSize: iconSize,
              cornerRadius: widget.cornerRadius - 4,
            ),
        ],
      ),
    );
  }
}

class _DownloadsIndicator extends StatelessWidget {
  final DownloadService downloadService;
  final VoidCallback? onTap;
  final double size;
  final double cornerRadius;

  const _DownloadsIndicator({
    required this.downloadService,
    this.onTap,
    this.size = 36.0,
    this.cornerRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final hasActive = downloadService.hasActiveDownloads;
        final hasDownloads = downloadService.downloads.isNotEmpty;
        
        if (!hasDownloads && !hasActive) return const SizedBox.shrink();
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = hasActive 
            ? Colors.blue.withValues(alpha: 0.2)
            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06));
        final iconColor = hasActive ? Colors.blue : (isDark ? Colors.white70 : Colors.black54);
        
        return Tooltip(
          message: hasActive ? 'Загрузка...' : 'Загрузки',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(cornerRadius),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(cornerRadius),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      hasActive ? Icons.downloading_rounded : Icons.download_rounded,
                      size: size * 0.5,
                      color: iconColor,
                    ),
                    if (hasActive)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VpnIndicator extends StatelessWidget {
  final VpnService vpnService;
  final VoidCallback? onTap;
  final double size;
  final double cornerRadius;

  const _VpnIndicator({
    required this.vpnService,
    this.onTap,
    this.size = 36.0,
    this.cornerRadius = 8.0,
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
          bgColor = Colors.grey.withValues(alpha: 0.15);
          iconColor = Colors.grey;
          tooltip = 'VPN отключен';
        }
        
        return Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(cornerRadius),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(cornerRadius),
                ),
                child: isConnecting
                    ? Padding(
                        padding: EdgeInsets.all(size * 0.25),
                        child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
                      )
                    : Icon(
                        isConnected ? Icons.vpn_lock : Icons.vpn_lock_outlined,
                        size: size * 0.5,
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

class _NavButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color iconColor;
  final Color disabledColor;
  final double size;
  final double iconSize;
  final double cornerRadius;

  const _NavButton({
    required this.icon,
    required this.enabled,
    this.onPressed,
    required this.tooltip,
    required this.iconColor,
    required this.disabledColor,
    this.size = 36.0,
    this.iconSize = 20.0,
    this.cornerRadius = 8.0,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoverColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _isHovered && widget.enabled ? hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(widget.cornerRadius),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.enabled ? widget.iconColor : widget.disabledColor,
            ),
          ),
        ),
      ),
    );
  }
}
