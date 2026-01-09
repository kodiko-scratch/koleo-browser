import 'package:glados/glados.dart';
import 'package:koleo_browser/services/tab_manager.dart';

/// **Feature: koleo-browser, Property 4: Tab Switching Correctness**
///
/// *For any* TabManager with multiple tabs and any valid tab ID, switching to
/// that tab SHALL set it as the active tab, and the active tab ID SHALL match
/// the requested ID.
///
/// **Validates: Requirements 2.2**
void main() {
  group('Property 4: Tab Switching Correctness', () {
    Glados(any.intInRange(2, 20)).test(
      'switching to any valid tab sets it as active',
      (tabCount) {
        final manager = TabManager();
        final tabIds = <String>[];

        // Create multiple tabs
        for (var i = 0; i < tabCount; i++) {
          final tab = manager.createTab();
          tabIds.add(tab.id);
        }

        // Switch to each tab and verify it becomes active
        for (final targetId in tabIds) {
          manager.switchToTab(targetId);

          expect(manager.activeTabId, equals(targetId),
              reason: 'activeTabId should match the requested ID');
          expect(manager.activeTab?.id, equals(targetId),
              reason: 'activeTab should return the switched-to tab');
        }
      },
    );

    Glados2(any.intInRange(2, 10), any.intInRange(0, 9)).test(
      'switching to random tab index sets correct active tab',
      (tabCount, targetIndex) {
        if (targetIndex >= tabCount) return;

        final manager = TabManager();
        final tabIds = <String>[];

        // Create tabs
        for (var i = 0; i < tabCount; i++) {
          final tab = manager.createTab();
          tabIds.add(tab.id);
        }

        final targetId = tabIds[targetIndex];
        manager.switchToTab(targetId);

        expect(manager.activeTabId, equals(targetId),
            reason: 'Should switch to tab at index $targetIndex');
      },
    );

    Glados(any.intInRange(2, 10)).test(
      'switching does not change tab count',
      (tabCount) {
        final manager = TabManager();

        for (var i = 0; i < tabCount; i++) {
          manager.createTab();
        }

        final countBefore = manager.tabs.length;
        final firstTabId = manager.tabs.first.id;

        manager.switchToTab(firstTabId);

        expect(manager.tabs.length, equals(countBefore),
            reason: 'Switching should not change tab count');
      },
    );

    test('switching to non-existent tab does nothing', () {
      final manager = TabManager();
      final tab = manager.createTab();

      manager.switchToTab('non-existent-id');

      expect(manager.activeTabId, equals(tab.id),
          reason: 'Active tab should remain unchanged');
    });

    test('switching to already active tab keeps it active', () {
      final manager = TabManager();
      final tab = manager.createTab();

      manager.switchToTab(tab.id);

      expect(manager.activeTabId, equals(tab.id),
          reason: 'Tab should remain active');
    });

    Glados(any.intInRange(3, 10)).test(
      'switching preserves tab order',
      (tabCount) {
        final manager = TabManager();
        final originalIds = <String>[];

        for (var i = 0; i < tabCount; i++) {
          final tab = manager.createTab();
          originalIds.add(tab.id);
        }

        // Switch to first tab
        manager.switchToTab(originalIds.first);

        // Verify order is preserved
        final currentIds = manager.tabs.map((t) => t.id).toList();
        expect(currentIds, equals(originalIds),
            reason: 'Tab order should be preserved after switching');
      },
    );
  });
}
