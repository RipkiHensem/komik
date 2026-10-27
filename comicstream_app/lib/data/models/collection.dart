/// Model untuk Koleksi Publik — folder komik buatan user yang bisa dilihat publik
class Collection {
  final String id;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final String name;
  final String? description;
  final bool isPublic;
  final List<CollectionItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Collection({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.name,
    this.description,
    this.isPublic = true,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    for (final field in ['id', 'user_id', 'name']) {
      if (json[field] is! String || (json[field] as String).trim().isEmpty) {
        throw FormatException('Field koleksi tidak valid: $field');
      }
    }
    final rawItems = json['collection_items'] as List<dynamic>? ?? [];
    final rawUsername = json['username'] as String?;
    final username = rawUsername?.trim();
    return Collection(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: username == null || username.isEmpty ? 'User' : username,
      userAvatarUrl: json['user_avatar_url'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      items: rawItems
          .map((e) => CollectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  int get itemCount => items.length;

  /// Ambil cover dari 4 komik pertama untuk preview grid
  List<String> get previewCovers => items
      .take(4)
      .map((i) => i.comicCoverUrl ?? '')
      .where((url) => url.isNotEmpty)
      .toList();
}

class CollectionItem {
  final String id;
  final String collectionId;
  final String comicId;
  final String? comicTitle;
  final String? comicCoverUrl;
  final DateTime addedAt;

  const CollectionItem({
    required this.id,
    required this.collectionId,
    required this.comicId,
    this.comicTitle,
    this.comicCoverUrl,
    required this.addedAt,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] as String,
      collectionId: json['collection_id'] as String,
      comicId: json['comic_id'] as String,
      comicTitle: json['comic_title'] as String?,
      comicCoverUrl: json['comic_cover_url'] as String?,
      addedAt:
          DateTime.tryParse(json['added_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
