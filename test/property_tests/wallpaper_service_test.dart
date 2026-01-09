import 'dart:math';

import 'package:glados/glados.dart';
import 'package:koleo_browser/services/wallpaper_service.dart';

/// **Feature: koleo-browser, Property 9: Wallpaper Service Validity**
///
/// *For any* call to getRandomWallpaper(), the returned WallpaperImage SHALL
/// have a non-empty URL and a valid category from the WallpaperCategory enum.
///
/// **Validates: Requirements 4.1, 4.3**
void main() {
  group('Property 9: Wallpaper Service Validity', () {
    // Test that getRandomWallpaper returns a wallpaper with non-empty URL
    Glados(any.int).test(
      'getRandomWallpaper returns wallpaper with non-empty URL',
      (seed) async {
        final random = Random(seed.abs());
        final service = WallpaperService(random: random);

        final wallpaper = await service.getRandomWallpaper();

        expect(
          wallpaper.url.isNotEmpty,
          isTrue,
          reason: 'Wallpaper URL should not be empty',
        );
      },
    );

    // Test that getRandomWallpaper returns a wallpaper with valid category
    Glados(any.int).test(
      'getRandomWallpaper returns wallpaper with valid category',
      (seed) async {
        final random = Random(seed.abs());
        final service = WallpaperService(random: random);

        final wallpaper = await service.getRandomWallpaper();

        expect(
          WallpaperCategory.values.contains(wallpaper.category),
          isTrue,
          reason: 'Wallpaper category should be a valid WallpaperCategory',
        );
      },
    );

    // Test that getRandomWallpaper returns a wallpaper with non-empty ID
    Glados(any.int).test(
      'getRandomWallpaper returns wallpaper with non-empty ID',
      (seed) async {
        final random = Random(seed.abs());
        final service = WallpaperService(random: random);

        final wallpaper = await service.getRandomWallpaper();

        expect(
          wallpaper.id.isNotEmpty,
          isTrue,
          reason: 'Wallpaper ID should not be empty',
        );
      },
    );

    // Test that getWallpaperCollection returns non-empty list
    test('getWallpaperCollection returns non-empty list', () async {
      final service = WallpaperService();

      final collection = await service.getWallpaperCollection();

      expect(
        collection.isNotEmpty,
        isTrue,
        reason: 'Wallpaper collection should not be empty',
      );
    });

    // Test that all wallpapers in collection have valid properties
    test('all wallpapers in collection have non-empty URLs and valid categories', () async {
      final service = WallpaperService();

      final collection = await service.getWallpaperCollection();

      for (final wallpaper in collection) {
        expect(
          wallpaper.url.isNotEmpty,
          isTrue,
          reason: 'Wallpaper ${wallpaper.id} should have non-empty URL',
        );
        expect(
          WallpaperCategory.values.contains(wallpaper.category),
          isTrue,
          reason: 'Wallpaper ${wallpaper.id} should have valid category',
        );
        expect(
          wallpaper.id.isNotEmpty,
          isTrue,
          reason: 'Wallpaper should have non-empty ID',
        );
      }
    });

    // Test that refreshWallpapers clears cache and reloads
    test('refreshWallpapers clears cache and allows reload', () async {
      final service = WallpaperService();

      // Get initial collection
      final collection1 = await service.getWallpaperCollection();
      expect(collection1.isNotEmpty, isTrue);

      // Refresh
      await service.refreshWallpapers();

      // Get collection again - should still work
      final collection2 = await service.getWallpaperCollection();
      expect(collection2.isNotEmpty, isTrue);
      expect(collection2.length, equals(collection1.length));
    });

    // Test that random wallpaper is always from the collection
    Glados(any.int).test(
      'getRandomWallpaper returns wallpaper from collection',
      (seed) async {
        final random = Random(seed.abs());
        final service = WallpaperService(random: random);

        final collection = await service.getWallpaperCollection();
        final randomWallpaper = await service.getRandomWallpaper();

        expect(
          collection.contains(randomWallpaper),
          isTrue,
          reason: 'Random wallpaper should be from the collection',
        );
      },
    );
  });
}
