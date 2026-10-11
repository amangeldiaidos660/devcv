import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/config/app_features.dart';
import '../../../core/errors/app_failure.dart';
import '../data/details_mapper.dart';
import '../domain/avatar_repository.dart';
import '../domain/details_validation.dart';
import '../domain/profile_details.dart';
import '../../auth/presentation/auth_providers.dart';
import 'profile_providers.dart';

final avatarRepositoryProvider = Provider<AvatarRepository>(
  (ref) => getIt<AvatarRepository>(),
);
final detailsActionsProvider =
    NotifierProvider.autoDispose<DetailsActions, AsyncValue<void>>(
      DetailsActions.new,
    );

class DetailsActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  Future<bool> _run(Future<bool> Function(String) action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final user = ref.read(authSessionProvider).asData?.value;
      if (user == null || !user.emailVerified) {
        throw const AppFailure('Войдите в свой аккаунт');
      }
      final result = await action(user.uid);
      if (ref.mounted) state = const AsyncData(null);
      return result;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }

  Future<bool> contacts(ProfileContacts contacts) => _run((uid) async {
    final email = ref.read(authSessionProvider).asData?.value?.email ?? '';
    final error = DetailsValidation.contacts(contacts, email);
    if (error != null) throw AppFailure(error);
    await ref.read(profileRepositoryProvider).updateDetails(uid, {
      'contacts': DetailsMapper.contacts(contacts),
    });
    return true;
  });
  Future<bool> preferences(CareerPreferences preferences) => _run((uid) async {
    final error = DetailsValidation.salary(
      preferences.salaryEnabled,
      preferences.minimumSalary,
    );
    if (error != null) throw AppFailure(error);
    await ref.read(profileRepositoryProvider).updateDetails(uid, {
      'preferences': DetailsMapper.preferences(preferences),
    });
    return true;
  });
  Future<bool> about(String text) => _run((uid) async {
    final error = DetailsValidation.about(text);
    if (error != null) throw AppFailure(error);
    await ref.read(profileRepositoryProvider).updateDetails(uid, {
      'aboutMe': text.trim(),
    });
    return true;
  });
  Future<bool> avatar(String? previousPath) async {
    if (!ref.read(profilePhotosEnabledProvider)) return false;
    return _run(
      (uid) =>
          ref.read(avatarRepositoryProvider).selectAndUpload(uid, previousPath),
    );
  }
}
