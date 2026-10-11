import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/error_message.dart';
import 'resume_providers.dart';

class ResumeScreen extends ConsumerWidget {
  const ResumeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastResumeConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Резюме')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SectionHeader(
                title: 'Ваша история. Ваш следующий шаг.',
                subtitle: 'Соберите резюме под конкретную позицию из актуальных данных профиля.',
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Один чистый шаблон A4. Только выбранные разделы, контакты и записи.',
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Создать резюме',
                      onPressed: () => context.pushNamed('resumeCreate'),
                    ),
                  ],
                ),
              ),
              last.when(
                loading: () => const LoadingState(),
                error: (error, stack) => ErrorMessage(
                  error: error,
                  onRetry: () => ref.invalidate(lastResumeConfigProvider),
                ),
                data: (config) => config == null
                    ? const SizedBox.shrink()
                    : AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              config.position,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            SecondaryButton(
                              label: 'Продолжить с последними настройками',
                              onPressed: () => context.pushNamed(
                                'resumeCreate',
                                extra: config,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
