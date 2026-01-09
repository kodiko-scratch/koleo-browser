/// Model representing a browser tab.
///
/// Each tab has a unique ID, URL, title, favicon, and loading state.
class BrowserTab {
  final String id;
  String url;
  String title;
  String? faviconUrl;
  String? groupId;
  bool isLoading;
  double loadingProgress;

  BrowserTab({
    required this.id,
    this.url = '',
    this.title = 'Новая вкладка',
    this.faviconUrl,
    this.groupId,
    this.isLoading = false,
    this.loadingProgress = 0.0,
  });

  /// Creates a copy of this tab with the given fields replaced.
  BrowserTab copyWith({
    String? id,
    String? url,
    String? title,
    String? faviconUrl,
    String? groupId,
    bool clearGroup = false,
    bool? isLoading,
    double? loadingProgress,
  }) {
    return BrowserTab(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      isLoading: isLoading ?? this.isLoading,
      loadingProgress: loadingProgress ?? this.loadingProgress,
    );
  }

  /// Serializes this tab to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'faviconUrl': faviconUrl,
      'groupId': groupId,
      'isLoading': isLoading,
      'loadingProgress': loadingProgress,
    };
  }

  /// Creates a BrowserTab from a JSON map.
  factory BrowserTab.fromJson(Map<String, dynamic> json) {
    return BrowserTab(
      id: json['id'] as String,
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? 'Новая вкладка',
      faviconUrl: json['faviconUrl'] as String?,
      groupId: json['groupId'] as String?,
      isLoading: json['isLoading'] as bool? ?? false,
      loadingProgress: (json['loadingProgress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrowserTab &&
        other.id == id &&
        other.url == url &&
        other.title == title &&
        other.faviconUrl == faviconUrl &&
        other.isLoading == isLoading &&
        other.loadingProgress == loadingProgress;
  }

  @override
  int get hashCode {
    return Object.hash(id, url, title, faviconUrl, isLoading, loadingProgress);
  }

  @override
  String toString() {
    return 'BrowserTab(id: $id, url: $url, title: $title, '
        'faviconUrl: $faviconUrl, isLoading: $isLoading, '
        'loadingProgress: $loadingProgress)';
  }
}
