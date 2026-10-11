import 'package:devcv/features/profile/domain/profile_entries.dart';
import 'package:devcv/features/profile/domain/profile_details.dart';
import 'package:devcv/features/profile/domain/details_validation.dart';
import 'package:devcv/features/profile/domain/profile_completion.dart';
import 'package:devcv/features/profile/data/details_mapper.dart';
import 'package:devcv/features/resume/domain/resume_config.dart';
import 'package:devcv/features/resume/domain/resume_document.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Work duration handles completed, current and invalid periods', () {
    final completed = WorkExperience(
      id: 'e',
      company: 'A',
      position: 'Backend',
      startDate: DateTime(2023, 8),
      endDate: DateTime(2024, 1),
    );
    expect(completed.durationMonths(), 6);
    expect(completed.durationLabel(), '6 месяцев');
    expect(completed.periodLabel, 'Август 2023 — Январь 2024');
    final current = WorkExperience(
      id: 'e',
      company: 'A',
      position: 'Backend',
      startDate: DateTime(2024, 5),
      isCurrent: true,
    );
    expect(current.durationMonths(now: DateTime(2025, 10)), 17);
    expect(current.durationLabel(now: DateTime(2025, 10)), '1 год 5 месяцев');
    expect(
      WorkExperience(
        id: 'e',
        company: '',
        position: '',
        startDate: DateTime(2024),
      ).validate(),
      isNotNull,
    );
    expect(
      WorkExperience(
        id: 'e',
        company: 'A',
        position: 'Backend',
        startDate: DateTime(2024),
        endDate: DateTime(2023),
      ).validate(),
      isNotNull,
    );
  });
  test(
    'Salary, about and work project validation enforce domain constraints',
    () {
      expect(DetailsValidation.salary(true, null), isNotNull);
      expect(DetailsValidation.salary(true, -1), isNotNull);
      expect(DetailsValidation.salary(true, 500000), isNull);
      expect(DetailsValidation.salary(false, null), isNull);
      expect(DetailsValidation.about('а' * 500), isNull);
      expect(DetailsValidation.about('а' * 501), isNotNull);
      expect(
        const Project(
          id: 'p',
          name: 'DevCV',
          description: '',
          projectType: ProjectType.work,
        ).validate(),
        contains('место работы'),
      );
      expect(
        const Project(
          id: 'p',
          name: 'DevCV',
          description: '',
          projectType: ProjectType.work,
          experienceId: 'e',
        ).validate(),
        isNull,
      );
    },
  );
  test(
    'Contacts round trip, visibility and two preferred contacts are enforced',
    () {
      const contacts = ProfileContacts(
        phone: '+7 777 123 45 67',
        githubUrl: 'https://github.com/aidos',
        visible: {ContactType.phone},
        preferred: {ContactType.phone},
      );
      final restored = DetailsMapper.readContacts(
        DetailsMapper.contacts(contacts),
      );
      expect(restored.phone, contacts.phone);
      expect(restored.selected('dev@example.com'), {
        ContactType.phone: contacts.phone,
      });
      expect(DetailsValidation.contacts(contacts, 'dev@example.com'), isNull);
      expect(
        DetailsValidation.contacts(
          const ProfileContacts(
            preferred: {
              ContactType.email,
              ContactType.phone,
              ContactType.telegram,
            },
          ),
          'dev@example.com',
        ),
        isNotNull,
      );
    },
  );
  test('Weighted completion reaches 100 without certificates or photo', () {
    final profile = sampleProfile().copyWith(
      aboutMe: 'Backend developer',
      preferences: const CareerPreferences(
        workModes: {WorkMode.remote},
        employmentTypes: {EmploymentType.fullTime},
      ),
    );
    expect(
      ProfileCompletion.calculate(
        profile: profile,
        email: profile.email,
        emailVerified: true,
        counts: {for (final e in EntryKind.values) e: 1},
      ),
      100,
    );
    expect(
      ProfileCompletion.calculate(
        profile: sampleProfile(),
        email: 'dev@example.com',
        emailVerified: true,
        counts: const {},
      ),
      30,
    );
  });
  test('Resume config retains item choices and uses latest profile data', () {
    final config = ResumeConfig(
      position: 'Backend Developer',
      includedSections: {
        ResumeSection.basic,
        ResumeSection.contacts,
        ResumeSection.experience,
      },
      selectedIds: {
        EntryKind.experience: {'e1'},
      },
    );
    final restored = ResumeConfig.fromMap(config.toMap());
    expect(restored.position, config.position);
    expect(restored.selectedIds[EntryKind.experience], {'e1'});
    final document = ResumeDocument(
      profile: sampleProfile(),
      config: restored,
      entries: {
        EntryKind.experience: [
          WorkExperience(
            id: 'e1',
            company: 'A',
            position: 'Middle',
            startDate: DateTime(2024),
            isCurrent: true,
          ),
          WorkExperience(
            id: 'e2',
            company: 'B',
            position: 'QA',
            startDate: DateTime(2023),
            isCurrent: true,
          ),
        ],
      },
    );
    expect(document.selected(EntryKind.experience).single.title, 'Middle');
    expect(document.validate(), isNull);
    expect(
      ResumeDocument(
        profile: sampleProfile().copyWith(
          contacts: const ProfileContacts(visible: {}),
        ),
        config: config,
        entries: const {},
      ).validate(),
      isNotNull,
    );
    final file = ResumeDocument(
      profile: sampleProfile().copyWith(fullName: 'Имя / Фамилия'),
      config: config.copyWith(position: 'Backend: <Dev>'),
      entries: const {},
    ).fileName;
    expect(file, endsWith('.pdf'));
    expect(file, isNot(contains('/')));
    expect(file, isNot(contains(':')));
  });
}
