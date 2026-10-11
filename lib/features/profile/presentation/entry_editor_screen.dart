import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/form_page.dart';
import '../../../core/widgets/error_message.dart';
import '../domain/profile_entries.dart';
import 'entry_providers.dart';

class EntryEditorScreen extends ConsumerStatefulWidget {
  const EntryEditorScreen({super.key, required this.kind, this.entry});
  final EntryKind kind;
  final ProfileEntry? entry;
  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorState();
}

class _EntryEditorState extends ConsumerState<EntryEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  final _dates = <String, DateTime?>{};
  bool _current = false, _dirty = false;
  ProjectType _projectType = ProjectType.personal;
  String? _experienceId;
  SkillCategory _category = SkillCategory.other;
  LanguageLevel _level = LanguageLevel.b1;
  @override
  void initState() {
    super.initState();
    final data = <String, String>{};
    switch (widget.entry) {
      case WorkExperience e:
        data.addAll({
          'company': e.company,
          'position': e.position,
          'responsibilities': e.responsibilities,
          'achievements': e.achievements,
        });
        _dates.addAll({'startDate': e.startDate, 'endDate': e.endDate});
        _current = e.isCurrent;
      case Education e:
        data.addAll({
          'institution': e.institution,
          'degree': e.degree,
          'fieldOfStudy': e.fieldOfStudy,
          'startYear': '${e.startYear}',
          'endYear': e.endYear?.toString() ?? '',
        });
        _current = e.isCurrent;
      case Project e:
        data.addAll({
          'name': e.name,
          'description': e.description,
          'technologies': e.technologies.join(', '),
          'resourceUrl': e.resourceUrl,
        });
        _projectType = e.projectType;
        _experienceId = e.experienceId;
      case Certificate e:
        data.addAll({
          'name': e.name,
          'issuer': e.issuer,
          'credentialUrl': e.credentialUrl,
        });
        _dates['issueDate'] = e.issueDate;
      case Skill e:
        data['name'] = e.name;
        _category = e.category;
      case Language e:
        data['language'] = e.language;
        _level = e.level;
      case null:
        break;
    }
    for (final key in [
      'company',
      'position',
      'responsibilities',
      'achievements',
      'institution',
      'degree',
      'fieldOfStudy',
      'startYear',
      'endYear',
      'name',
      'description',
      'technologies',
      'resourceUrl',
      'issuer',
      'credentialUrl',
      'language',
    ]) {
      _fields[key] = TextEditingController(text: data[key] ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String value(String key) => _fields[key]?.text.trim() ?? '';
  Widget text(
    String key,
    String label, {
    bool required = false,
    int lines = 1,
    String? helper,
    bool year = false,
    String? Function(String?)? validator,
  }) => AppTextField(
    controller: _fields[key]!,
    label: label,
    enabled: !ref.watch(entryActionsProvider).isLoading,
    maxLines: lines,
    helper: helper,
    keyboardType: year ? TextInputType.number : null,
    onChanged: (_) => setState(() => _dirty = true),
    validator:
        validator ?? (v) => required ? requiredText(v ?? '', label) : null,
  );
  Widget date(String key, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: ValueKey('$key:${_dates[key]}'),
      initialValue: _dates[key] == null
          ? ''
          : '${_dates[key]!.day}.${_dates[key]!.month}.${_dates[key]!.year}',
      readOnly: true,
      enabled: !ref.watch(entryActionsProvider).isLoading,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      validator: (_) => _dates[key] == null
          ? switch (key) {
              'startDate' => 'Укажите дату начала',
              'endDate' => 'Укажите дату окончания',
              _ => 'Укажите дату выдачи',
            }
          : null,
      onTap: () async {
        final today = DateUtils.dateOnly(DateTime.now());
        final selected = await showDatePicker(
          context: context,
          initialDate: _dates[key] ?? today,
          firstDate: DateTime(1900),
          lastDate: today,
        );
        if (selected != null && mounted) {
          setState(() {
            _dates[key] = selected;
            _dirty = true;
          });
        }
      },
    ),
  );
  DateTime requiredDate(String key) =>
      _dates[key] ?? (throw const AppFailure('Укажите дату'));
  ProfileEntry buildEntry() {
    final id = widget.entry?.id ?? '';
    return switch (widget.kind) {
      EntryKind.experience => WorkExperience(
        id: id,
        company: value('company'),
        position: value('position'),
        startDate: requiredDate('startDate'),
        endDate: _current ? null : requiredDate('endDate'),
        isCurrent: _current,
        responsibilities: value('responsibilities'),
        achievements: value('achievements'),
      ),
      EntryKind.education => Education(
        id: id,
        institution: value('institution'),
        degree: value('degree'),
        fieldOfStudy: value('fieldOfStudy'),
        startYear: int.tryParse(value('startYear')) ?? 0,
        endYear: _current ? null : int.tryParse(value('endYear')),
        isCurrent: _current,
      ),
      EntryKind.project => Project(
        id: id,
        name: value('name'),
        description: value('description'),
        projectType: _projectType,
        experienceId: _projectType == ProjectType.work ? _experienceId : null,
        technologies: value('technologies')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList(),
        resourceUrl: value('resourceUrl'),
      ),
      EntryKind.certificate => Certificate(
        id: id,
        name: value('name'),
        issuer: value('issuer'),
        issueDate: requiredDate('issueDate'),
        credentialUrl: value('credentialUrl'),
      ),
      EntryKind.skill => Skill(
        id: id,
        name: value('name'),
        category: _category,
      ),
      EntryKind.language => Language(
        id: id,
        language: value('language'),
        level: _level,
      ),
    };
  }

  Future<void> save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final saved = await ref
        .read(entryActionsProvider.notifier)
        .save(buildEntry());
    if (saved && mounted) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Запись сохранена')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(entryActionsProvider),
        experiences = ref.watch(entriesProvider(EntryKind.experience));
    final fields = <Widget>[];
    switch (widget.kind) {
      case EntryKind.experience:
        fields.addAll([
          text('company', 'Компания', required: true),
          text('position', 'Должность', required: true),
          date('startDate', 'Дата начала'),
          SwitchListTile(
            title: const Text('Работаю сейчас'),
            value: _current,
            onChanged: action.isLoading
                ? null
                : (v) => setState(() {
                    _current = v;
                    _dirty = true;
                  }),
          ),
          if (!_current) date('endDate', 'Дата окончания'),
          text(
            'responsibilities',
            'Обязанности',
            lines: 5,
            helper: 'Опишите, чем вы занимались на этой позиции.',
          ),
          text(
            'achievements',
            'Достижения',
            lines: 5,
            helper: 'Добавьте конкретные результаты или достижения.',
          ),
        ]);
      case EntryKind.education:
        fields.addAll([
          text('institution', 'Учебное заведение', required: true),
          text(
            'degree',
            'Уровень образования',
            required: true,
            helper: 'Например: бакалавриат, магистратура, другое',
          ),
          text('fieldOfStudy', 'Специальность'),
          text('startYear', 'Год начала', required: true, year: true),
          SwitchListTile(
            title: const Text('Учусь сейчас'),
            value: _current,
            onChanged: action.isLoading
                ? null
                : (v) => setState(() {
                    _current = v;
                    _dirty = true;
                  }),
          ),
          if (!_current)
            text('endYear', 'Год окончания', required: true, year: true),
        ]);
      case EntryKind.project:
        fields.addAll([
          text('name', 'Название проекта', required: true),
          text('description', 'Описание', lines: 5),
          AppDropdown(
            label: 'Тип проекта',
            value: _projectType,
            items: {for (final e in ProjectType.values) e: e.label},
            enabled: !action.isLoading,
            onChanged: (v) => setState(() {
              _projectType = v ?? ProjectType.personal;
              _dirty = true;
            }),
          ),
          if (_projectType == ProjectType.work)
            experiences.when(
              loading: () => const LoadingState(),
              error: (e, s) => ErrorMessage(
                error: e,
                onRetry: () =>
                    ref.invalidate(entriesProvider(EntryKind.experience)),
              ),
              data: (items) => AppDropdown<String>(
                label: 'Место работы',
                value: items.any((e) => e.id == _experienceId)
                    ? _experienceId
                    : null,
                items: {
                  for (final e in items) e.id: '${e.subtitle} — ${e.title}',
                },
                enabled: !action.isLoading,
                validator: (v) => v == null ? 'Выберите место работы' : null,
                onChanged: (v) => setState(() {
                  _experienceId = v;
                  _dirty = true;
                }),
              ),
            ),
          text(
            'technologies',
            'Технологии',
            helper: 'Введите теги через запятую',
          ),
          text(
            'resourceUrl',
            'Ссылка на проект',
            validator: (v) => optionalUrl(v ?? ''),
          ),
        ]);
      case EntryKind.certificate:
        fields.addAll([
          text('name', 'Название сертификата', required: true),
          text('issuer', 'Организация', required: true),
          date('issueDate', 'Дата выдачи'),
          text(
            'credentialUrl',
            'Ссылка на сертификат',
            validator: (v) => optionalUrl(v ?? ''),
          ),
        ]);
      case EntryKind.skill:
        fields.addAll([
          text('name', 'Название навыка', required: true),
          AppDropdown(
            label: 'Категория',
            value: _category,
            items: {for (final e in SkillCategory.values) e: e.label},
            enabled: !action.isLoading,
            onChanged: (v) => setState(() {
              _category = v ?? SkillCategory.other;
              _dirty = true;
            }),
          ),
        ]);
      case EntryKind.language:
        fields.addAll([
          text('language', 'Язык', required: true),
          AppDropdown(
            label: 'Уровень',
            value: _level,
            items: {for (final e in LanguageLevel.values) e: e.label},
            enabled: !action.isLoading,
            onChanged: (v) => setState(() {
              _level = v ?? LanguageLevel.b1;
              _dirty = true;
            }),
          ),
        ]);
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
        title:
            '${widget.entry == null ? 'Добавить' : 'Изменить'} ${widget.kind.singular.toLowerCase()}',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...fields,
              if (action.hasError) ErrorMessage(error: action.error!),
              const SizedBox(height: 16),
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
