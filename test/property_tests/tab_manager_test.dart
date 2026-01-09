import 'package:glados/glados.dart';
import 'package:koleo_browser/services/tab_manager.dart';

/// **Feature: koleo-browser, Property 3: Tab Creation Invariant**
///
/// *For any* TabManager state, creating a new tab SHALL increase the tab count
/// by exactly 1, and the new tab SHALL appear in the tabs list.
///
/// **Validates: Requirements 2.1**
void main() {
  group('Property 3: Tab Creation Invariant', () {
    Glados(any.intInRange(0, 20)).test(
      'creating a tab increases count by exactly 1',
      (initialTabCount) {
        final manager = TabManager();

        // Create initial tabs
        for (var i = 0; i < initialTabCount; i++) {
          manager.createTab();
        }

        final countBefore = manager.tabs.length;
        expect(countBefore, equals(initialTabCount));

        // Create one more tab
        final newTab = manager.createTab();

        final countAfter = manager.tabs.length;
        expect(countAfter, equals(countBefore + 1),
            reason: 'Tab count should increase by exactly 1');

        // Verify the new tab is in the list
        expect(manager.tabs.any((t) => t.id == newTab.id), isTrue,
            reason: 'New tab should appear in the tabs list');
      },
    );

    Glados(any.intInRange(0, 10)).test(
      'new tab becomes the active tab',
      (initialTabCount) {
        final manager = TabManager();

        // Create initial tabs
        for (var i = 0; i < initialTabCount; i++) {
          manager.createTab();
        }

        final newTab = manager.createTab();

        expect(manager.activeTabId, equals(newTab.id),
            reason: 'New tab should become active');
        expect(manager.activeTab?.id, equals(newTab.id),
            reason: 'activeTab should return the new tab');
      },
    );

    Glados2(any.letterOrDigits, any.letterOrDigits).test(
      'tab created with URL has correct URL',
      (urlPart1, urlPart2) {
        final manager = TabManager();
        final url = 'https://$urlPart1.$urlPart2.com';

        final tab = manager.createTab(url: url);

        expect(tab.url, equals(url), reason: 'Tab should have the provided URL');
        expect(manager.tabs.last.url, equals(url),
            reason: 'Tab in list should have the provided URL');
      },
    );

    test('tab created without URL has empty URL', () {
      final manager = TabManager();
      final tab = manager.createTab();

      expect(tab.url, equals(''), reason: 'Tab without URL should have empty URL');
    });

    test('new tab has default title', () {
      final manager = TabManager();
      final tab = manager.createTab();

      expect(tab.title, equals('Новая вкладка'),
          reason: 'New tab should have default title');
    });

    test('each created tab has unique ID', () {
      final manager = TabManager();
      final ids = <String>{};

      for (var i = 0; i < 100; i++) {
        final tab = manager.createTab();
        expect(ids.contains(tab.id), isFalse,
            reason: 'Each tab should have a unique ID');
        ids.add(tab.id);
      }
    });
  });
}
