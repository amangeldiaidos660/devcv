import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/error_message.dart';
import '../domain/details_validation.dart';
import '../domain/developer_profile.dart';
import '../domain/profile_details.dart';
import '../domain/profile_entries.dart';
import 'profile_providers.dart';
import 'details_providers.dart';

class DetailsEditorScreen extends ConsumerStatefulWidget {
  const DetailsEditorScreen({super.key, required this.section});
  final String section;
  @override
  ConsumerState<DetailsEditorScreen> createState() => _DetailsEditorState();
}

class _DetailsEditorState extends ConsumerState<DetailsEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = <ContactType, TextEditingController>{};
  final _salary = TextEditingController(), _about = TextEditingController();
  Set<ContactType> _visible = {}, _preferred = {};
  Set<WorkMode> _modes = {};
  Set<EmploymentType> _employment = {};
  bool _salaryEnabled = false,
      _relocation = false,
      _initialized = false,
      _dirty = false;
  BusinessTrips _trips = BusinessTrips.notReady;
  String _currency = 'KZT';
  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _salary.dispose();
    _about.dispose();
    super.dispose();
  }

  void initialize(DeveloperProfile? profile, String email) {
    if (_initialized) return;
    _initialized = true;
    final contacts = profile?.contacts ?? const ProfileContacts();
    for (final type in ContactType.values) {
      _fields[type] = TextEditingController(text: contacts.value(type, email));
    }
    _visible = {...contacts.visible};
    _preferred = {...contacts.preferred};
    final pref = profile?.preferences ?? const CareerPreferences();
    _modes = {...pref.workModes};
    _employment = {...pref.employmentTypes};
    _salaryEnabled = pref.salaryEnabled;
    _salary.text = pref.minimumSalary?.toString() ?? '';
    _currency = pref.currency;
    _trips = pref.businessTrips;
    _relocation = pref.relocation;
    _about.text = profile?.aboutMe ?? '';
  }

  Future<void> save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final actions = ref.read(detailsActionsProvider.notifier);
    final success = switch (widget.section) {
      'contacts' => await actions.contacts(
        ProfileContacts(
          phone: _fields[ContactType.phone]!.text.trim(),
          githubUrl: _fields[ContactType.github]!.text.trim(),
          linkedinUrl: _fields[ContactType.linkedin]!.text.trim(),
          telegram: _fields[ContactType.telegram]!.text.trim(),
          website: _fields[ContactType.website]!.text.trim(),
          visible: _visible,
          preferred: _preferred,
        ),
      ),
      'preferences' => await actions.preferences(
        CareerPreferences(
          workModes: _modes,
          employmentTypes: _employment,
          salaryEnabled: _salaryEnabled,
          minimumSalary: _salaryEnabled
              ? int.tryParse(_salary.text.replaceAll(' ', ''))
              : null,
          currency: _currency,
          relocation: _relocation,
          businessTrips: _trips,
        ),
      ),
      _ => await actions.about(_about.text),
    };
    if (success && mounted) {
      _dirty = false;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Раздел сохранён')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final action = ref.watch(detailsActionsProvider);
    final email = ref.watch(authEmailProvider);
    if (profile.isLoading) return const Scaffold(body: LoadingState());
    if (profile.hasError) {
      return Scaffold(
        body: ErrorMessage(
          error: profile.error!,
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
      );
    }
    initialize(profile.asData?.value, email);
    final widgets = <Widget>[];
    switch (widget.section) {
      case 'contacts':
        widgets.add(
          const Text(
            'Выберите до двух предпочтительных контактов. Email подтверждён через аккаунт.',
          ),
        );
        for (final type in ContactType.values) {
          widgets.add(
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    controller: _fields[type]!,
                    label: type.label,
                    enabled: type != ContactType.email && !action.isLoading,
                    keyboardType: type == ContactType.phone
                        ? TextInputType.phone
                        : null,
                    onChanged: (_) => setState(() => _dirty = true),
                    validator: (v) =>
                        {
                          ContactType.github,
                          ContactType.linkedin,
                          ContactType.website,
                        }.contains(type)
                        ? optionalUrl(v ?? '')
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Показывать в резюме'),
                    value: _visible.contains(type),
                    onChanged: action.isLoading
                        ? null
                        : (v) => setState(() {
                            _dirty = true;
                            v ? _visible.add(type) : _visible.remove(type);
                          }),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Предпочтительный контакт'),
                    value: _preferred.contains(type),
                    onChanged: action.isLoading
                        ? null
                        : (v) {
                            if (v == true && _preferred.length >= 2) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Можно выбрать максимум 2 контакта',
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _dirty = true;
                              v == true
                                  ? _preferred.add(type)
                                  : _preferred.remove(type);
                            });
                          },
                  ),
                ],
              ),
            ),
          );
        }
      case 'preferences':
        widgets.addAll([
          const SectionHeader(title: 'Формат работы'),
          Wrap(
            spacing: 8,
            children: [
              for (final e in WorkMode.values)
                AppChip(
                  label: e.label,
                  selected: _modes.contains(e),
                  onSelected: action.isLoading
                      ? null
                      : (v) => setState(() {
                          _dirty = true;
                          v ? _modes.add(e) : _modes.remove(e);
                        }),
                ),
            ],
          ),
          const SectionHeader(title: 'Занятость'),
          Wrap(
            spacing: 8,
            children: [
              for (final e in EmploymentType.values)
                AppChip(
                  label: e.label,
                  selected: _employment.contains(e),
                  onSelected: action.isLoading
                      ? null
                      : (v) => setState(() {
                          _dirty = true;
                          v ? _employment.add(e) : _employment.remove(e);
                        }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Указать ожидаемую зарплату'),
            value: _salaryEnabled,
            onChanged: action.isLoading
                ? null
                : (v) => setState(() {
                    _salaryEnabled = v;
                    _dirty = true;
                  }),
          ),
          if (_salaryEnabled) ...[
            AppTextField(
              controller: _salary,
              label: 'Ожидаемая зарплата на руки',
              keyboardType: TextInputType.number,
              enabled: !action.isLoading,
              onChanged: (_) => setState(() => _dirty = true),
              validator: (v) => DetailsValidation.salary(
                true,
                int.tryParse((v ?? '').replaceAll(' ', '')),
              ),
            ),
            AppDropdown(
              label: 'Валюта',
              value: _currency,
              items: const {
                'KZT': 'KZT · ₸',
                'USD': 'USD',
                'EUR': 'EUR · €',
                'RUB': 'RUB · ₽',
              },
              enabled: !action.isLoading,
              onChanged: (v) => setState(() {
                _currency = v ?? 'KZT';
                _dirty = true;
              }),
            ),
          ],
          SwitchListTile(
            title: const Text('Готов к переезду'),
            value: _relocation,
            onChanged: action.isLoading
                ? null
                : (v) => setState(() {
                    _relocation = v;
                    _dirty = true;
                  }),
          ),
          AppDropdown(
            label: 'Командировки',
            value: _trips,
            items: {for (final e in BusinessTrips.values) e: e.label},
            enabled: !action.isLoading,
            onChanged: (v) => setState(() {
              _trips = v ?? BusinessTrips.notReady;
              _dirty = true;
            }),
          ),
        ]);
      default:
        widgets.add(
          AppTextField(
            controller: _about,
            label: 'О себе',
            maxLines: 8,
            maxLength: 500,
            enabled: !action.isLoading,
            onChanged: (_) => setState(() => _dirty = true),
            validator: (v) => DetailsValidation.about(v ?? ''),
            helper: 'Кратко расскажите о своем опыте, специализации и сильных сторонах.',
          ),
        );
    }
    return PopScope(
      canPop: !_dirty && !action.isLoading,
      onPopInvokedWithResult: (popped, result) async {
        if (popped || action.isLoading) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Изменения не сохранены'),
            content: const Text('Вернуться без сохранения?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Остаться'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Вернуться'),
              ),
            ],
          ),
        );
        if (leave == true && mounted) {
          setState(() => _dirty = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
        }
      },
      child: FormPage(
        title: switch (widget.section) {
          'contacts' => 'Контакты',
          'preferences' => 'Предпочтения',
          _ => 'О себе',
        },
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...widgets,
              if (action.hasError) ErrorMessage(error: action.error!),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Сохранить',
                busy: action.isLoading,
                onPressed: save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
