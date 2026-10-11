import 'dart:io';

import 'package:devcv/features/resume/data/resume_pdf_service.dart';
import 'package:devcv/features/resume/domain/resume_document.dart';
import 'package:devcv/features/resume/domain/resume_config.dart';
import 'package:devcv/features/profile/domain/profile_entries.dart';
import 'package:devcv/features/profile/domain/profile_details.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'PDF generates A4 bytes with Cyrillic, selected records and multiple pages',
    () async {
      final entries = <EntryKind, List<ProfileEntry>>{
        EntryKind.experience: [
          WorkExperience(
            id: 'e1',
            company: 'DevCV Studio',
            position: 'Backend Developer',
            startDate: DateTime(2024, 5),
            isCurrent: true,
            responsibilities: List.filled(
              35,
              'Разрабатывал API, оптимизировал базу данных и поддерживал сервисы.',
            ).join(' '),
            achievements: 'Сократил время ответа API на 35%.',
          ),
          WorkExperience(
            id: 'hidden',
            company: 'HIDDEN COMPANY',
            position: 'HIDDEN POSITION',
            startDate: DateTime(2023),
            isCurrent: true,
          ),
        ],
        EntryKind.project: [
          const Project(
            id: 'p',
            name: 'DevCV',
            description:
                'Приложение для профиля разработчика и генерации резюме.',
            technologies: ['Flutter', 'Firebase'],
            resourceUrl: 'https://github.com/aidos/devcv',
          ),
        ],
        EntryKind.skill: [
          const Skill(
            id: 's1',
            name: 'Dart',
            category: SkillCategory.programmingLanguage,
          ),
          const Skill(
            id: 's2',
            name: 'Flutter',
            category: SkillCategory.framework,
          ),
        ],
        EntryKind.education: [
          const Education(
            id: 'ed',
            institution: 'Казахстанский университет',
            degree: 'Бакалавриат',
            fieldOfStudy: 'Информатика',
            startYear: 2018,
            endYear: 2022,
          ),
        ],
        EntryKind.certificate: [
          Certificate(
            id: 'c',
            name: 'Cloud Developer',
            issuer: 'Учебный центр',
            issueDate: DateTime(2024),
          ),
        ],
        EntryKind.language: [
          const Language(
            id: 'l',
            language: 'Қазақша',
            level: LanguageLevel.native,
          ),
        ],
      };
      final config = ResumeConfig(
        position: 'Python Backend Developer',
        includedSections: {
          for (final section in ResumeSection.values)
            if (section != ResumeSection.photo) section,
        },
        selectedIds: {
          for (final pair in entries.entries)
            pair.key: pair.value
                .where((e) => e.id != 'hidden')
                .map((e) => e.id)
                .toSet(),
        },
        showSalary: true,
      );
      final profile = sampleProfile().copyWith(
        fullName: 'Айдос Аман',
        aboutMe:
            'Backend-разработчик. Создаю надёжные API и понятные приложения.',
        contacts: const ProfileContacts(
          githubUrl: 'https://github.com/aidos',
          visible: {ContactType.email, ContactType.github},
        ),
        preferences: const CareerPreferences(
          workModes: {WorkMode.remote},
          employmentTypes: {EmploymentType.fullTime},
          salaryEnabled: true,
          minimumSalary: 500000,
        ),
      );
      final service = ResumePdfService(
        loadFont: (path) async =>
            ByteData.sublistView(await File(path).readAsBytes()),
      );
      final bytes = await service.generate(
        ResumeDocument(profile: profile, config: config, entries: entries),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(15000));
      final withoutPhoto = await service.generate(
        ResumeDocument(
          profile: profile,
          config: config.copyWith(
            showPhoto: true,
            includedSections: {...config.includedSections, ResumeSection.photo},
          ),
          entries: entries,
        ),
      );
      expect(String.fromCharCodes(withoutPhoto.take(5)), '%PDF-');
      expect(withoutPhoto.length, greaterThan(15000));
      if (const bool.fromEnvironment('WRITE_PDF_SAMPLE')) {
        await Directory('output/pdf').create(recursive: true);
        await File('output/pdf/DevCV-sample.pdf').writeAsBytes(bytes);
      }
    },
  );
}
