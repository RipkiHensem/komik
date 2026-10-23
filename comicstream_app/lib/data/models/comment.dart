/// Model untuk komentar pada halaman detail komik
class Comment {
  final String id;
  final String? comicId;
  final String? chapterId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;
  final bool isSpoiler;

  const Comment({
    required this.id,
    this.comicId,
    this.chapterId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.createdAt,
    this.isSpoiler = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      comicId: json['comic_id']?.toString(),
      chapterId: json['chapter_id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      username: (json['username'] as String?) ?? 'Anonim',
      avatarUrl: json['avatar_url'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isSpoiler: json['is_spoiler'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (comicId != null) 'comic_id': comicId,
      if (chapterId != null) 'chapter_id': chapterId,
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${(diff.inDays / 365).floor()} tahun lalu';
  }
}
