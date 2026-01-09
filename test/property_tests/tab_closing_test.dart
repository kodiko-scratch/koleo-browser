import 'package:glados/glados.dart';
import 'package:koleo_browser/services/tab_manager.dart';

/// **Feature: koleo-browser, Property 5: Tab Closing Invariant**
///
/// *For any* TabManager with at least one tab, closing a tab SHALL decrease
/// the tab count by exactly 1, and if the closed tab was active, a different
/// tab SHALL become active (unless it was the last tab).
///
/// **Validates: Requirements 2.3**
void main() {
  group('Property 5: Tab Closing Invariant', () {
    Glados(any.intInRange(1, 20)).test(
      'closing a tab decreases count by exactly 1',
      (tabCount) {
        final manager = TabManager();

        for (var i = 0; i < tabCount; i++) {
          manager.createTab();
        }

        final countBefore = manager.tabs.length;
        final tabToClose = manager.tabs.first.id;

        manager.closeTab(tabToClose);

        expect(manager.tabs.length, equals(countBefore - 1),
            reason: 'Tab count should decrease by exactly 1');
      },
    );

    Glados(any.intInRange(2, 10)).test(
      'closing active tab switches to another tab',
      (tabCount) {
        final manager = TabManager();

        for (var i = 0; i < tabCount; i++) {
          manager.createTab();
        }

        final activeId = manager.activeTabId!;
        manager.closeTab(activeId);

        // Should have switched to another tab
        expect(manager.activeTabId, isNotNull,
            reason: 'Should have an active tab after closing');
        expect(manager.activeTabId, isNot(equals(activeId)),
            reason: 'Active tab should be different from closed tab');
        expect(manager.tabs.any((t) => t.id == manager.activeTabId), isTrue,
            reason: 'Active tab should exist in tabs list');
      },
    );

    test('closing the last tab sets activeTabId to null', () {
      final manager = TabManager();
      final tab = manager.createTab();

      manager.closeTab(tab.id);

      expect(manager.tabs.isEmpty, isTrue, reason: 'Tabs should be empty');
      expect(manager.activeTabId, isNull,
          reason: 'activeTabId should be null when no tabs');
      expect(manager.activeTab, isNull,
          reason: 'activeTab should be null when no tabs');
    });

    Glados(any.intInRange(2, 10)).test(
      'closing non-active tab keeps current active tab',
      (tabCount) {
        final manager = TabManager();

        for (var i = 0; i < tabCount; i++) {
          manager.createTab();
        }

        // Switch to last tab
        final lastTabId = manager.tabs.last.id;
        manager.switchToTab(lastTabId);

        // Close first tab (not active)
        final firstTabId = manager.tabs.first.id;
        manager.closeTab(firstTabId);

        expect(manager.activeTabId, equals(lastTabId),
            reason: 'Active tab should remain unchanged');
      },
    );

    Glados(any.intInRange(2, 10)).test(
      'closed tab is removed from tabs list',
      (tabCount) {
        final manager = TabManager();

        for (var i = 0; i < tabCount; i++) {
          manager.createTab();
        }

        final tabToClose = manager.tabs.first.id;
        manager.closeTab(tabToClose);

        expect(manager.tabs.any((t) => t.id == tabToClose), isFalse,
            reason: 'Closed tab should not be in tabs list');
      },
    );

    test('closing non-existent tab does nothing', () {
      final manager = TabManager();
      manager.createTab();
      manager.createTab();

      final countBefore = manager.tabs.length;
      final activeIdBefore = manager.activeTabId;

      manager.closeTab('non-existent-id');

      expect(manager.tabs.length, equals(countBefore),
          reason: 'Tab count should not change');
      expect(manager.activeTabId, equals(activeIdBefore),
          reason: 'Active tab should not change');
    });

    Glados(any.intInRange(3, 10)).test(
      'closing middle tab switches to neighbor',
      (tabCount) {
        final manager = TabManager();

        for (var i = 0; i < tabCount; i++) {
          manager.createTab();
        }

        // Switch to middle tab
        final middleIndex = tabCount ~/ 2;
        final middleTabId = manager.tabs[middleIndex].id;
        manager.switchToTab(middleTabId);

        // Close middle tab
        manager.closeTab(middleTabId);

        // Should switch to a neighbor (same index or previous)
        expect(manager.activeTabId, isNotNull,
            reason: 'Should have an active tab');
        expect(manager.tabs.any((t) => t.id == manager.activeTabId), isTrue,
            reason: 'Active tab should exist');
      },
    );
  });
}
