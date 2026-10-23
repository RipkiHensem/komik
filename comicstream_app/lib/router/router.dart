import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers/providers.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/password_recovery_screens.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/search/search_screen.dart';
import '../presentation/screens/detail/comic_detail_screen.dart';
import '../presentation/screens/reader/reader_screen.dart';
import '../presentation/screens/bookmark/bookmark_screen.dart';
import '../presentation/screens/bookmark/collections_screen.dart';
import '../presentation/screens/bookmark/collection_detail_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/main/main_shell.dart';
import '../presentation/screens/admin/admin_comics_screen.dart';

bool _initialAppLaunch = true;

final routerProvider = Provider<GoRouter>((ref) {
  // Keep one router instance alive. Watching authProvider here recreated
  // GoRouter whenever login changed to/from loading, resetting navigation to
  // initialLocation (/home) before the request could finish.
  final refreshListenable = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.status != next.status) {
      refreshListenable.value++;
    }
  });

  final router = GoRouter(
    refreshListenable: refreshListenable,
    initialLocation: '/home',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.status == AuthStatus.authenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // On initial launch or page refresh, go directly into the website (/home)
      if (_initialAppLaunch) {
        _initialAppLaunch = false;
        if (state.matchedLocation == '/splash' ||
            state.matchedLocation == '/' ||
            isAuthRoute) {
          return '/home';
        }
      }

      // Any navigation to /splash or root / goes to /home
      if (state.matchedLocation == '/splash' || state.matchedLocation == '/') {
        return '/home';
      }

      // Authenticated but on auth route → redirect to home
      if (isAuth && isAuthRoute) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(path: '/splash', redirect: (context, state) => '/home'),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminComicsScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: '/bookmarks',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BookmarkScreen()),
          ),
          GoRoute(
            path: '/collections',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CollectionsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // Detail & Reader (outside shell — no bottom nav)
      GoRoute(
        path: '/comic/:id',
        builder: (context, state) =>
            ComicDetailScreen(comicId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/comic/:comicId/chapter/:chapterId',
        builder: (context, state) => ReaderScreen(
          comicId: state.pathParameters['comicId']!,
          chapterId: state.pathParameters['chapterId']!,
        ),
      ),
      GoRoute(
        path: '/collections/:id',
        builder: (context, state) => CollectionDetailScreen(
          collectionId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshListenable.dispose();
  });

  return router;
});
