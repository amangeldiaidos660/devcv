import 'dart:async';

import 'package:devcv/core/errors/app_failure.dart';
import 'package:devcv/features/auth/domain/auth_user.dart';
import 'package:devcv/features/auth/presentation/auth_providers.dart';
import 'package:devcv/features/profile/presentation/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Profile follows the authenticated UID and does not expose the previous account', () async {
    final auth = FakeAuthRepository(user: verifiedUser);
    final profiles = FakeProfileRepository();
    profiles.profiles['user-1'] = sampleProfile();
    profiles.profiles['user-2'] = sampleProfile(uid: 'user-2');
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(profiles),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await auth.dispose();
      await profiles.dispose();
    });
    final session = container.listen(authSessionProvider, (_, next) {});
    addTearDown(session.close);
    final subscription = container.listen(currentProfileProvider, (_, next) {});
    addTearDown(subscription.close);
    await container.read(authSessionProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(
      (await container.read(currentProfileProvider.future))?.uid,
      'user-1',
    );
    auth.emit(
      const AuthUser(
        uid: 'user-2',
        email: 'second@example.com',
        emailVerified: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      (await container.read(currentProfileProvider.future))?.uid,
      'user-2',
    );
    auth.emit(null);
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(currentProfileProvider.future), isNull);
  });
  test(
    'Profile save validates fields, trims data and prevents duplicate submits',
    () async {
      final auth = FakeAuthRepository(user: verifiedUser);
      final profiles = FakeProfileRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(profiles),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await auth.dispose();
        await profiles.dispose();
      });
      final session = container.listen(authSessionProvider, (_, next) {});
      addTearDown(session.close);
      final subscription = container.listen(
        profileActionsProvider,
        (_, next) {},
      );
      addTearDown(subscription.close);
      await container.read(authSessionProvider.future);
      final actions = container.read(profileActionsProvider.notifier);
      expect(
        await actions.save(fullName: ' ', birthDate: null, city: ' '),
        isFalse,
      );
      expect(profiles.saveCalls, 0);
      profiles.saveGate = Completer<void>();
      final first = actions.save(
        fullName: ' Айдос ',
        birthDate: DateTime(2000),
        city: ' Алматы ',
      );
      expect(container.read(profileActionsProvider).isLoading, isTrue);
      expect(
        await actions.save(
          fullName: 'Айдос',
          birthDate: DateTime(2000),
          city: 'Алматы',
        ),
        isFalse,
      );
      expect(profiles.saveCalls, 1);
      profiles.saveGate?.complete();
      expect(await first, isTrue);
      expect(profiles.lastSaved?.email, verifiedUser.email);
      expect(profiles.lastSaved?.fullName, 'Айдос');
      expect(profiles.lastSaved?.city, 'Алматы');
      profiles.failure = const AppFailure('Нет доступа');
      expect(
        await actions.save(
          fullName: 'Айдос',
          birthDate: DateTime(2000),
          city: 'Алматы',
        ),
        isFalse,
      );
      expect(container.read(profileActionsProvider).hasError, isTrue);
    },
  );
}
