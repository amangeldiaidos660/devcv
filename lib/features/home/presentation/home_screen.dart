import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/error_message.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../profile/domain/profile_entries.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../profile/presentation/profile_summary_provider.dart';
import '../../profile/presentation/entry_providers.dart';
import '../../profile/presentation/profile_avatar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).asData?.value;
    final profile = ref.watch(currentProfileProvider);
    final completion = ref.watch(profileCompletionProvider);
    final data = profile.asData?.value;
    return Scaffold(
      appBar: AppBar(title: const Text('DevCV')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(
                'Добро пожаловать',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data?.fullName.isNotEmpty == true
                          ? data!.fullName
                          : 'Ваш следующий шаг',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ProfileAvatar(
                    name: data?.fullName ?? '',
                    url: data?.avatarUrl,
                    radius: 28,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Developer Profile & Resume Builder'),
              const SizedBox(height: 24),
              if (profile.isLoading)
                const LoadingState()
              else if (profile.hasError)
                ErrorMessage(
                  error: profile.error!,
                  onRetry: () => ref.invalidate(currentProfileProvider),
                )
              else
                ProfileCompletionCard(
                  percent: completion,
                  onContinue: () => context.goNamed('profile'),
                ),
              AppCard(
                onTap: () => context.pushNamed('resumeCreate'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 38,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Профиль готов к новым возможностям',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Выберите важное и соберите резюме, которое расскажет вашу историю.',
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Создать резюме',
                      icon: Icons.arrow_forward,
                      onPressed: () => context.pushNamed('resumeCreate'),
                    ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Ваши достижения'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    children: [
                      for (final kind in [
                        EntryKind.experience,
                        EntryKind.project,
                        EntryKind.skill,
                        EntryKind.education,
                      ])
                        SizedBox(
                          width: width,
                          child: AppCard(
                            onTap: () => context.pushNamed(
                              'profileEntries',
                              pathParameters: {'kind': kind.name},
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ref.watch(entriesProvider(kind)).asData?.value.length ?? 0}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(kind.label),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              SectionCard(
                title: 'Ваш профиль',
                subtitle: user?.email ?? 'Начните с основной информации',
                icon: Icons.person_outline,
                onTap: () => context.goNamed('profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
