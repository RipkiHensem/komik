import 'package:supabase_flutter/supabase_flutter.dart';

/// Caption overrides for comics supplied by the external catalog.
/// Authorization for writes is enforced by Postgres RLS.
class ComicCaptionRepository {
  final SupabaseClient _client;

  ComicCaptionRepository(this._client);

  Future<String?> getCaption(String comicId) async {
    final row = await _client
        .from('comic_synopsis_overrides')
        .select('synopsis')
        .eq('comic_id', comicId)
        .maybeSingle();
    return row?['synopsis'] as String?;
  }

  Future<void> saveCaption(String comicId, String synopsis) async {
    final cleaned = synopsis.trim();
    if (cleaned.isEmpty || cleaned.length > 5000) {
      throw ArgumentError('Caption harus berisi 1–5000 karakter.');
    }
    await _client
        .from('comic_synopsis_overrides')
        .upsert({
          'comic_id': comicId,
          'synopsis': cleaned,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('comic_id')
        .single();
  }
}
