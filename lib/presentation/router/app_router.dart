import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/profile_screen.dart';
import '../screens/home/edit_profile_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../screens/post/post_detail_screen.dart';
import '../screens/wallet/wallet_screen.dart';

class AppRouter {
  AppRouter._();

  static final _authService = AuthService.instance;

  static final router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authService.isAuthenticated,
    redirect: (context, state) {
      final loggedIn = _authService.isAuthenticated.value;
      final current = state.uri.path;
      final goingToAuth = current == '/auth' || current == '/';

      if (!loggedIn && current == '/home') return '/auth';
      if (loggedIn && goingToAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/wallet', builder: (context, state) => const WalletScreen()),
      GoRoute(path: '/create-post', builder: (context, state) => const CreatePostScreen()),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PostDetailScreen(postId: id);
        },
      ),
      GoRoute(
        path: '/profile/:uid',
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return ProfileScreen(userId: uid);
        },
      ),
    ],
  );
}
