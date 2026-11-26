import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comic_engagement.dart';

class ComicEngagementRepository {
  final SupabaseClient client;

  const ComicEngagementRepository(this.client);

  Future<ComicEngagement> load(String comicId) async {
    final response = await client.rpc(
      'get_comic_engagement',
      params: {'p_comic_id': comicId},
    );
    final row = switch (response) {
      Map value => Map<String, dynamic>.from(value),
      List values when values.isNotEmpty => Map<String, dynamic>.from(
        values.first as Map,
      ),
      _ => const <String, dynamic>{},
    };
    return ComicEngagement.fromJson(row);
  }

  Future<void> rate(String comicId, int rating) async {
    if (client.auth.currentUser == null) {
      throw Exception('Silakan masuk untuk memberi rating.');
    }
    if (rating < 1 || rating > 10) {
      throw ArgumentError.value(rating, 'rating', 'Harus bernilai 1 sampai 10');
    }
    await client.rpc(
      'rate_comic',
      params: {'p_comic_id': comicId, 'p_rating': rating},
    );
  }
}
