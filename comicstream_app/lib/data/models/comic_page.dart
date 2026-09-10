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

  factory ComicPage.fromJson(Map<String, dynamic> json) {
    return ComicPage(
      id: json['id'] as String,
      chapterId: json['chapter_id'] as String,
      pageNumber: json['page_number'] as int,
      imageUrl: json['image_url'] as String,
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
