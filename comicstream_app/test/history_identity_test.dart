import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comicstream_app/data/models/bookmark.dart';
import 'package:comicstream_app/data/providers/providers.dart';
import 'package:comicstream_app/data/services/auth_service.dart';
import 'package:comicstream_app/data/models/user.dart';

class DuplicateHistory extends SupabaseAuthService {
  int clears = 0;
  @override
  User? getCurrentUser() => null;
  @override
  Future<void> clearHistory() async {
    clears++;
  }

  @override
  Future<List<Bookmark>> getMyHistory() async => [
    Bookmark(
      id: 'new',
      userId: 'reader',
      comicId: 'shngm:uuid',
      comicTitle: 'Eleceed',
      lastChapterId: 'shngm:uuid:chapter',
      lastPage: 7,
      createdAt: DateTime(2026, 11, 5),
    ),
    Bookmark(
      id: 'old',
      userId: 'reader',
      comicId: 'eleceed',
      comicTitle: 'Komik Eleceed',
      lastChapterId: 'eleceed-chapter-50',
      lastPage: 3,
      createdAt: DateTime(2026, 10, 1),
    ),
  ];
}

class HistoryAuth extends AuthNotifier {
  HistoryAuth(super.service);
  void signIn() => state = AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'reader',
      username: 'reader',
      email: 'reader@example.test',
      createdAt: DateTime(2026),
    ),
  );
  void signOut() => state = const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  test(
    'history follows account changes without clearing saved history on logout',
    () async {
      final service = DuplicateHistory();
      final auth = HistoryAuth(service);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          supabaseAuthServiceProvider.overrideWithValue(service),
          comicChaptersProvider('shngm:uuid').overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(historyProvider).requireValue, isEmpty);
      auth.signIn();
      final notifier = container.read(historyProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(historyProvider).requireValue, hasLength(1));
      auth.signIn();
      expect(container.read(historyProvider.notifier), same(notifier));
      auth.signOut();
      expect(container.read(historyProvider).requireValue, isEmpty);
      expect(service.clears, 0);
    },
  );

  test(
    'history shows one comic after moving from Komiku to Shinigami',
    () async {
      final notifier = HistoryNotifier(DuplicateHistory(), true);
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.requireValue, hasLength(1));
      expect(notifier.state.requireValue.single.comicId, 'shngm:uuid');
      expect(notifier.state.requireValue.single.lastPage, 7);
    },
  );
}
