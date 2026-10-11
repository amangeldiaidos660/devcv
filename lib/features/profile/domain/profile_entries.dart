import '../../../core/errors/app_failure.dart';

enum EntryKind {
  experience('experiences', 'Опыт работы', 'Опыт', 'Опыт пока не добавлен'),
  education(
    'education',
    'Образование',
    'Образование',
    'Образование пока не добавлено',
  ),
  project('projects', 'Проекты', 'Проект', 'Проекты пока не добавлены'),
  certificate(
    'certificates',
    'Сертификаты',
    'Сертификат',
    'Сертификаты пока не добавлены',
  ),
  skill('skills', 'Навыки', 'Навык', 'Навыки пока не добавлены'),
  language('languages', 'Языки', 'Язык', 'Языки пока не добавлены');

  const EntryKind(this.collection, this.label, this.singular, this.emptyLabel);
  final String collection, label, singular, emptyLabel;
}

enum ProjectType {
  work('Рабочий'),
  freelance('Фриланс'),
  personal('Личный');

  const ProjectType(this.label);
  final String label;
}

enum SkillCategory {
  programmingLanguage('Programming Language'),
  framework('Framework / Library'),
  database('Database'),
  devops('DevOps'),
  testing('Testing'),
  tools('Tools'),
  other('Other');

  const SkillCategory(this.label);
  final String label;
}

enum LanguageLevel {
  a1('A1'),
  a2('A2'),
  b1('B1'),
  b2('B2'),
  c1('C1'),
  c2('C2'),
  native('Native');

  const LanguageLevel(this.label);
  final String label;
}

sealed class ProfileEntry {
  const ProfileEntry({required this.id, this.createdAt, this.updatedAt});
  final String id;
  final DateTime? createdAt, updatedAt;
  EntryKind get kind;
  String get title;
  String get subtitle;
  String? validate();
}

String? requiredText(String text, String label, {int max = 200}) {
  if (text.trim().isEmpty) return 'Укажите $label';
  if (text.trim().length > max) return 'Максимум $max символов: $label';
  return null;
}

String? optionalUrl(String text) {
  if (text.trim().isEmpty) return null;
  if (text.trim().length > 2000) return 'Максимум 2000 символов в ссылке';
  final uri = Uri.tryParse(text.trim());
  return uri != null &&
          {'http', 'https'}.contains(uri.scheme) &&
          uri.host.contains('.')
      ? null
      : 'Укажите ссылку https://...';
}

class WorkExperience extends ProfileEntry {
  const WorkExperience({
    required super.id,
    required this.company,
    required this.position,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.responsibilities = '',
    this.achievements = '',
    super.createdAt,
    super.updatedAt,
  });
  final String company, position, responsibilities, achievements;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  @override
  EntryKind get kind => EntryKind.experience;
  @override
  String get title => position;
  @override
  String get subtitle => company;
  int durationMonths({DateTime? now}) {
    final end = isCurrent ? (now ?? DateTime.now()) : endDate ?? startDate;
    final months =
        (end.year - startDate.year) * 12 +
        end.month -
        startDate.month +
        (isCurrent ? 0 : 1);
    return months < 0 ? 0 : months;
  }

  String durationLabel({DateTime? now}) {
    final total = durationMonths(now: now);
    if (total == 0) return 'Меньше месяца';
    String counted(int count, String one, String few, String many) {
      final lastTwo = count % 100, last = count % 10;
      final word = lastTwo >= 11 && lastTwo <= 14
          ? many
          : last == 1
          ? one
          : last >= 2 && last <= 4
          ? few
          : many;
      return '$count $word';
    }

    final years = total ~/ 12, months = total % 12;
    return [
      if (years > 0) counted(years, 'год', 'года', 'лет'),
      if (months > 0) counted(months, 'месяц', 'месяца', 'месяцев'),
    ].join(' ');
  }

  String get periodLabel {
    String month(DateTime date) =>
        '${const ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'][date.month - 1]} ${date.year}';
    return '${month(startDate)} — ${isCurrent
        ? 'настоящее время'
        : endDate == null
        ? ''
        : month(endDate!)}';
  }

  @override
  String? validate() =>
      requiredText(company, 'компанию') ??
      requiredText(position, 'должность') ??
      (startDate.isAfter(DateTime.now())
          ? 'Дата начала не может быть в будущем'
          : null) ??
      (!isCurrent && (endDate == null || endDate!.isBefore(startDate))
          ? 'Укажите дату окончания не раньше начала'
          : null) ??
      (!isCurrent && endDate!.isAfter(DateTime.now())
          ? 'Дата окончания не может быть в будущем'
          : null) ??
      (responsibilities.length > 10000 || achievements.length > 10000
          ? 'Максимум 10000 символов в описании'
          : null);
}

