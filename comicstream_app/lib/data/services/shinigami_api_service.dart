import 'package:dio/dio.dart';
import '../models/chapter.dart';
import '../models/comic.dart';
import '../models/comic_page.dart';

/// Shinigami is kept behind one adapter so the app can switch sources centrally.
class ShinigamiApiService {
  static const active = true; // Set false to restore the Komiku API.
  final Dio _dio;
  ShinigamiApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.shngm.io',
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Accept': 'application/json',
                'Origin': 'https://app.shinigami.asia',
                'DNT': '1',
              },
            ),
          );

  List<dynamic> _items(dynamic data) => data is List
      ? data
      : (data is Map && data['data'] is List ? data['data'] as List : const []);

  List<String> _names(Map item, String kind) {
    final taxonomy = item['taxonomy'];
    final values = taxonomy is Map ? taxonomy[kind] : null;
    if (values is! List) return [];
    return values
        .whereType<Map>()
        .map((value) => value['name']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  Comic _comic(Map item) => Comic(
    id: 'shngm:${item['manga_id']?.toString() ?? item['id']?.toString() ?? ''}',
    title: item['title']?.toString() ?? 'Unknown',
    coverUrl:
        item['cover_image_url']?.toString() ??
        item['cover_portrait_url']?.toString() ??
        '',
    genres: _names(item, 'Genre'),
    format:
        _names(item, 'Format').firstOrNull ??
        const {
          'KR': 'Manhwa',
          'JP': 'Manga',
          'CN': 'Manhua',
        }[item['country_id']] ??
        'Unknown',
    synopsis: item['description']?.toString() ?? '',
    author: _names(item, 'Author').join(', '),
    status: item['status'] == 1
        ? 'Ongoing'
        : item['status'] == 2
        ? 'Completed'
        : 'Unknown',
  );

  static String genreSlug(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');

  Future<ComicCatalogPage> catalogPage({
    int page = 1,
    String sort = 'latest',
    String? format,
    Set<String> genres = const {},
    String query = '',
  }) async {
    final response = await _dio.get(
      '/v1/manga/list',
      queryParameters: {
        'page': page,
        'page_size': 30,
        'sort': sort,
        if (format != null) 'format': format.toLowerCase(),
        if (genres.isNotEmpty) 'genre': genreSlug(genres.first),
        if (query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    final raw = _items(response.data);
    final meta = response.data is Map ? response.data['meta'] : null;
    final total = meta is Map ? int.tryParse('${meta['total_page']}') : null;
    return ComicCatalogPage(
      raw.whereType<Map>().map(_comic).toList(),
      hasMore: total != null ? page < total : raw.length >= 30,
    );
  }

  Future<List<Comic>> list({
    int page = 1,
    String sort = 'latest',
    String? format,
    Set<String> genres = const {},
  }) async => (await catalogPage(
    page: page,
    sort: sort,
    format: format,
    genres: genres,
  )).comics;

  Future<List<Comic>> search(
    String query, {
    int page = 1,
    String? format,
    Set<String> genres = const {},
  }) async => (await catalogPage(
    query: query,
    page: page,
    format: format,
    genres: genres,
  )).comics;

  Future<Map<String, dynamic>> detail(String id) async {
    id = id.replaceFirst('shngm:', '');
    final response = await _dio.get('/v1/manga/detail/$id');
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw StateError('Detail komik Shinigami tidak tersedia.');
    }
    final comic = _comic(data);
    final chapters = await _dio.get(
      '/v1/chapter/$id/list',
      queryParameters: {'page_size': 3000},
    );
    final items = _items(chapters.data).whereType<Map>().toList();
    final mapped = items.map((item) {
      final chapterId =
          item['chapter_id']?.toString() ?? item['id']?.toString() ?? '';
      final number =
          item['chapter_number']?.toString() ??
          item['number']?.toString() ??
          '0';
      return Chapter(
        id: 'shngm:$id:$chapterId',
        comicId: id,
        chapterNumber: int.tryParse(number.split('.').first) ?? 0,
        title: item['chapter_title']?.toString() ?? item['title']?.toString(),
        releasedAt: Chapter.parseDate(
          item['release_date'] ?? item['created_at'],
        ),
      );
    }).toList();
    return {'comic': comic, 'chapters': mapped};
  }

  Future<List<ComicPage>> pages(String endpoint) async {
    final parts = endpoint.split(':');
    if (parts.length != 3 || parts.first != 'shngm') {
      throw ArgumentError('ID chapter Shinigami tidak valid.');
    }
    final response = await _dio.get('/v1/chapter/detail/${parts[2]}');
    final data = response.data is Map ? response.data['data'] : null;
    final chapter = data is Map ? data['chapter'] : null;
    final base = chapter is Map
        ? (chapter['base_url'] ?? data['base_url_low'] ?? '')
        : '';
    final path = chapter is Map ? (chapter['path'] ?? '') : '';
    final images = chapter is Map && chapter['data'] is List
        ? chapter['data'] as List
        : const [];
    return images
        .asMap()
        .entries
        .map(
          (entry) => ComicPage(
            id: '$endpoint:${entry.key}',
            chapterId: endpoint,
            pageNumber: entry.key + 1,
            imageUrl: '$base$path${entry.value}',
          ),
        )
        .toList();
  }

  Future<List<Comic>> popular({int page = 1, String? format}) =>
      list(page: page, sort: 'popularity', format: format);
}

class ComicCatalogPage {
  final List<Comic> comics;
  final bool hasMore;
  const ComicCatalogPage(this.comics, {required this.hasMore});
}
