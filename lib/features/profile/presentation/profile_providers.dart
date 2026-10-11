import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/validators.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/developer_profile.dart';
import '../domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => getIt<ProfileRepository>(),
);
final authEmailProvider = Provider<String>(
  (ref) => ref.watch(authSessionProvider).asData?.value?.email ?? '',
);

final currentProfileProvider = StreamProvider.autoDispose<DeveloperProfile?>((
  ref,
) {
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null || !user.emailVerified) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(user.uid);
});

final profileActionsProvider =
    NotifierProvider.autoDispose<ProfileController, AsyncValue<void>>(
      ProfileController.new,
    );

class ProfileController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save({
    required String fullName,
    required DateTime? birthDate,
    required String city,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final user = ref.read(authSessionProvider).asData?.value;
      if (user == null || !user.emailVerified || user.email == null) {
        throw const AppFailure('Войдите в аккаунт с подтверждённым email');
      }
      final message =
          Validators.fullName(fullName) ??
          Validators.city(city) ??
          Validators.birthDate(birthDate);
      if (message != null) throw AppFailure(message);
      final repository = ref.read(profileRepositoryProvider);
      await repository.saveProfile(
        DeveloperProfile(
          uid: user.uid,
          email: user.email ?? '',
          fullName: fullName.trim(),
          birthDate: birthDate,
          city: city.trim(),
        ),
      );
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }
}

final profileDirtyProvider =
    NotifierProvider.autoDispose<ProfileDirtyController, bool>(
      ProfileDirtyController.new,
    );

class ProfileDirtyController extends Notifier<bool> {
  @override
  bool build() => false;
  void setDirty(bool value) => state = value;
}
