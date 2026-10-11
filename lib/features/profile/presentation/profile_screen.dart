import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/config/app_features.dart';
import '../../../core/widgets/error_message.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/profile_entries.dart';
import 'profile_providers.dart';
import 'profile_summary_provider.dart';
import 'details_providers.dart';
import 'entry_providers.dart';
import 'profile_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).asData?.value;
    final profile = ref.watch(currentProfileProvider);
    final completion = ref.watch(profileCompletionProvider);
    final action = ref.watch(detailsActionsProvider);
    final photosEnabled = ref.watch(profilePhotosEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ваш профиль')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: profile.when(
            loading: () => const LoadingState(),
            error: (error, stack) => Center(
              child: ErrorMessage(
                error: error,
                onRetry: () => ref.invalidate(currentProfileProvider),
              ),
            ),
            data: (data) => ListView(
              padding: const EdgeInsets.all(22),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      ProfileAvatar(
                        name: data?.fullName ?? '',
                        url: data?.avatarUrl,
                        radius: 48,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        data?.fullName.isNotEmpty == true
                            ? data!.fullName
                            : 'Добавьте имя',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(user?.email ?? ''),
                      if (data?.city.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(data!.city),
                        ),
                      TextButton.icon(
                        onPressed: !photosEnabled || action.isLoading
                            ? null
                            : () async {
                                if (data == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Сначала сохраните основную информацию профиля',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await ref
                                    .read(detailsActionsProvider.notifier)
                                    .avatar(data.avatarPath);
                              },
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          !photosEnabled
                              ? 'Фото недоступно'
                              : action.isLoading
                              ? 'Загрузка фото…'
                              : 'Изменить фото',
                        ),
                      ),
                      if (!photosEnabled)
                        const Text(
                          AppFeatures.photoUnavailableMessage,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
                if (action.hasError) ErrorMessage(error: action.error!),
                ProfileCompletionCard(percent: completion),
                if (data == null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Профиль ещё не создан. Начните с основной информации.',
                    ),
                  ),
                SectionCard(
                  title: 'Основная информация',
                  subtitle: data == null
                      ? 'Заполните ФИО, дату рождения и город'
                      : '${data.fullName} · ${data.city}',
                  icon: Icons.person_outline,
                  onTap: () => context.pushNamed('profileBasic'),
                ),
                SectionCard(
                  title: 'Контакты',
                  subtitle:
                      '${data?.contacts.selected(user?.email ?? '').length ?? 1} для резюме',
                  icon: Icons.contact_mail_outlined,
                  onTap: () => context.pushNamed(
                    'profileDetails',
                    pathParameters: {'section': 'contacts'},
                  ),
                ),
                for (final kind in EntryKind.values)
                  SectionCard(
                    title: kind.label,
                    subtitle: ref
                        .watch(entriesProvider(kind))
                        .when(
                          data: (items) => '${items.length} записей',
                          loading: () => 'Загрузка…',
                          error: (e, s) => 'Не удалось загрузить',
                        ),
                    icon: switch (kind) {
                      EntryKind.experience => Icons.work_outline,
                      EntryKind.education => Icons.school_outlined,
                      EntryKind.project => Icons.code,
                      EntryKind.certificate => Icons.workspace_premium_outlined,
                      EntryKind.skill => Icons.bolt,
                      EntryKind.language => Icons.language,
                    },
                    onTap: () => context.pushNamed(
                      'profileEntries',
                      pathParameters: {'kind': kind.name},
                    ),
                  ),
                SectionCard(
                  title: 'Предпочтения',
                  subtitle: data?.preferences.isFilled == true
                      ? 'Формат работы и занятость выбраны'
                      : 'Укажите условия работы',
                  icon: Icons.tune,
                  onTap: () => context.pushNamed(
                    'profileDetails',
                    pathParameters: {'section': 'preferences'},
                  ),
                ),
                SectionCard(
                  title: 'О себе',
                  subtitle: data?.aboutMe.isNotEmpty == true
                      ? '${data!.aboutMe.runes.length} / 500 символов'
                      : 'Расскажите о специализации',
                  icon: Icons.notes,
                  onTap: () => context.pushNamed(
                    'profileDetails',
                    pathParameters: {'section': 'about'},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
