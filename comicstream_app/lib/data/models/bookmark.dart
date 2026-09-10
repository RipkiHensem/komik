class Bookmark {
  final String id;
  final String userId;
  final String comicId;
  final String? lastChapterId;
  final int lastPage;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data (populated when fetched with comic info)
  final String? comicTitle;
  final String? comicCoverUrl;
  final int? lastChapterNumber;

  const Bookmark({
    required this.id,
    required this.userId,
    required this.comicId,
    this.lastChapterId,
    this.lastPage = 1,
    required this.createdAt,
    required this.updatedAt,
    this.comicTitle,
    this.comicCoverUrl,
    this.lastChapterNumber,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      comicId: json['comic_id'] as String,
      lastChapterId: json['last_chapter_id'] as String?,
      lastPage: json['last_page'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      comicTitle: json['comic_title'] as String?,
      comicCoverUrl: json['comic_cover_url'] as String?,
      lastChapterNumber: json['last_chapter_number'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'comic_id': comicId,
      'last_chapter_id': lastChapterId,
      'last_page': lastPage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Progress display text
  String get progressText {
    if (lastChapterNumber != null) {
      return 'Ch. $lastChapterNumber — Hal. $lastPage';
    }
    return 'Halaman $lastPage';
  }
}
