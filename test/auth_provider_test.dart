import 'dart:async';

import 'package:devcv/core/errors/app_failure.dart';
import 'package:devcv/features/auth/data/auth_error_mapper.dart';
import 'package:devcv/features/auth/presentation/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Known Firebase errors are mapped without exposing technical text', () {
    expect(
      authFailure('invalid-credential').message,
      'Неверный email или пароль',
    );
    expect(
      authFailure('email-already-in-use').message,
      contains('уже существует'),
    );
    expect(
      authFailure('network-request-failed').message,
      contains('интернету'),
    );
  });
  test(
    'Auth operations drive session, verification, Google and sign out',
    () async {
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() async {
        container.dispose();
        await repository.dispose();
      });
      final session = container.listen(authSessionProvider, (_, next) {});
      addTearDown(session.close);
      expect(await container.read(authSessionProvider.future), isNull);
      final actions = container.read(authActionsProvider.notifier);
      expect(
        await actions.register(
          ' dev@example.com ',
          'password123',
          'password123',
        ),
        isTrue,
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.receivedEmail, 'dev@example.com');
      expect(repository.verificationCalls, 1);
      expect(
        container.read(authSessionProvider).asData?.value?.emailVerified,
        isFalse,
      );
      repository.verificationConfirmed = true;
      expect(await actions.reloadUser(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(authSessionProvider).asData?.value?.emailVerified,
        isTrue,
      );
      expect(await actions.signOut(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authSessionProvider).asData?.value, isNull);
      expect(await actions.signInWithGoogle(), isTrue);
      expect(repository.googleCalls, 1);
      expect(await actions.resetPassword(' dev@example.com '), isTrue);
      expect(repository.resetCalls, 1);
    },
  );
  test('Validation prevents repository calls; errors and duplicate submits are handled', () async {
    final repository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });
    final actions = container.read(authActionsProvider.notifier);
    expect(await actions.signIn('invalid', ''), isFalse);
    expect(repository.signInCalls, 0);
    repository.gate = Completer<void>();
    repository.failure = const AppFailure('Проверьте подключение к интернету');
    final first = actions.signIn('dev@example.com', 'password123');
    expect(container.read(authActionsProvider).isLoading, isTrue);
    expect(await actions.signIn('dev@example.com', 'password123'), isFalse);
    expect(repository.signInCalls, 1);
    repository.gate?.complete();
    expect(await first, isFalse);
    expect(container.read(authActionsProvider).hasError, isTrue);
    repository.failure = null;
    expect(await actions.signIn('dev@example.com', 'password123'), isTrue);
  });
}
