import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../../models/browser_tab.dart';
import '../../models/tab_group.dart';
import '../../services/tab_manager.dart';
import '../theme/theme.dart';

/// Rounded tab bar with modern design, groups and window controls
class BrowserTabBar extends StatelessWidget {
  final List<BrowserTab> tabs;
  final List<TabGroup> groups;
  final String? activeTabId;
  final ValueChanged<String>? onTabSelected;
  final ValueChanged<String>? onTabClosed;
  final VoidCallback? onNewTab;
  final TabManager? tabManager;
  final Color accentColor;
  final double cornerRadius;
  final bool compactMode;
  final double tabHeight;
  final bool showTabIcons;
  final double tabWidth;

  const BrowserTabBar({
    super.key,
    required this.tabs,
    this.groups = const [],
    this.activeTabId,
    this.onTabSelected,
    this.onTabClosed,
    this.onNewTab,
    this.tabManager,
    this.accentColor = const Color(0xFF4a9eff),
    this.cornerRadius = 16.0,
    this.compactMode = false,
    this.tabHeight = 40.0,
    this.showTabIcons = true,
    this.tabWidth = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onPanStart: (_) => _startWindowDrag(),
      child: Container(
        height: tabHeight + 8,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: compactMode ? 3 : 4),
        child: Row(
          children: [
            Expanded(
              child: _ScrollableTabList(
                children: _buildTabsWithGroups(context),
              ),
            ),
            _NewTabButton(
              onPressed: onNewTab,
              accentColor: accentColor,
              compactMode: compactMode,
            ),
            const SizedBox(width: 8),
            _WindowControls(isDark: isDark),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabsWithGroups(BuildContext context) {
    final widgets = <Widget>[];
    final groupedTabIds = <String>{};
    
    for (final group in groups) {
      if (group.tabIds.isEmpty) continue;
      widgets.add(_GroupChip(
        group: group,
        tabs: tabs.where((t) => group.tabIds.contains(t.id)).toList(),
        activeTabId: activeTabId,
        onTabSelected: onTabSelected,
        onTabClosed: onTabClosed,
        tabManager: tabManager,
        cornerRadius: cornerRadius,
        compactMode: compactMode,
        tabHeight: tabHeight,
        showTabIcons: showTabIcons,
        tabWidth: tabWidth,
      ));
      groupedTabIds.addAll(group.tabIds);
    }
    
    for (final tab in tabs) {
      if (groupedTabIds.contains(tab.id)) continue;
      widgets.add(_TabItem(
        tab: tab,
        isActive: tab.id == activeTabId,
        onTap: () => onTabSelected?.call(tab.id),
        onClose: () => onTabClosed?.call(tab.id),
        tabManager: tabManager,
        groups: groups,
        accentColor: accentColor,
        cornerRadius: cornerRadius,
        compactMode: compactMode,
        tabHeight: tabHeight,
        showTabIcons: showTabIcons,
        tabWidth: tabWidth,
      ));
    }
    return widgets;
  }
  
  void _startWindowDrag() {
    final hwnd = GetForegroundWindow();
    ReleaseCapture();
    SendMessage(hwnd, WM_NCLBUTTONDOWN, HTCAPTION, 0);
  }
}

class _GroupChip extends StatelessWidget {
  final TabGroup group;
  final List<BrowserTab> tabs;
  final String? activeTabId;
  final ValueChanged<String>? onTabSelected;
  final ValueChanged<String>? onTabClosed;
  final TabManager? tabManager;
  final double cornerRadius;
  final bool compactMode;
  final double tabHeight;
  final bool showTabIcons;
  final double tabWidth;

  const _GroupChip({
    required this.group,
    required this.tabs,
    this.activeTabId,
    this.onTabSelected,
    this.onTabClosed,
    this.tabManager,
    this.cornerRadius = 16.0,
    this.compactMode = false,
    this.tabHeight = 40.0,
    this.showTabIcons = true,
    this.tabWidth = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    if (group.isCollapsed) return _buildCollapsedChip(context);
    return _buildExpandedGroup(context);
  }

  Widget _buildCollapsedChip(BuildContext context) {
    return GestureDetector(
      onTap: () => tabManager?.toggleGroupCollapsed(group.id),
      onSecondaryTapDown: (details) => _showGroupMenu(context, details.globalPosition),
      child: Container(
        height: tabHeight,
        margin: const EdgeInsets.only(right: 4),
        padding: EdgeInsets.symmetric(horizontal: compactMode ? 10 : 12, vertical: compactMode ? 4 : 6),
        decoration: BoxDecoration(
          color: group.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(cornerRadius - 6),
          border: Border.all(color: group.color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              group.name,
              style: KoleoTypography.caption.copyWith(
                color: group.color,
                fontWeight: FontWeight.w600,
                fontSize: compactMode ? 11 : 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: group.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${tabs.length}',
                style: KoleoTypography.caption.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedGroup(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => tabManager?.toggleGroupCollapsed(group.id),
          onSecondaryTapDown: (details) => _showGroupMenu(context, details.globalPosition),
          child: Container(
            height: tabHeight,
            margin: const EdgeInsets.only(right: 2),
            padding: EdgeInsets.symmetric(horizontal: compactMode ? 8 : 10, vertical: compactMode ? 4 : 6),
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(cornerRadius - 6)),
              border: Border.all(color: group.color.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Text(
              group.name,
              style: KoleoTypography.caption.copyWith(
                color: group.color,
                fontWeight: FontWeight.w600,
                fontSize: compactMode ? 11 : 12,
              ),
            ),
          ),
        ),
        ...tabs.map((tab) => _TabItem(
          tab: tab,
          isActive: tab.id == activeTabId,
          onTap: () => onTabSelected?.call(tab.id),
          onClose: () => onTabClosed?.call(tab.id),
          groupColor: group.color,
          tabManager: tabManager,
          groups: const [],
          cornerRadius: cornerRadius,
          compactMode: compactMode,
          tabHeight: tabHeight,
          showTabIcons: showTabIcons,
          tabWidth: tabWidth,
        )),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showGroupMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        const PopupMenuItem(value: 'rename', child: Text('Переименовать')),
        const PopupMenuItem(value: 'delete', child: Text('Удалить группу')),
      ],
    ).then((value) {
      if (value == 'rename') _showRenameDialog(context);
      else if (value == 'delete') tabManager?.deleteGroup(group.id);
    });
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Переименовать группу'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Название группы'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              tabManager?.renameGroup(group.id, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

class _WindowControls extends StatelessWidget {
  final bool isDark;
  const _WindowControls({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(icon: Icons.remove_rounded, iconColor: iconColor, onTap: _minimizeWindow),
        _WindowButton(icon: Icons.crop_square_rounded, iconColor: iconColor, onTap: _maximizeWindow),
        _WindowButton(
          icon: Icons.close_rounded,
          iconColor: iconColor,
          hoverColor: const Color(0xFFe81123),
          hoverIconColor: Colors.white,
          onTap: _closeWindow,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _minimizeWindow() {
    final hwnd = GetForegroundWindow();
    ShowWindow(hwnd, SW_MINIMIZE);
  }

  void _maximizeWindow() {
    final hwnd = GetForegroundWindow();
    final placement = calloc<WINDOWPLACEMENT>();
    placement.ref.length = sizeOf<WINDOWPLACEMENT>();
    GetWindowPlacement(hwnd, placement);
    if (placement.ref.showCmd == SW_MAXIMIZE) {
      ShowWindow(hwnd, SW_RESTORE);
    } else {
      ShowWindow(hwnd, SW_MAXIMIZE);
    }
    calloc.free(placement);
  }

  void _closeWindow() {
    final hwnd = GetForegroundWindow();
    PostMessage(hwnd, WM_CLOSE, 0, 0);
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color? hoverColor;
  final Color? hoverIconColor;
  final VoidCallback onTap;

  const _WindowButton({
    required this.icon,
    required this.iconColor,
    this.hoverColor,
    this.hoverIconColor,
    required this.onTap,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultHoverColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 36,
          decoration: BoxDecoration(
            color: _isHovered ? (widget.hoverColor ?? defaultHoverColor) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered && widget.hoverIconColor != null ? widget.hoverIconColor : widget.iconColor,
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final BrowserTab tab;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final Color? groupColor;
  final TabManager? tabManager;
  final List<TabGroup> groups;
  final Color accentColor;
  final double cornerRadius;
  final bool compactMode;
  final double tabHeight;
  final bool showTabIcons;
  final double tabWidth;

  const _TabItem({
    required this.tab,
    required this.isActive,
    this.onTap,
    this.onClose,
    this.groupColor,
    this.tabManager,
    this.groups = const [],
    this.accentColor = const Color(0xFF4a9eff),
    this.cornerRadius = 16.0,
    this.compactMode = false,
    this.tabHeight = 40.0,
    this.showTabIcons = true,
    this.tabWidth = 180.0,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;

  void _showContextMenu(BuildContext context, Offset position) {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'new_group', child: Text('Добавить в новую группу')),
    ];
    if (widget.groups.isNotEmpty) {
      items.add(const PopupMenuDivider());
      for (final group in widget.groups) {
        items.add(PopupMenuItem(
          value: 'group_${group.id}',
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: group.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Добавить в "${group.name}"'),
            ],
          ),
        ));
      }
    }
    if (widget.tab.groupId != null) {
      items.add(const PopupMenuDivider());
      items.add(const PopupMenuItem(value: 'remove_from_group', child: Text('Убрать из группы')));
    }

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: items,
    ).then((value) {
      if (value == 'new_group') _createNewGroup(context);
      else if (value == 'remove_from_group') widget.tabManager?.removeTabFromGroup(widget.tab.id);
      else if (value != null && value.startsWith('group_')) {
        widget.tabManager?.addTabToGroup(widget.tab.id, value.substring(6));
      }
    });
  }

  void _createNewGroup(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая группа'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Название группы'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final group = widget.tabManager?.createGroup(controller.text);
                if (group != null) widget.tabManager?.addTabToGroup(widget.tab.id, group.id);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;
    final hoverColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final secondaryColor = isDark ? Colors.white60 : const Color(0xFF666666);
    final radius = widget.cornerRadius - 6;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.tabWidth,
          height: widget.tabHeight,
          margin: const EdgeInsets.only(right: 4),
          padding: EdgeInsets.symmetric(horizontal: widget.compactMode ? 10 : 12),
          decoration: BoxDecoration(
            color: widget.isActive ? activeColor : (_isHovered ? hoverColor : Colors.transparent),
            borderRadius: BorderRadius.circular(radius),
            border: widget.groupColor != null
                ? Border.all(color: widget.groupColor!.withValues(alpha: 0.5), width: 1.5)
                : (widget.isActive 
                    ? Border.all(color: widget.accentColor.withValues(alpha: 0.3), width: 1)
                    : null),
          ),
          child: Row(
            children: [
              if (widget.showTabIcons) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: widget.tab.isLoading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                          ),
                        )
                      : Icon(
                          widget.tab.url.isEmpty ? Icons.home_rounded : Icons.public_rounded,
                          size: 16,
                          color: widget.isActive ? textColor : secondaryColor,
                        ),
                ),
                SizedBox(width: widget.compactMode ? 6 : 8),
              ],
              Expanded(
                child: Text(
                  widget.tab.title,
                  style: KoleoTypography.caption.copyWith(
                    color: widget.isActive ? textColor : secondaryColor,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: widget.compactMode ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isHovered || widget.isActive)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _isHovered ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.close_rounded, size: 12, color: secondaryColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewTabButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool compactMode;

  const _NewTabButton({this.onPressed, this.accentColor = const Color(0xFF4a9eff), this.compactMode = false});

  @override
  State<_NewTabButton> createState() => _NewTabButtonState();
}

class _NewTabButtonState extends State<_NewTabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(widget.compactMode ? 6 : 8),
          decoration: BoxDecoration(
            color: _isHovered ? widget.accentColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.add_rounded,
            size: widget.compactMode ? 18 : 20,
            color: _isHovered ? widget.accentColor : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

/// Scrollable tab list with mouse wheel support
class _ScrollableTabList extends StatefulWidget {
  final List<Widget> children;

  const _ScrollableTabList({required this.children});

  @override
  State<_ScrollableTabList> createState() => _ScrollableTabListState();
}

class _ScrollableTabListState extends State<_ScrollableTabList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final delta = event.scrollDelta.dy;
      final newOffset = _scrollController.offset + delta;
      _scrollController.jumpTo(
        newOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handleScroll,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        children: widget.children,
      ),
    );
  }
}
