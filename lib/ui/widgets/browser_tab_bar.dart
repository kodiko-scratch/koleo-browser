import 'package:flutter/material.dart';
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

  const BrowserTabBar({
    super.key,
    required this.tabs,
    this.groups = const [],
    this.activeTabId,
    this.onTabSelected,
    this.onTabClosed,
    this.onNewTab,
    this.tabManager,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1a1a1a) : const Color(0xFFe8e8e8);

    return GestureDetector(
      onPanStart: (_) => _startWindowDrag(),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: bgColor),
        child: Row(
          children: [
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                children: _buildTabsWithGroups(context),
              ),
            ),
            _NewTabButton(onPressed: onNewTab),
            const SizedBox(width: 8),
            const _WindowControls(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabsWithGroups(BuildContext context) {
    final widgets = <Widget>[];
    final groupedTabIds = <String>{};
    
    // First add grouped tabs
    for (final group in groups) {
      if (group.tabIds.isEmpty) continue;
      
      widgets.add(_GroupChip(
        group: group,
        tabs: tabs.where((t) => group.tabIds.contains(t.id)).toList(),
        activeTabId: activeTabId,
        onTabSelected: onTabSelected,
        onTabClosed: onTabClosed,
        tabManager: tabManager,
      ));
      
      groupedTabIds.addAll(group.tabIds);
    }
    
    // Then add ungrouped tabs
    for (final tab in tabs) {
      if (groupedTabIds.contains(tab.id)) continue;
      
      widgets.add(_TabItem(
        tab: tab,
        isActive: tab.id == activeTabId,
        onTap: () => onTabSelected?.call(tab.id),
        onClose: () => onTabClosed?.call(tab.id),
        tabManager: tabManager,
        groups: groups,
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

/// Group chip that shows collapsed/expanded tabs
class _GroupChip extends StatelessWidget {
  final TabGroup group;
  final List<BrowserTab> tabs;
  final String? activeTabId;
  final ValueChanged<String>? onTabSelected;
  final ValueChanged<String>? onTabClosed;
  final TabManager? tabManager;

  const _GroupChip({
    required this.group,
    required this.tabs,
    this.activeTabId,
    this.onTabSelected,
    this.onTabClosed,
    this.tabManager,
  });

  @override
  Widget build(BuildContext context) {
    if (group.isCollapsed) {
      return _buildCollapsedChip(context);
    }
    return _buildExpandedGroup(context);
  }

  Widget _buildCollapsedChip(BuildContext context) {
    return GestureDetector(
      onTap: () => tabManager?.toggleGroupCollapsed(group.id),
      onSecondaryTapDown: (details) => _showGroupMenu(context, details.globalPosition),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: group.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: group.color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              group.name,
              style: KoleoTypography.caption.copyWith(
                color: group.color,
                fontWeight: FontWeight.w600,
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
                  fontSize: 11,
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
        // Group header
        GestureDetector(
          onTap: () => tabManager?.toggleGroupCollapsed(group.id),
          onSecondaryTapDown: (details) => _showGroupMenu(context, details.globalPosition),
          child: Container(
            margin: const EdgeInsets.only(right: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              border: Border.all(color: group.color, width: 2),
            ),
            child: Text(
              group.name,
              style: KoleoTypography.caption.copyWith(
                color: group.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Tabs in group
        ...tabs.map((tab) => _TabItem(
          tab: tab,
          isActive: tab.id == activeTabId,
          onTap: () => onTabSelected?.call(tab.id),
          onClose: () => onTabClosed?.call(tab.id),
          groupColor: group.color,
          tabManager: tabManager,
          groups: const [],
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
      if (value == 'rename') {
        _showRenameDialog(context);
      } else if (value == 'delete') {
        tabManager?.deleteGroup(group.id);
      }
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

/// Window control buttons (minimize, maximize, close)
class _WindowControls extends StatelessWidget {
  const _WindowControls();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.remove_rounded,
          iconColor: iconColor,
          onTap: _minimizeWindow,
        ),
        _WindowButton(
          icon: Icons.crop_square_rounded,
          iconColor: iconColor,
          onTap: _maximizeWindow,
        ),
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
    final defaultHoverColor = isDark ? Colors.white10 : Colors.black12;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 44,
          color: _isHovered 
              ? (widget.hoverColor ?? defaultHoverColor) 
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 18,
            color: _isHovered && widget.hoverIconColor != null
                ? widget.hoverIconColor
                : widget.iconColor,
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

  const _TabItem({
    required this.tab,
    required this.isActive,
    this.onTap,
    this.onClose,
    this.groupColor,
    this.tabManager,
    this.groups = const [],
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
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: group.color,
                  shape: BoxShape.circle,
                ),
              ),
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
      if (value == 'new_group') {
        _createNewGroup(context);
      } else if (value == 'remove_from_group') {
        widget.tabManager?.removeTabFromGroup(widget.tab.id);
      } else if (value != null && value.startsWith('group_')) {
        final groupId = value.substring(6);
        widget.tabManager?.addTabToGroup(widget.tab.id, groupId);
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
                if (group != null) {
                  widget.tabManager?.addTabToGroup(widget.tab.id, group.id);
                }
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
    
    final activeColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final hoverColor = isDark ? const Color(0xFF252525) : const Color(0xFFf5f5f5);
    final textColor = isDark ? Colors.white : const Color(0xFF1a1a1a);
    final secondaryColor = isDark ? Colors.white60 : const Color(0xFF666666);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 200,
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.isActive 
                ? activeColor 
                : (_isHovered ? hoverColor : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: widget.groupColor != null
                ? Border.all(color: widget.groupColor!, width: 2)
                : (widget.isActive && !isDark 
                    ? Border.all(color: const Color(0xFFe0e0e0)) 
                    : null),
          ),
          child: Row(
            children: [
              // Icon
              SizedBox(
                width: 18,
                height: 18,
                child: widget.tab.isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? KoleoColors.darkAccent : KoleoColors.lightAccent,
                          ),
                        ),
                      )
                    : Icon(
                        widget.tab.url.isEmpty ? Icons.home_rounded : Icons.public_rounded,
                        size: 18,
                        color: widget.isActive ? textColor : secondaryColor,
                      ),
              ),
              const SizedBox(width: 10),
              // Title
              Expanded(
                child: Text(
                  widget.tab.title,
                  style: KoleoTypography.caption.copyWith(
                    color: widget.isActive ? textColor : secondaryColor,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Close button
              if (_isHovered || widget.isActive)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isHovered 
                          ? (isDark ? Colors.white10 : const Color(0xFFe0e0e0))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: secondaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewTabButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _NewTabButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.add_rounded,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}
