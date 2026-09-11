/// Model Chapter yang disesuaikan dengan response dari mangamint API
class Chapter {
  final String id; // endpoint/slug chapter, mis: "solo-leveling-chapter-1"
  final String comicId; // endpoint/slug comic
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
      id: json['endpoint']?.toString() ?? json['id']?.toString() ?? '',
      comicId: json['comic_id']?.toString() ?? '',
      chapterNumber: _parseInt(json['chapter_number']),
      title: json['title']?.toString(),
      pageCount: _parseInt(json['page_count']),
      releasedAt: _parseDate(json['released_at'] ?? json['date']),
    );
  }

  factory Chapter.fromSupabase(Map<String, dynamic> json) {
    return Chapter(
      id: json['id']?.toString() ?? '',
      comicId: json['comic_id']?.toString() ?? '',
      chapterNumber: (json['chapter_number'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString(),
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
      releasedAt: json['released_at'] != null
          ? (DateTime.tryParse(json['released_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
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

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString().replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Display name for the chapter
  String get displayName {
    if (title != null && title!.isNotEmpty) {
      final cleanTitle = title!.trim();
      final lower = cleanTitle.toLowerCase();
      if (lower == 'chapter $chapterNumber' || lower == 'ch. $chapterNumber') {
        return 'Chapter $chapterNumber';
      }
      // If title already contains chapter number, just show the title
      if (lower.startsWith('chapter')) return cleanTitle;
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
