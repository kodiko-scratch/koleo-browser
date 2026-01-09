import 'dart:math';

import '../models/wallpaper_image.dart';

export '../models/wallpaper_image.dart';

/// Abstract interface for the Wallpaper Service.
abstract class IWallpaperService {
  Future<WallpaperImage> getRandomWallpaper();
  Future<List<WallpaperImage>> getWallpaperCollection();
  Future<void> refreshWallpapers();
}

/// Implementation of the Wallpaper Service.
/// 
/// Manages background images for the home screen, providing a collection
/// of nature-themed wallpapers from Unsplash.
class WallpaperService implements IWallpaperService {
  final Random _random;
  
  /// Built-in collection of nature wallpapers from Unsplash (free to use).
  static const List<_WallpaperData> _builtInWallpapers = [
    _WallpaperData(
      id: 'nature_01',
      assetPath: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&q=80',
      category: WallpaperCategory.mountains,
      author: 'Samuel Ferrara',
    ),
    _WallpaperData(
      id: 'nature_02',
      assetPath: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1920&q=80',
      category: WallpaperCategory.nature,
      author: 'Lukasz Szmigiel',
    ),
    _WallpaperData(
      id: 'ocean_01',
      assetPath: 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=1920&q=80',
      category: WallpaperCategory.ocean,
      author: 'Frank McKenna',
    ),
    _WallpaperData(
      id: 'forest_01',
      assetPath: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1920&q=80',
      category: WallpaperCategory.forest,
      author: 'Sebastian Unrau',
    ),
    _WallpaperData(
      id: 'sky_01',
      assetPath: 'https://images.unsplash.com/photo-1517483000871-1dbf64a6e1c6?w=1920&q=80',
      category: WallpaperCategory.sky,
      author: 'Luca Bravo',
    ),
    _WallpaperData(
      id: 'mountains_02',
      assetPath: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1920&q=80',
      category: WallpaperCategory.mountains,
      author: 'Kalen Emsley',
    ),
    _WallpaperData(
      id: 'forest_02',
      assetPath: 'https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?w=1920&q=80',
      category: WallpaperCategory.forest,
      author: 'Geran de Klerk',
    ),
    _WallpaperData(
      id: 'ocean_02',
      assetPath: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1920&q=80',
      category: WallpaperCategory.ocean,
      author: 'Sean Oulashin',
    ),
  ];

  List<WallpaperImage> _cachedWallpapers = [];

  /// Creates a WallpaperService instance.
  /// 
  /// [random] can be provided for testing purposes.
  WallpaperService({Random? random}) : _random = random ?? Random();

  /// Returns a random wallpaper from the collection.
  /// 
  /// The returned WallpaperImage will have a non-empty URL and a valid category.
  @override
  Future<WallpaperImage> getRandomWallpaper() async {
    final collection = await getWallpaperCollection();
    if (collection.isEmpty) {
      // Return a default wallpaper if collection is empty
      return const WallpaperImage(
        id: 'default',
        url: 'assets/wallpapers/nature_01.jpg',
        category: WallpaperCategory.nature,
        author: 'Koleo',
      );
    }
    final index = _random.nextInt(collection.length);
    return collection[index];
  }

  /// Returns the full collection of available wallpapers.
  /// 
  /// Each wallpaper has a non-empty URL and a valid WallpaperCategory.
  @override
  Future<List<WallpaperImage>> getWallpaperCollection() async {
    if (_cachedWallpapers.isEmpty) {
      _cachedWallpapers = _builtInWallpapers
          .map((data) => WallpaperImage(
                id: data.id,
                url: data.assetPath,
                author: data.author,
                category: data.category,
              ))
          .toList();
    }
    return List.unmodifiable(_cachedWallpapers);
  }

  /// Refreshes the wallpaper collection.
  /// 
  /// Clears the cache and reloads wallpapers on next access.
  @override
  Future<void> refreshWallpapers() async {
    _cachedWallpapers = [];
  }
}

/// Internal data class for built-in wallpaper definitions.
class _WallpaperData {
  final String id;
  final String assetPath;
  final WallpaperCategory category;
  final String? author;

  const _WallpaperData({
    required this.id,
    required this.assetPath,
    required this.category,
    this.author,
  });
}
