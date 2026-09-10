class Comic {
  final String id;
  final String title;
  final String? alternativeTitle;
  final String synopsis;
  final String coverUrl;
  final List<String> genres;
  final String status;
  final String author;
  final String? artist;
  final String format;
  final double rating;
  final int viewCount;
  final int bookmarkCount;
  final int chapterCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Comic({
    required this.id,
    required this.title,
    this.alternativeTitle,
    required this.synopsis,
    required this.coverUrl,
    required this.genres,
    required this.status,
    required this.author,
    this.artist,
    required this.format,
    this.rating = 0.0,
    this.viewCount = 0,
    this.bookmarkCount = 0,
    this.chapterCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      id: json['id'] as String,
      title: json['title'] as String,
      alternativeTitle: json['alternative_title'] as String?,
      synopsis: json['synopsis'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      genres: (json['genre'] is List)
          ? List<String>.from(json['genre'])
          : (json['genre'] as String?)?.split(',').map((e) => e.trim()).toList() ?? [],
      status: json['status'] as String? ?? 'Ongoing',
      author: json['author'] as String? ?? 'Unknown',
      artist: json['artist'] as String?,
      format: json['format'] as String? ?? 'Manhwa',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      viewCount: json['view_count'] as int? ?? 0,
      bookmarkCount: json['bookmark_count'] as int? ?? 0,
      chapterCount: json['chapter_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'alternative_title': alternativeTitle,
      'synopsis': synopsis,
      'cover_url': coverUrl,
      'genre': genres,
      'status': status,
      'author': author,
      'artist': artist,
      'format': format,
      'rating': rating,
      'view_count': viewCount,
      'bookmark_count': bookmarkCount,
      'chapter_count': chapterCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Returns a human-friendly relative time for last update
  String get lastUpdatedRelative {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  /// Flag emoji based on format
  String get formatFlag {
    switch (format.toLowerCase()) {
      case 'manhwa':
        return '🇰🇷';
      case 'manga':
        return '🇯🇵';
      case 'manhua':
        return '🇨🇳';
      default:
        return '🌐';
    }
  }

  /// Formatted view count (e.g., 1.2M, 300K)
  String get formattedViews {
    if (viewCount >= 1000000) {
      final val = viewCount / 1000000;
      return val == val.roundToDouble() ? '${val.toInt()}M' : '${val.toStringAsFixed(1)}M';
    }
    if (viewCount >= 1000) {
      final val = viewCount / 1000;
      return val == val.roundToDouble() ? '${val.toInt()}K' : '${val.toStringAsFixed(1)}K';
    }
    return viewCount.toString();
  }

  /// Formatted bookmark count (e.g., 250K, 1.2M)
  String get formattedBookmarks {
    if (bookmarkCount >= 1000000) {
      final val = bookmarkCount / 1000000;
      return val == val.roundToDouble() ? '${val.toInt()}M' : '${val.toStringAsFixed(1)}M';
    }
    if (bookmarkCount >= 1000) {
      final val = bookmarkCount / 1000;
      return val == val.roundToDouble() ? '${val.toInt()}K' : '${val.toStringAsFixed(1)}K';
    }
    return bookmarkCount.toString();
  }
}
