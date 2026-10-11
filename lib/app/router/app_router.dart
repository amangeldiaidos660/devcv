import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_user.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/email_verification_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/resume/presentation/resume_screen.dart';
import '../../features/profile/presentation/basic_profile_screen.dart';
import '../../features/profile/presentation/details_editor_screen.dart';
import '../../features/profile/presentation/entry_list_screen.dart';
import '../../features/profile/presentation/entry_editor_screen.dart';
import '../../features/profile/domain/profile_entries.dart';
import '../../features/resume/domain/resume_config.dart';
import '../../features/resume/presentation/resume_builder_screen.dart';
import '../../features/resume/presentation/resume_preview_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';
import 'route_names.dart';

String? authRedirect(AsyncValue<AuthUser?> session, String location) {
  if (session.isLoading || session.hasError) {
    return location == '/splash' ? null : '/splash';
  }
  final user = session.asData?.value;
  if (user == null) {
    return const ['/login', '/register', '/forgot-password'].contains(location)
        ? null
        : '/login';
  }
  if (!user.emailVerified) {
    return location == '/verify-email' ? null : '/verify-email';
  }
  return const [
        '/splash',
        '/login',
        '/register',
        '/forgot-password',
        '/verify-email',
        '/',
      ].contains(location)
      ? '/home'
      : null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authSessionProvider, (_, next) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(ref.read(authSessionProvider), state.uri.path),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/splash'),
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: RouteNames.verifyEmail,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/resume',
                name: RouteNames.resume,
                builder: (context, state) => const ResumeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile/basic',
        name: 'profileBasic',
        builder: (context, state) => const BasicProfileScreen(),
      ),
      GoRoute(
        path: '/profile/details/:section',
        name: 'profileDetails',
        builder: (context, state) => DetailsEditorScreen(
          section: state.pathParameters['section'] ?? 'about',
        ),
      ),
      GoRoute(
        path: '/profile/entries/:kind',
        name: 'profileEntries',
        builder: (context, state) => EntryListScreen(
          kind: EntryKind.values.byName(state.pathParameters['kind']!),
        ),
        routes: [
          GoRoute(
            path: 'add',
            name: 'entryAdd',
            builder: (context, state) => EntryEditorScreen(
              kind: EntryKind.values.byName(state.pathParameters['kind']!),
            ),
          ),
          GoRoute(
            path: ':id/edit',
            name: 'entryEdit',
            builder: (context, state) => EntryEditorScreen(
              kind: EntryKind.values.byName(state.pathParameters['kind']!),
              entry: state.extra as ProfileEntry?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/resume/create',
        name: 'resumeCreate',
        builder: (context, state) =>
            ResumeBuilderScreen(initialConfig: state.extra as ResumeConfig?),
      ),
      GoRoute(
        path: '/resume/preview',
        name: 'resumePreview',
        builder: (context, state) => const ResumePreviewScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
