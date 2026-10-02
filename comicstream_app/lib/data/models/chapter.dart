/// Model Chapter yang disesuaikan dengan response dari mangamint API
class Chapter {
  final String id; // endpoint/slug chapter, mis: "solo-leveling-chapter-1"
  final String comicId; // endpoint/slug comic
  final int chapterNumber;
  final String? title;
  final int pageCount;
  final DateTime? releasedAt;

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
      releasedAt: parseDate(json['released_at'] ?? json['date']),
    );
  }

  factory Chapter.fromSupabase(Map<String, dynamic> json) {
    return Chapter(
      id: json['id']?.toString() ?? '',
      comicId: json['comic_id']?.toString() ?? '',
      chapterNumber: (json['chapter_number'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString(),
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
      releasedAt: DateTime.tryParse(json['released_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comic_id': comicId,
      'chapter_number': chapterNumber,
      'title': title,
      'page_count': pageCount,
      'released_at': releasedAt?.toIso8601String(),
    };
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString().replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  }

  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    final raw = v.toString().trim();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      final relative = raw.toLowerCase();
      if (relative.contains('baru saja') || relative.contains('just now')) {
        return DateTime.now();
      }
      if (relative.contains('kemarin') || relative.contains('yesterday')) {
        return DateTime.now().subtract(const Duration(days: 1));
      }

      final match = RegExp(
        r'(\d+)\s*(detik|second|menit|minute|jam|hour|hari|day|minggu|week|bulan|month|tahun|year)',
      ).firstMatch(relative);
      if (match != null) {
        final amount = int.tryParse(match.group(1)!) ?? 0;
        final unit = match.group(2)!;
        final duration = switch (unit) {
          'detik' || 'second' => Duration(seconds: amount),
          'menit' || 'minute' => Duration(minutes: amount),
          'jam' || 'hour' => Duration(hours: amount),
          'hari' || 'day' => Duration(days: amount),
          'minggu' || 'week' => Duration(days: amount * 7),
          'bulan' || 'month' => Duration(days: amount * 30),
          'tahun' || 'year' => Duration(days: amount * 365),
          _ => Duration.zero,
        };
        return DateTime.now().subtract(duration);
      }

      final dateMatch = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$')
          .firstMatch(raw);
      if (dateMatch != null) {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final year = int.parse(dateMatch.group(3)!);
        return DateTime(year, month, day);
      }
      return null;
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
    return relativeTimeAt() ?? 'Waktu tidak tersedia';
  }

  String? relativeTimeAt([DateTime? fallback]) {
    final timestamp = releasedAt ?? fallback;
    if (timestamp == null) return null;
    final diff = DateTime.now().difference(timestamp);
    if (diff.isNegative || diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${(diff.inDays / 365).floor()} tahun lalu';
  }
}
