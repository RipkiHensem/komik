class Chapter {
  final String id;
  final String comicId;
  final int chapterNumber;
  final String? title;
  final int pageCount;
  final DateTime releasedAt;

  const Chapter({
    required this.id,
    required this.comicId,
    required this.chapterNumber,
    this.title,
    this.pageCount = 0,
    required this.releasedAt,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      comicId: json['comic_id'] as String,
      chapterNumber: json['chapter_number'] as int,
      title: json['title'] as String?,
      pageCount: json['page_count'] as int? ?? 0,
      releasedAt: DateTime.parse(json['released_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comic_id': comicId,
      'chapter_number': chapterNumber,
      'title': title,
      'page_count': pageCount,
      'released_at': releasedAt.toIso8601String(),
    };
  }

  /// Display name for the chapter
  String get displayName {
    if (title != null && title!.isNotEmpty) {
      // Avoid redundant "Chapter 5: Chapter 5" — only show subtitle if it adds info
      final cleanTitle = title!.trim();
      final chapterPrefix = 'chapter $chapterNumber';
      if (cleanTitle.toLowerCase() == chapterPrefix ||
          cleanTitle.toLowerCase() == 'chapter $chapterNumber') {
        return 'Chapter $chapterNumber';
      }
      return 'Chapter $chapterNumber: $cleanTitle';
    }
    return 'Chapter $chapterNumber';
  }

  /// Relative time since release
  String get relativeTime {
    final diff = DateTime.now().difference(releasedAt);
    if (diff.isNegative || diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${(diff.inDays / 365).floor()} tahun lalu';
  }
}
