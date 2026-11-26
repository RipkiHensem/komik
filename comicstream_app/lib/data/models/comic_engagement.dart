class ComicEngagement {
  final int readerCount;
  final int bookmarkCount;
  final double ratingAverage;
  final int ratingCount;
  final int? userRating;

  const ComicEngagement({
    this.readerCount = 0,
    this.bookmarkCount = 0,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.userRating,
  });

  factory ComicEngagement.fromJson(Map<String, dynamic> json) {
    return ComicEngagement(
      readerCount: (json['reader_count'] as num?)?.toInt() ?? 0,
      bookmarkCount: (json['bookmark_count'] as num?)?.toInt() ?? 0,
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      userRating: (json['user_rating'] as num?)?.toInt(),
    );
  }
}
