import 'bookmark.dart';

/// Exact normalized titles only: no fuzzy matching of sequels or spin-offs.
class HistoryIdentity {
  static String titleKey(String? title) {
    var value = (title ?? '').trim().toLowerCase();
    value = value.replaceFirst(RegExp(r'^komik\s+'), '');
    value = value.replaceAll(RegExp("['’]"), '');
    value = value
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
        .trim();
    return const {'', 'unknown', 'untitled', 'komik'}.contains(value)
        ? ''
        : value;
  }

  static String _title(Bookmark item) {
    final key = titleKey(item.comicTitle);
    if (key.isNotEmpty) return key;
    // Old Komiku records can lack metadata. Never treat opaque UUIDs as titles.
    final slug = item.comicId
        .replaceAll(RegExp(r'^/+|/+$'), '')
        .replaceFirst(RegExp(r'^manga/'), '');
    if (slug.contains(':') || RegExp(r'^[0-9a-f-]{32,}$').hasMatch(slug)) {
      return '';
    }
    return RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(slug)
        ? titleKey(slug)
        : '';
  }

  static bool sameComic(Bookmark a, Bookmark b) {
    if (a.userId != b.userId) return false;
    if (a.comicId == b.comicId) return true;
    if (a.comicId.startsWith('shngm:') == b.comicId.startsWith('shngm:')) {
      return false;
    }
    final key = _title(a);
    return key.isNotEmpty && key == _title(b);
  }

  static List<List<Bookmark>> groups(Iterable<Bookmark> items) {
    final sorted = items.toList()
      ..sort(
        (a, b) =>
            (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt),
      );
    final result = <List<Bookmark>>[];
    for (final item in sorted) {
      final group = result
          .where((group) => sameComic(group.first, item))
          .firstOrNull;
      if (group == null) {
        result.add([item]);
      } else {
        group.add(item);
      }
    }
    return result;
  }

  static List<Bookmark> merge(Iterable<Bookmark> items) =>
      groups(items).map((group) => group.first).toList();
}
