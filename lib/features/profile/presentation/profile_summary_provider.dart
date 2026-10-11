import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_entries.dart';
import '../domain/profile_completion.dart';
import '../../auth/presentation/auth_providers.dart';
import 'entry_providers.dart';
import 'profile_providers.dart';

final profileCompletionProvider = Provider<int>((ref) {
  final profile = ref.watch(currentProfileProvider).asData?.value;
  final user = ref.watch(authSessionProvider).asData?.value;
  return ProfileCompletion.calculate(
    profile: profile,
    email: user?.email,
    emailVerified: user?.emailVerified ?? false,
    counts: {
      for (final kind in EntryKind.values)
        kind: ref.watch(entriesProvider(kind)).asData?.value.length ?? 0,
    },
  );
});
