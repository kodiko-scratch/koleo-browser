/// Model representing a wallpaper image for the home screen.

/// Categories for wallpaper images.
enum WallpaperCategory {
  nature,
  mountains,
  ocean,
  forest,
  sky,
}

/// Represents a wallpaper image with metadata.
class WallpaperImage {
  final String id;
  final String url;
  final String? author;
  final WallpaperCategory category;

  const WallpaperImage({
    required this.id,
    required this.url,
    this.author,
    required this.category,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WallpaperImage &&
        other.id == id &&
        other.url == url &&
        other.author == author &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(id, url, author, category);

  @override
  String toString() =>
      'WallpaperImage(id: $id, url: $url, author: $author, category: $category)';
}
