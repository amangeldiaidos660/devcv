import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_message.dart';
import '../../auth/presentation/auth_providers.dart';
import 'profile_form.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).asData?.value;
    final profile = ref.watch(currentProfileProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());
    return profile.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorMessage(
              error: error,
              onRetry: () => ref.invalidate(currentProfileProvider),
            ),
          ),
        ),
      ),
      data: (data) => ProfileForm(
        key: ValueKey(user.uid),
        profile: data,
        email: user.email ?? '',
      ),
    );
  }
}
