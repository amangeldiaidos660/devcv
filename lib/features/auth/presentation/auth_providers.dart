import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/validators.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => getIt<AuthRepository>(),
);

final authSessionProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).watchUser(),
);

final authActionsProvider = NotifierProvider<AuthController, AsyncValue<void>>(
  AuthController.new,
);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<bool> _run(Future<void> Function(AuthRepository) action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await action(ref.read(authRepositoryProvider));
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }

  Future<bool> signIn(String email, String password) =>
      _run((repository) async {
        final message =
            Validators.email(email) ?? Validators.loginPassword(password);
        if (message != null) throw AppFailure(message);
        await repository.signIn(email.trim(), password);
      });

  Future<bool> register(String email, String password, String repeated) =>
      _run((repository) async {
        final message =
            Validators.email(email) ??
            Validators.password(password) ??
            Validators.repeatPassword(repeated, password);
        if (message != null) throw AppFailure(message);
        await repository.register(email.trim(), password);
      });

  Future<bool> signInWithGoogle() =>
      _run((repository) => repository.signInWithGoogle());
  Future<bool> signOut() => _run((repository) => repository.signOut());
  Future<bool> resetPassword(String email) => _run((repository) async {
    final message = Validators.email(email);
    if (message != null) throw AppFailure(message);
    await repository.resetPassword(email.trim());
  });
  Future<bool> sendVerificationEmail() =>
      _run((repository) => repository.sendVerificationEmail());
  Future<bool> reloadUser() => _run((repository) => repository.reloadUser());
}
