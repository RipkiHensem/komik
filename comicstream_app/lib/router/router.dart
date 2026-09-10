import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers/providers.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/search/search_screen.dart';
import '../presentation/screens/detail/comic_detail_screen.dart';
import '../presentation/screens/reader/reader_screen.dart';
import '../presentation/screens/bookmark/bookmark_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/main/main_shell.dart';

bool _initialAppLaunch = true;

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
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
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/splash',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/bookmarks',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BookmarkScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Detail & Reader (outside shell — no bottom nav)
      GoRoute(
        path: '/comic/:id',
        builder: (context, state) => ComicDetailScreen(
          comicId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/comic/:comicId/chapter/:chapterId',
        builder: (context, state) => ReaderScreen(
          comicId: state.pathParameters['comicId']!,
          chapterId: state.pathParameters['chapterId']!,
        ),
      ),
    ],
  );
});
