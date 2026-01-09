import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/browser_tab.dart';
import '../models/tab_group.dart';
import '../models/tab_state.dart';

/// Abstract interface for tab management.
abstract class ITabManager {
  List<BrowserTab> get tabs;
  List<TabGroup> get groups;
  BrowserTab? get activeTab;
  String? get activeTabId;

  BrowserTab createTab({String? url, String? groupId});
  void closeTab(String tabId);
  void switchToTab(String tabId);
  void updateTabInfo(String tabId, {String? title, String? faviconUrl, String? url});
  void updateTabLoadingState(String tabId, {bool? isLoading, double? progress});
  
  TabGroup createGroup(String name, {Color? color});
  void deleteGroup(String groupId);
  void addTabToGroup(String tabId, String groupId);
  void removeTabFromGroup(String tabId);
  void renameGroup(String groupId, String name);
  void toggleGroupCollapsed(String groupId);
}

/// Manages browser tabs with reactive state updates and persistence.
class TabManager extends ChangeNotifier implements ITabManager {
  final List<BrowserTab> _tabs = [];
  final List<TabGroup> _groups = [];
  String? _activeTabId;
  final Uuid _uuid = const Uuid();
  
  static const String _tabsKey = 'koleo_tabs';
  static const String _groupsKey = 'koleo_groups';
  static const String _activeTabKey = 'koleo_active_tab';

  @override
  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  
  @override
  List<TabGroup> get groups => List.unmodifiable(_groups);

  @override
  String? get activeTabId => _activeTabId;

  @override
  BrowserTab? get activeTab {
    if (_activeTabId == null) return null;
    try {
      return _tabs.firstWhere((tab) => tab.id == _activeTabId);
    } catch (_) {
      return null;
    }
  }

  /// Returns the current tab state as an immutable snapshot.
  TabState get state => TabState(
        tabs: List.from(_tabs),
        activeTabId: _activeTabId,
      );

  /// Loads saved tabs from storage.
  Future<void> loadSavedTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load tabs
      final tabsJson = prefs.getString(_tabsKey);
      if (tabsJson != null) {
        final tabsList = jsonDecode(tabsJson) as List<dynamic>;
        _tabs.clear();
        for (final tabJson in tabsList) {
          _tabs.add(BrowserTab.fromJson(tabJson as Map<String, dynamic>));
        }
      }
      
      // Load groups
      final groupsJson = prefs.getString(_groupsKey);
      if (groupsJson != null) {
        final groupsList = jsonDecode(groupsJson) as List<dynamic>;
        _groups.clear();
        for (final groupJson in groupsList) {
          _groups.add(TabGroup.fromJson(groupJson as Map<String, dynamic>));
        }
      }
      
