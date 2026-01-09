import 'browser_tab.dart';

/// Model representing the state of all browser tabs.
///
/// Contains the list of tabs and the ID of the currently active tab.
class TabState {
  final List<BrowserTab> tabs;
  final String? activeTabId;

  TabState({
    required this.tabs,
    this.activeTabId,
  });

  /// Creates a copy of this state with the given fields replaced.
  TabState copyWith({
    List<BrowserTab>? tabs,
    String? activeTabId,
  }) {
    return TabState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
    );
  }

  /// Serializes this state to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'tabs': tabs.map((tab) => tab.toJson()).toList(),
      'activeTabId': activeTabId,
    };
  }

  /// Creates a TabState from a JSON map.
  factory TabState.fromJson(Map<String, dynamic> json) {
    final tabsList = (json['tabs'] as List<dynamic>?)
            ?.map((tabJson) =>
                BrowserTab.fromJson(tabJson as Map<String, dynamic>))
            .toList() ??
        [];

    return TabState(
      tabs: tabsList,
      activeTabId: json['activeTabId'] as String?,
    );
  }

  /// Returns the currently active tab, or null if no tab is active.
  BrowserTab? get activeTab {
    if (activeTabId == null) return null;
    try {
      return tabs.firstWhere((tab) => tab.id == activeTabId);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TabState) return false;
    if (other.activeTabId != activeTabId) return false;
    if (other.tabs.length != tabs.length) return false;
    for (int i = 0; i < tabs.length; i++) {
      if (other.tabs[i] != tabs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(Object.hashAll(tabs), activeTabId);
  }

  @override
  String toString() {
    return 'TabState(tabs: $tabs, activeTabId: $activeTabId)';
  }
}
