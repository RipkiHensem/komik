/// Model Comic yang disesuaikan dengan response dari mangamint API
class Comic {
  final String id; // endpoint/slug dari API, mis: "solo-leveling"
  final String title;
  final String? alternativeTitle;
  final String synopsis;
  final String coverUrl;
  final List<String> genres;
  final String status;
  final String author;
  final String? artist;
  final String format; // Manhwa / Manga / Manhua
  final double rating;
  final int viewCount;
  final int bookmarkCount;
  final int chapterCount;
  final DateTime? updatedAt;

  const Comic({
    required this.id,
    required this.title,
    this.alternativeTitle,
    this.synopsis = '',
    required this.coverUrl,
    this.genres = const [],
    this.status = 'Ongoing',
    this.author = 'Unknown',
    this.artist,
    this.format = 'Manhwa',
    this.rating = 0.0,
    this.viewCount = 0,
    this.bookmarkCount = 0,
    this.chapterCount = 0,
    this.updatedAt,
  });

  /// Parse dari database Supabase
  factory Comic.fromSupabase(Map<String, dynamic> json) {
    return Comic(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      alternativeTitle: json['alternative_title']?.toString(),
      synopsis: json['synopsis']?.toString() ?? '',
      coverUrl: json['cover_url']?.toString() ?? '',
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status']?.toString() ?? 'Ongoing',
      author: json['author']?.toString() ?? 'Unknown',
      artist: json['artist']?.toString(),
      format: json['format']?.toString() ?? 'Manhwa',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      chapterCount: (json['chapter_count'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  /// Parse dari response list (manga/page, manga/popular, dll)
  factory Comic.fromListJson(Map<String, dynamic> json) {
    // genres bisa berupa list of string atau list of object
    List<String> genreList = [];
    if (json['genre_list'] is List) {
      genreList = (json['genre_list'] as List)
          .map((g) => g is Map ? (g['genre_name'] ?? '').toString() : g.toString())
          .toList();
    }

    // type: Manhwa / Manga / Manhua
    final String format = _normalizeFormat(json['type']?.toString() ?? 'Manhwa');

    return Comic(
      id: json['endpoint']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      coverUrl: json['thumb']?.toString() ?? json['cover_url']?.toString() ?? '',
      genres: genreList,
      format: format,
      status: json['status']?.toString() ?? 'Ongoing',
      author: json['author']?.toString() ?? 'Unknown',
      chapterCount: _parseInt(json['chapter_count'] ?? json['total_chapter']),
      synopsis: json['synopsis']?.toString() ?? json['description']?.toString() ?? '',
    );
  }

  /// Parse dari response detail (/manga/detail/[endpoint])
  factory Comic.fromDetailJson(Map<String, dynamic> json) {
    List<String> genreList = [];
    if (json['genre_list'] is List) {
      genreList = (json['genre_list'] as List)
          .map((g) => g is Map ? (g['genre_name'] ?? '').toString() : g.toString())
          .toList();
    }

    final String format = _normalizeFormat(json['type']?.toString() ?? 'Manhwa');

    return Comic(
      // Edge Function: manga_endpoint | fallback ke endpoint, id
      id: json['manga_endpoint']?.toString() ?? json['endpoint']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      alternativeTitle: json['alternative_title']?.toString(),
      synopsis: json['synopsis']?.toString() ?? json['description']?.toString() ?? '',
      // Edge Function: thumb | fallback ke cover_url
      coverUrl: json['thumb']?.toString() ?? json['cover_url']?.toString() ?? '',
      genres: genreList,
      status: json['status']?.toString() ?? 'Ongoing',
      author: json['author']?.toString() ?? 'Unknown',
      artist: json['artist']?.toString(),
      format: format,
      rating: _parseDouble(json['rating'] ?? json['score']),
      chapterCount: _parseInt(json['chapter_count'] ?? json['total_chapter']),
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
    };
  }

  static String _normalizeFormat(String type) {
    final t = type.toLowerCase();
    if (t.contains('manhwa')) return 'Manhwa';
    if (t.contains('manhua')) return 'Manhua';
    return 'Manga';
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  /// Returns a human-friendly relative time for last update
  String get lastUpdatedRelative {
    if (updatedAt == null) return '';
    final diff = DateTime.now().difference(updatedAt!);
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
