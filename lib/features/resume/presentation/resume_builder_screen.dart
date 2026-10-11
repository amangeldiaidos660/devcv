import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/config/app_features.dart';
import '../../../core/widgets/error_message.dart';
import '../../../core/widgets/form_page.dart';
import '../domain/resume_config.dart';
import '../../profile/domain/profile_entries.dart';
import 'resume_providers.dart';

class ResumeBuilderScreen extends ConsumerStatefulWidget {
  const ResumeBuilderScreen({super.key, this.initialConfig});
  final ResumeConfig? initialConfig;
  @override
  ConsumerState<ResumeBuilderScreen> createState() => _ResumeBuilderState();
}

class _ResumeBuilderState extends ConsumerState<ResumeBuilderScreen> {
  final _form = GlobalKey<FormState>();
  final _position = TextEditingController();
  ResumeConfig _config = const ResumeConfig();
  int _step = 0;
  bool _initialized = false;
  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void initialize(ResumeProfileData data) {
    if (_initialized) return;
    _initialized = true;
    _config =
        widget.initialConfig ??
        ResumeConfig(
          selectedIds: {
            for (final kind in EntryKind.values)
              kind: (data.entries[kind] ?? []).map((e) => e.id).toSet(),
          },
        );
    _position.text = _config.position;
  }

  Future<void> next(ResumeProfileData data) async {
    if (_step == 0 && !(_form.currentState?.validate() ?? false)) return;
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    final config = _config.copyWith(position: _position.text.trim());
    if (data.profile.fullName.trim().isEmpty ||
        data.profile.contacts.selected(data.profile.email).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для PDF нужны ФИО и хотя бы один видимый контакт'),
        ),
      );
      return;
    }
    if (await ref.read(resumeActionsProvider.notifier).saveConfig(config) &&
        mounted) {
      ref.read(resumeDraftProvider.notifier).setConfig(config);
      context.pushNamed('resumePreview');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(resumeProfileDataProvider),
        action = ref.watch(resumeActionsProvider);
    final photosEnabled = ref.watch(profilePhotosEnabledProvider);
    return data.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Создать резюме')),
        body: const LoadingState(),
      ),
      error: (error, stack) => FormPage(
        title: 'Создать резюме',
        child: Column(
          children: [
            ErrorMessage(
              error: error,
              onRetry: () => ref.invalidate(resumeProfileDataProvider),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Заполнить профиль',
              onPressed: () => context.pushNamed('profileBasic'),
            ),
          ],
        ),
      ),
      data: (profileData) {
        initialize(profileData);
        if (!photosEnabled) {
          _config = _config.copyWith(
            showPhoto: false,
            includedSections: {..._config.includedSections}
              ..remove(ResumeSection.photo),
          );
        }
        final widgets = <Widget>[];
        switch (_step) {
          case 0:
            widgets.addAll([
              const SectionHeader(
                title: 'На какую позицию?',
                subtitle: 'Один профиль — резюме под вашу следующую роль.',
              ),
              AppTextField(
                controller: _position,
                label: 'Позиция',
                enabled: !action.isLoading,
                validator: (v) => ResumeConfig(position: v ?? '').validate(),
              ),
              ResumeSectionTile(
                title: 'Показывать зарплату',
                subtitle: profileData.profile.preferences.salaryEnabled
                    ? 'Из карьерных предпочтений'
                    : 'Сначала укажите зарплату в предпочтениях',
                selected: _config.showSalary,
                onChanged:
                    profileData.profile.preferences.salaryEnabled &&
                        !action.isLoading
                    ? (v) => setState(
                        () => _config = _config.copyWith(showSalary: v),
                      )
                    : null,
              ),
            ]);
          case 1:
            widgets.add(
              const SectionHeader(
                title: 'Что включить?',
                subtitle: 'Пустые разделы не появятся в PDF.',
              ),
            );
            for (final section in ResumeSection.values) {
              final required = {
                ResumeSection.basic,
                ResumeSection.contacts,
              }.contains(section);
              final available =
                  section != ResumeSection.photo ||
                  (photosEnabled && profileData.profile.avatarPath != null);
              widgets.add(
                ResumeSectionTile(
                  title: section.label,
                  selected: _config.includedSections.contains(section),
                  subtitle: required
                      ? 'Обязательный раздел'
                      : section == ResumeSection.photo && !photosEnabled
                      ? AppFeatures.photoUnavailableMessage
                      : !available
                      ? 'Фото ещё не добавлено'
                      : null,
                  onChanged: required || !available || action.isLoading
                      ? null
                      : (v) => setState(() {
                          final sections = {..._config.includedSections};
                          v ? sections.add(section) : sections.remove(section);
                          _config = _config.copyWith(
                            includedSections: sections,
                            showPhoto: sections.contains(ResumeSection.photo),
                          );
                        }),
                ),
              );
            }
          default:
            widgets.add(
              const SectionHeader(
                title: 'Выберите записи',
                subtitle: 'Включите только то, что важно для этой позиции.',
              ),
            );
            final kinds = _config.includedSections
                .map((e) => e.kind)
                .whereType<EntryKind>();
            if (kinds.isEmpty) {
              widgets.add(
                const Text(
                  'Списковые разделы не выбраны. Можно открыть Preview.',
                ),
              );
            }
            for (final kind in kinds) {
              final entries = profileData.entries[kind] ?? [];
              widgets.add(SectionHeader(title: kind.label));
              if (entries.isEmpty) widgets.add(Text(kind.emptyLabel));
              for (final entry in entries) {
                widgets.add(
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: CheckboxListTile(
                      title: Text(entry.title),
                      subtitle: Text(entry.subtitle),
                      value:
                          _config.selectedIds[kind]?.contains(entry.id) ??
                          false,
                      onChanged: action.isLoading
                          ? null
                          : (v) => setState(() {
                              final ids = {...?_config.selectedIds[kind]};
                              v == true
                                  ? ids.add(entry.id)
                                  : ids.remove(entry.id);
                              _config = _config.copyWith(
                                selectedIds: {
                                  ..._config.selectedIds,
                                  kind: ids,
                                },
                              );
                            }),
                    ),
                  ),
                );
              }
            }
        }
        return FormPage(
          title: 'Создать резюме',
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ШАГ ${_step + 1} ИЗ 4',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_step + 1) / 4,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(8),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    key: ValueKey(_step),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widgets,
                  ),
                ),
                if (action.hasError) ErrorMessage(error: action.error!),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _step == 2 ? 'Открыть Preview' : 'Продолжить',
                  busy: action.isLoading,
                  onPressed: () => next(profileData),
                ),
                if (_step > 0)
                  SecondaryButton(
                    label: 'Назад',
                    onPressed: action.isLoading
                        ? null
                        : () => setState(() => _step--),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
