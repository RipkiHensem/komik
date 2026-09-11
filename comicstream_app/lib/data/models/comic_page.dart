/// Model halaman chapter yang disesuaikan dengan response mangamint API
class ComicPage {
  final String id;
  final String chapterId;
  final int pageNumber;
  final String imageUrl;

  const ComicPage({
    required this.id,
    required this.chapterId,
    required this.pageNumber,
    required this.imageUrl,
  });

  /// Parse dari response /chapter/[endpoint]
  /// Response: { "chapter_pages": [{ "image": "url", "id": "..." }] }
  factory ComicPage.fromJson(Map<String, dynamic> json) {
    return ComicPage(
      id: json['id']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString() ?? '',
      pageNumber: json['page_number'] as int? ?? 0,
      imageUrl: json['image']?.toString() ?? json['image_url']?.toString() ?? '',
    );
  }

  factory ComicPage.fromSupabase(Map<String, dynamic> json) {
    return ComicPage(
      id: json['id']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString() ?? '',
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 0,
      imageUrl: (json['image_url'] ?? json['image'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'page_number': pageNumber,
      'image_url': imageUrl,
    };
  }
}
