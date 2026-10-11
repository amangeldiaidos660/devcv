import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/profile_entries.dart';

abstract final class EntryMapper {
  static ProfileEntry read(
    EntryKind kind,
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime date(String key) => (data[key] as Timestamp).toDate();
    DateTime? optionalDate(String key) => (data[key] as Timestamp?)?.toDate();
    String text(String key) => data[key] as String? ?? '';
    final created = optionalDate('createdAt'),
        updated = optionalDate('updatedAt');
    return switch (kind) {
      EntryKind.experience => WorkExperience(
        id: id,
        company: text('company'),
        position: text('position'),
        startDate: date('startDate'),
        endDate: optionalDate('endDate'),
        isCurrent: data['isCurrent'] as bool? ?? false,
        responsibilities: text('responsibilities'),
        achievements: text('achievements'),
        createdAt: created,
        updatedAt: updated,
      ),
      EntryKind.education => Education(
        id: id,
        institution: text('institution'),
        degree: text('degree'),
        fieldOfStudy: text('fieldOfStudy'),
        startYear: data['startYear'] as int,
        endYear: data['endYear'] as int?,
        isCurrent: data['isCurrent'] as bool? ?? false,
        createdAt: created,
        updatedAt: updated,
      ),
      EntryKind.project => Project(
        id: id,
        name: text('name'),
        description: text('description'),
        technologies: List<String>.from(data['technologies'] as List? ?? []),
        projectType: ProjectType.values.byName(text('projectType')),
        experienceId: data['experienceId'] as String?,
        resourceUrl: text('resourceUrl'),
        createdAt: created,
        updatedAt: updated,
      ),
      EntryKind.certificate => Certificate(
        id: id,
        name: text('name'),
        issuer: text('issuer'),
        issueDate: date('issueDate'),
        credentialUrl: text('credentialUrl'),
        createdAt: created,
        updatedAt: updated,
      ),
      EntryKind.skill => Skill(
        id: id,
        name: text('name'),
        category: SkillCategory.values.byName(text('category')),
        createdAt: created,
        updatedAt: updated,
      ),
      EntryKind.language => Language(
        id: id,
        language: text('language'),
        level: LanguageLevel.values.byName(text('level')),
        createdAt: created,
        updatedAt: updated,
      ),
    };
  }

  static Map<String, Object?> write(ProfileEntry entry) => {
    ...switch (entry) {
      WorkExperience e => {
        'company': e.company.trim(),
        'position': e.position.trim(),
        'startDate': Timestamp.fromDate(e.startDate),
        'endDate': e.isCurrent || e.endDate == null
            ? null
            : Timestamp.fromDate(e.endDate!),
        'isCurrent': e.isCurrent,
        'responsibilities': e.responsibilities.trim(),
        'achievements': e.achievements.trim(),
      },
      Education e => {
        'institution': e.institution.trim(),
        'degree': e.degree.trim(),
        'fieldOfStudy': e.fieldOfStudy.trim(),
        'startYear': e.startYear,
        'endYear': e.isCurrent ? null : e.endYear,
        'isCurrent': e.isCurrent,
      },
      Project e => {
        'name': e.name.trim(),
        'description': e.description.trim(),
        'technologies': e.technologies,
        'projectType': e.projectType.name,
        'experienceId': e.projectType == ProjectType.work
            ? e.experienceId
            : null,
        'resourceUrl': e.resourceUrl.trim(),
      },
      Certificate e => {
        'name': e.name.trim(),
        'issuer': e.issuer.trim(),
        'issueDate': Timestamp.fromDate(e.issueDate),
        'credentialUrl': e.credentialUrl.trim(),
      },
      Skill e => {'name': e.name.trim(), 'category': e.category.name},
      Language e => {'language': e.language.trim(), 'level': e.level.name},
    },
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
