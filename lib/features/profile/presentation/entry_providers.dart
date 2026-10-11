import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/profile_entries.dart';
import '../../auth/presentation/auth_providers.dart';

final entryRepositoryProvider = Provider<EntryRepository>(
  (ref) => getIt<EntryRepository>(),
);
final entriesProvider = StreamProvider.autoDispose
    .family<List<ProfileEntry>, EntryKind>((ref, kind) {
      final user = ref.watch(authSessionProvider).asData?.value;
      if (user == null || !user.emailVerified) return Stream.value([]);
      return ref.watch(entryRepositoryProvider).watchEntries(user.uid, kind);
    });
final entryActionsProvider =
    NotifierProvider.autoDispose<EntryActions, AsyncValue<void>>(
      EntryActions.new,
    );

class EntryActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  Future<bool> _run(
    Future<void> Function(EntryRepository, String) action,
  ) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final user = ref.read(authSessionProvider).asData?.value;
      if (user == null || !user.emailVerified) {
        throw const AppFailure('Войдите в свой аккаунт');
      }
      await action(ref.read(entryRepositoryProvider), user.uid);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }

  Future<bool> save(ProfileEntry entry) => _run((repo, uid) async {
    validateEntry(entry);
    await repo.saveEntry(uid, entry);
  });
  Future<bool> delete(EntryKind kind, String id) =>
      _run((repo, uid) => repo.deleteEntry(uid, kind, id));
}
