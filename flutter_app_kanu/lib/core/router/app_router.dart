import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/community/community_screen.dart';
import '../../features/compatibility/compatibility_tab.dart';
import '../../features/home/home_tab.dart';
import '../../features/info/info_screen.dart';
import '../../features/legal/legal_screen.dart';
import '../../features/messages/chat_screen.dart';
import '../../features/messages/messages_tab.dart';
import '../../features/not_found/not_found_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/profile/profile_detail_screen.dart';
import '../../features/profile/profile_tab.dart';
import '../../features/questionnaire/questionnaire_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/search/search_tab.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../state/auth_controller.dart';
import '../../state/startup_controller.dart';

/// Construction du graphe de navigation (go_router).
///
/// Les cinq onglets principaux vivent dans une [StatefulShellRoute] afin de
/// conserver leur état ; les écrans de détail et d'authentification sont des
/// routes de haut niveau.
class AppRouter {
  const AppRouter._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String search = '/search';
  static const String compatibility = '/compatibility';
  static const String messages = '/messages';
  static const String profile = '/profile';

  static const Set<String> _protectedPrefixes = {
    home,
    search,
    compatibility,
    messages,
    profile,
    '/questionnaire',
    '/premium',
    '/settings',
    '/membre',
    '/chat',
    '/report',
  };

  static bool _isProtected(String location) {
    for (final String prefix in _protectedPrefixes) {
      if (location == prefix || location.startsWith('$prefix/')) {
        return true;
      }
    }
    return false;
  }

  static String? _redirect(
    Ref ref,
    GoRouterState state,
  ) {
    final AuthState auth = ref.read(authControllerProvider);
    final StartupState startup = ref.read(startupControllerProvider);
    final String location = state.matchedLocation;
    final bool isSplash = location == splash;
    final bool isAuthRoute = location == login ||
        location == register ||
        location == forgotPassword;
    final bool isOnboarding = location == onboarding;

    if (auth.status == AuthStatus.unknown) {
      return isSplash ? null : splash;
    }

    if (isSplash) {
      if (auth.isAuthenticated) return home;
      return startup.onboardingDone ? login : onboarding;
    }

    if (auth.isAuthenticated && (isAuthRoute || isOnboarding)) {
      return home;
    }

    if (!auth.isAuthenticated && _isProtected(location)) {
      return login;
    }

    return null;
  }

  static List<RouteBase> _routes() {
    return [
      GoRoute(
        path: splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/questionnaire',
        builder: (_, _) => const QuestionnaireScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (_, _) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/community',
        builder: (_, _) => const CommunityScreen(),
      ),
      GoRoute(
        path: '/concept',
        builder: (_, _) => const InfoScreen(slug: 'concept'),
      ),
      GoRoute(
        path: '/comment-ca-fonctionne',
        builder: (_, _) => const InfoScreen(slug: 'comment-ca-fonctionne'),
      ),
      GoRoute(
        path: '/valeurs',
        builder: (_, _) => const InfoScreen(slug: 'valeurs'),
      ),
      GoRoute(
        path: '/securite',
        builder: (_, _) => const InfoScreen(slug: 'securite'),
      ),
      GoRoute(
        path: '/faq',
        builder: (_, _) => const InfoScreen(slug: 'faq'),
      ),
      GoRoute(
        path: '/legal/:slug',
        builder: (_, GoRouterState state) =>
            LegalScreen(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        path: '/membre/:id',
        builder: (_, GoRouterState state) =>
            ProfileDetailScreen(memberId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, GoRouterState state) => ChatScreen(
          otherId: state.pathParameters['id'] ?? '',
          compatibilityId: state.uri.queryParameters['compatibility'] ?? '',
        ),
      ),
      GoRoute(
        path: '/report/:id',
        builder: (_, GoRouterState state) =>
            ReportScreen(memberId: state.pathParameters['id'] ?? ''),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: home, builder: (_, _) => const HomeTab()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: search, builder: (_, _) => const SearchTab()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: compatibility,
                builder: (_, _) => const CompatibilityTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: messages,
                builder: (_, _) => const MessagesTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: profile, builder: (_, _) => const ProfileTab()),
            ],
          ),
        ],
      ),
    ];
  }
}

/// Fournit l'instance unique de [GoRouter] et la rafraîchit lorsque l'état
/// d'authentification ou de démarrage change.
final routerProvider = Provider<GoRouter>((ref) {
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(startupControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRouter.splash,
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) =>
        AppRouter._redirect(ref, state),
    errorBuilder: (BuildContext context, GoRouterState state) =>
        const NotFoundScreen(),
    routes: AppRouter._routes(),
  );
});
