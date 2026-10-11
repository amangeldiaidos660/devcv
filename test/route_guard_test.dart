import 'package:devcv/app/router/app_router.dart';
import 'package:devcv/features/auth/domain/auth_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Guard handles loading, error, anonymous, unverified and verified states without loops', () {
    expect(authRedirect(const AsyncLoading<AuthUser?>(), '/home'), '/splash');
    expect(authRedirect(const AsyncLoading<AuthUser?>(), '/splash'), isNull);
    expect(
      authRedirect(
        AsyncError<AuthUser?>(Exception(), StackTrace.current),
        '/profile',
      ),
      '/splash',
    );
    for (final path in [
      '/home',
      '/profile',
      '/resume',
      '/settings',
      '/verify-email',
    ]) {
      expect(authRedirect(const AsyncData<AuthUser?>(null), path), '/login');
    }
    for (final path in ['/login', '/register', '/forgot-password']) {
      expect(authRedirect(const AsyncData<AuthUser?>(null), path), isNull);
      expect(
        authRedirect(const AsyncData<AuthUser?>(verifiedUser), path),
        '/home',
      );
    }
    expect(
      authRedirect(const AsyncData<AuthUser?>(unverifiedUser), '/home'),
      '/verify-email',
    );
    expect(
      authRedirect(const AsyncData<AuthUser?>(unverifiedUser), '/verify-email'),
      isNull,
    );
    expect(
      authRedirect(const AsyncData<AuthUser?>(verifiedUser), '/home'),
      isNull,
    );
  });
}
