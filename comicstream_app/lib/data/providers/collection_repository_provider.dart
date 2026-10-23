import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/collection_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return SupabaseCollectionRepository(Supabase.instance.client);
});
