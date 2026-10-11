import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/widgets/error_message.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../profile/domain/developer_profile.dart';
import '../../profile/domain/profile_completion.dart';
import '../../profile/presentation/profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).asData?.value;
    final profile = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('DevCV')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Developer Profile & Resume Builder',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              profile.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => ErrorMessage(
                  error: error,
                  onRetry: () => ref.invalidate(currentProfileProvider),
                ),
                data: (data) => _ProfileCard(
                  profile: data,
                  email: user?.email,
                  completion: ProfileCompletion.calculate(
                    profile: data,
                    email: user?.email,
                    emailVerified: user?.emailVerified ?? false,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.goNamed(RouteNames.profile),
                icon: const Icon(Icons.person_outline),
                label: const Text('Продолжить заполнение профиля'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.goNamed(RouteNames.resume),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Создать резюме'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.email,
    required this.completion,
  });
  final DeveloperProfile? profile;
  final String? email;
  final int completion;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile?.fullName.trim().isNotEmpty ?? false)
            Text(
              profile?.fullName ?? '',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          Text(email ?? 'Email отсутствует'),
          const SizedBox(height: 20),
          Text('Заполнение базового профиля: $completion%'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completion / 100,
            semanticsLabel: 'Заполнение базового профиля',
          ),
        ],
      ),
    ),
  );
}