class Education extends ProfileEntry {
  const Education({
    required super.id,
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startYear,
    this.endYear,
    this.isCurrent = false,
    super.createdAt,
    super.updatedAt,
  });
  final String institution, degree, fieldOfStudy;
  final int startYear;
  final int? endYear;
  final bool isCurrent;
  @override
  EntryKind get kind => EntryKind.education;
  @override
  String get title => institution;
  @override
  String get subtitle => '$degree · $fieldOfStudy';
  @override
  String? validate() =>
      requiredText(institution, 'учебное заведение') ??
      requiredText(degree, 'уровень образования') ??
      (fieldOfStudy.length > 200
          ? 'Максимум 200 символов в специальности'
          : null) ??
      (startYear < 1900 || startYear > DateTime.now().year
          ? 'Некорректный год начала'
          : null) ??
      (!isCurrent &&
              (endYear == null ||
                  endYear! < startYear ||
                  endYear! > DateTime.now().year)
          ? 'Проверьте год окончания'
          : null);
}

class Project extends ProfileEntry {
  const Project({
    required super.id,
    required this.name,
    required this.description,
    this.technologies = const [],
    this.projectType = ProjectType.personal,
    this.experienceId,
    this.resourceUrl = '',
    super.createdAt,
    super.updatedAt,
  });
  final String name, description, resourceUrl;
  final List<String> technologies;
  final ProjectType projectType;
  final String? experienceId;
  @override
  EntryKind get kind => EntryKind.project;
  @override
  String get title => name;
  @override
  String get subtitle => technologies.join(' · ');
  @override
  String? validate() =>
      requiredText(name, 'название проекта') ??
      (description.length > 10000 ? 'Максимум 10000 символов' : null) ??
      optionalUrl(resourceUrl) ??
      (projectType == ProjectType.work && (experienceId?.isNotEmpty != true)
          ? 'Выберите место работы'
          : null) ??
      (technologies.length > 100 ? 'Максимум 100 технологий' : null);
}

class Certificate extends ProfileEntry {
  const Certificate({
    required super.id,
    required this.name,
    required this.issuer,
    required this.issueDate,
    this.credentialUrl = '',
    super.createdAt,
    super.updatedAt,
  });
  final String name, issuer, credentialUrl;
  final DateTime issueDate;
  @override
  EntryKind get kind => EntryKind.certificate;
  @override
  String get title => name;
  @override
  String get subtitle => issuer;
  @override
  String? validate() =>
      requiredText(name, 'название сертификата') ??
      requiredText(issuer, 'организацию') ??
      (issueDate.isAfter(DateTime.now())
          ? 'Дата выдачи не может быть в будущем'
          : null) ??
      optionalUrl(credentialUrl);
}

class Skill extends ProfileEntry {
  const Skill({
    required super.id,
    required this.name,
    this.category = SkillCategory.other,
    super.createdAt,
    super.updatedAt,
  });
  final String name;
  final SkillCategory category;
  @override
  EntryKind get kind => EntryKind.skill;
  @override
  String get title => name;
  @override
  String get subtitle => category.label;
  @override
  String? validate() => requiredText(name, 'навык', max: 80);
}

class Language extends ProfileEntry {
  const Language({
    required super.id,
    required this.language,
    this.level = LanguageLevel.b1,
    super.createdAt,
    super.updatedAt,
  });
  final String language;
  final LanguageLevel level;
  @override
  EntryKind get kind => EntryKind.language;
  @override
  String get title => language;
  @override
  String get subtitle => level.label;
  @override
  String? validate() => requiredText(language, 'язык', max: 80);
}

abstract interface class EntryRepository {
  Stream<List<ProfileEntry>> watchEntries(String uid, EntryKind kind);
  Future<void> saveEntry(String uid, ProfileEntry entry);
  Future<void> deleteEntry(String uid, EntryKind kind, String id);
}

void validateEntry(ProfileEntry entry) {
  final error = entry.validate();
  if (error != null) throw AppFailure(error);
}
