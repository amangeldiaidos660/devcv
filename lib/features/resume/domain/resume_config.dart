import '../../profile/domain/profile_entries.dart';

enum ResumeSection {
  basic('Основная информация'),
  photo('Фото'),
  contacts('Контакты'),
  about('О себе'),
  experience('Опыт'),
  education('Образование'),
  projects('Проекты'),
  certificates('Сертификаты'),
  skills('Навыки'),
  languages('Языки'),
  preferences('Предпочтения');

  const ResumeSection(this.label);
  final String label;
  EntryKind? get kind => switch (this) {
    experience => EntryKind.experience,
    education => EntryKind.education,
    projects => EntryKind.project,
    certificates => EntryKind.certificate,
    skills => EntryKind.skill,
    languages => EntryKind.language,
    _ => null,
  };
}

class ResumeConfig {
  const ResumeConfig({
    this.position = '',
    this.includedSections = const {
      ResumeSection.basic,
      ResumeSection.contacts,
      ResumeSection.experience,
      ResumeSection.skills,
    },
    this.selectedIds = const {},
    this.showPhoto = false,
    this.showSalary = false,
    this.updatedAt,
  });
  final String position;
  final Set<ResumeSection> includedSections;
  final Map<EntryKind, Set<String>> selectedIds;
  final bool showPhoto, showSalary;
  final DateTime? updatedAt;
  ResumeConfig copyWith({
    String? position,
    Set<ResumeSection>? includedSections,
    Map<EntryKind, Set<String>>? selectedIds,
    bool? showPhoto,
    bool? showSalary,
  }) => ResumeConfig(
    position: position ?? this.position,
    includedSections: includedSections ?? this.includedSections,
    selectedIds: selectedIds ?? this.selectedIds,
    showPhoto: showPhoto ?? this.showPhoto,
    showSalary: showSalary ?? this.showSalary,
    updatedAt: updatedAt,
  );
  String? validate() => position.trim().isEmpty
      ? 'Укажите позицию'
      : position.trim().length > 120
      ? 'Максимум 120 символов'
      : !includedSections.containsAll({
          ResumeSection.basic,
          ResumeSection.contacts,
        })
      ? 'Основная информация и контакты обязательны'
      : null;
  Map<String, Object?> toMap() => {
    'position': position.trim(),
    'includedSections': includedSections.map((e) => e.name).toList(),
    for (final kind in EntryKind.values)
      'selected${kind.name[0].toUpperCase()}${kind.name.substring(1)}Ids':
          (selectedIds[kind] ?? {}).toList(),
    'showPhoto': showPhoto,
    'showSalary': showSalary,
  };
  static ResumeConfig fromMap(Map<String, dynamic> data) => ResumeConfig(
    position: data['position'] as String? ?? '',
    includedSections: ResumeSection.values
        .where(
          (e) =>
              (data['includedSections'] as List? ??
                      ['basic', 'contacts', 'experience', 'skills'])
                  .contains(e.name),
        )
        .toSet(),
    selectedIds: {
      for (final kind in EntryKind.values)
        kind: Set<String>.from(
          data['selected${kind.name[0].toUpperCase()}${kind.name.substring(1)}Ids']
                  as List? ??
              [],
        ),
    },
    showPhoto: data['showPhoto'] as bool? ?? false,
    showSalary: data['showSalary'] as bool? ?? false,
  );
}

abstract interface class ResumeConfigRepository {
  Future<ResumeConfig?> load(String uid);
  Future<void> save(String uid, ResumeConfig config);
}