      // Load active tab
      _activeTabId = prefs.getString(_activeTabKey);
      if (_activeTabId != null && !_tabs.any((t) => t.id == _activeTabId)) {
        _activeTabId = _tabs.isNotEmpty ? _tabs.first.id : null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tabs: $e');
    }
  }

  /// Saves tabs to storage.
  Future<void> _saveTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save tabs
      final tabsJson = jsonEncode(_tabs.map((t) => t.toJson()).toList());
      await prefs.setString(_tabsKey, tabsJson);
      
      // Save groups
      final groupsJson = jsonEncode(_groups.map((g) => g.toJson()).toList());
      await prefs.setString(_groupsKey, groupsJson);
      
      // Save active tab
      if (_activeTabId != null) {
        await prefs.setString(_activeTabKey, _activeTabId!);
      } else {
        await prefs.remove(_activeTabKey);
      }
    } catch (e) {
      debugPrint('Error saving tabs: $e');
    }
  }

  /// Creates a new tab and makes it active.
  @override
  BrowserTab createTab({String? url, String? groupId}) {
    final tab = BrowserTab(
      id: _uuid.v4(),
      url: url ?? '',
      title: 'Новая вкладка',
      groupId: groupId,
    );
    _tabs.add(tab);
    _activeTabId = tab.id;
    
    // Add to group if specified
    if (groupId != null) {
      final groupIndex = _groups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        _groups[groupIndex].tabIds.add(tab.id);
      }
    }
    
    notifyListeners();
    _saveTabs();
    return tab;
  }

  /// Closes the tab with the given ID.
  @override
  void closeTab(String tabId) {
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index == -1) return;

    final tab = _tabs[index];
    final wasActive = _activeTabId == tabId;
    
    // Remove from group
    if (tab.groupId != null) {
      final groupIndex = _groups.indexWhere((g) => g.id == tab.groupId);
      if (groupIndex != -1) {
        _groups[groupIndex].tabIds.remove(tabId);
      }
    }
    
    _tabs.removeAt(index);

    if (wasActive && _tabs.isNotEmpty) {
      final newIndex = index >= _tabs.length ? _tabs.length - 1 : index;
      _activeTabId = _tabs[newIndex].id;
    } else if (_tabs.isEmpty) {
      _activeTabId = null;
    }

    notifyListeners();
    _saveTabs();
  }

  /// Switches to the tab with the given ID.
  @override
  void switchToTab(String tabId) {
    final exists = _tabs.any((tab) => tab.id == tabId);
    if (!exists) return;

    _activeTabId = tabId;
    notifyListeners();
    _saveTabs();
  }

  /// Updates the title and/or favicon of a tab.
  @override
  void updateTabInfo(String tabId, {String? title, String? faviconUrl, String? url}) {
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index == -1) return;

    final tab = _tabs[index];
    _tabs[index] = tab.copyWith(
      title: title,
      faviconUrl: faviconUrl,
      url: url,
    );
    notifyListeners();
    _saveTabs();
  }

  /// Updates the loading state of a tab.
  @override
  void updateTabLoadingState(String tabId, {bool? isLoading, double? progress}) {
    final index = _tabs.indexWhere((tab) => tab.id == tabId);
    if (index == -1) return;

    final tab = _tabs[index];
    _tabs[index] = tab.copyWith(
      isLoading: isLoading,
      loadingProgress: progress,
    );
    notifyListeners();
    // Don't save on loading state changes - too frequent
  }

  // ===== Group Management =====

  /// Creates a new tab group.
  @override
  TabGroup createGroup(String name, {Color? color}) {
    final group = TabGroup(
      id: _uuid.v4(),
      name: name,
      color: color ?? TabGroup.availableColors[_groups.length % TabGroup.availableColors.length],
    );
    _groups.add(group);
    notifyListeners();
    _saveTabs();
    return group;
  }

  /// Deletes a group and removes all tabs from it.
  @override
  void deleteGroup(String groupId) {
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;
    
    // Remove group reference from all tabs
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].groupId == groupId) {
        _tabs[i] = _tabs[i].copyWith(clearGroup: true);
      }
    }
    
    _groups.removeAt(groupIndex);
    notifyListeners();
    _saveTabs();
  }

  /// Adds a tab to a group.
  @override
  void addTabToGroup(String tabId, String groupId) {
    final tabIndex = _tabs.indexWhere((t) => t.id == tabId);
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    
    if (tabIndex == -1 || groupIndex == -1) return;
    
    // Remove from old group if any
    final oldGroupId = _tabs[tabIndex].groupId;
    if (oldGroupId != null) {
      final oldGroupIndex = _groups.indexWhere((g) => g.id == oldGroupId);
      if (oldGroupIndex != -1) {
        _groups[oldGroupIndex].tabIds.remove(tabId);
      }
    }
    
    // Add to new group
    _tabs[tabIndex] = _tabs[tabIndex].copyWith(groupId: groupId);
    if (!_groups[groupIndex].tabIds.contains(tabId)) {
      _groups[groupIndex].tabIds.add(tabId);
    }
    
    notifyListeners();
    _saveTabs();
  }

  /// Removes a tab from its group.
  @override
  void removeTabFromGroup(String tabId) {
    final tabIndex = _tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex == -1) return;
    
    final groupId = _tabs[tabIndex].groupId;
    if (groupId != null) {
      final groupIndex = _groups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        _groups[groupIndex].tabIds.remove(tabId);
      }
    }
    
    _tabs[tabIndex] = _tabs[tabIndex].copyWith(clearGroup: true);
    notifyListeners();
    _saveTabs();
  }

  /// Renames a group.
  @override
  void renameGroup(String groupId, String name) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    
    _groups[index] = _groups[index].copyWith(name: name);
    notifyListeners();
    _saveTabs();
  }

  /// Toggles group collapsed state.
  @override
  void toggleGroupCollapsed(String groupId) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    
    _groups[index] = _groups[index].copyWith(isCollapsed: !_groups[index].isCollapsed);
    notifyListeners();
    _saveTabs();
  }

  /// Gets group by ID.
  TabGroup? getGroup(String groupId) {
    try {
      return _groups.firstWhere((g) => g.id == groupId);
    } catch (_) {
      return null;
    }
  }

  /// Restores tab state from a TabState object.
  void restoreState(TabState state) {
    _tabs.clear();
    _tabs.addAll(state.tabs);
    _activeTabId = state.activeTabId;
    notifyListeners();
    _saveTabs();
  }
}
