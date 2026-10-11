enum ContactType {
  email('Email'),
  phone('Телефон'),
  github('GitHub'),
  linkedin('LinkedIn'),
  telegram('Telegram'),
  website('Сайт');

  const ContactType(this.label);
  final String label;
}

class ProfileContacts {
  const ProfileContacts({
    this.phone = '',
    this.githubUrl = '',
    this.linkedinUrl = '',
    this.telegram = '',
    this.website = '',
    this.visible = const {ContactType.email},
    this.preferred = const {ContactType.email},
  });
  final String phone, githubUrl, linkedinUrl, telegram, website;
  final Set<ContactType> visible, preferred;
  String value(ContactType type, String email) => switch (type) {
    ContactType.email => email,
    ContactType.phone => phone,
    ContactType.github => githubUrl,
    ContactType.linkedin => linkedinUrl,
    ContactType.telegram => telegram,
    ContactType.website => website,
  };
  Map<ContactType, String> selected(String email) => {
    for (final type in ContactType.values)
      if (visible.contains(type) && value(type, email).trim().isNotEmpty)
        type: value(type, email).trim(),
  };
}

enum WorkMode {
  office('Офис'),
  hybrid('Гибрид'),
  remote('Удалённо');

  const WorkMode(this.label);
  final String label;
}

enum EmploymentType {
  fullTime('Полная'),
  partTime('Частичная'),
  project('Проектная'),
  internship('Стажировка');

  const EmploymentType(this.label);
  final String label;
}

enum BusinessTrips {
  ready('Готов'),
  sometimes('Иногда'),
  notReady('Не готов');

  const BusinessTrips(this.label);
  final String label;
}

class CareerPreferences {
  const CareerPreferences({
    this.workModes = const {},
    this.employmentTypes = const {},
    this.salaryEnabled = false,
    this.minimumSalary,
    this.currency = 'KZT',
    this.relocation = false,
    this.businessTrips = BusinessTrips.notReady,
  });
  final Set<WorkMode> workModes;
  final Set<EmploymentType> employmentTypes;
  final bool salaryEnabled, relocation;
  final int? minimumSalary;
  final String currency;
  final BusinessTrips businessTrips;
  bool get isFilled => workModes.isNotEmpty && employmentTypes.isNotEmpty;
}
