import '../domain/profile_details.dart';

abstract final class DetailsMapper {
  static Map<String, Object?> contacts(ProfileContacts value) => {
    'phone': value.phone,
    'githubUrl': value.githubUrl,
    'linkedinUrl': value.linkedinUrl,
    'telegram': value.telegram,
    'website': value.website,
    'visible': value.visible.map((e) => e.name).toList(),
    'preferred': value.preferred.map((e) => e.name).toList(),
  };
  static ProfileContacts readContacts(Object? raw) {
    if (raw is! Map) return const ProfileContacts();
    return ProfileContacts(
      phone: raw['phone'] as String? ?? '',
      githubUrl: raw['githubUrl'] as String? ?? '',
      linkedinUrl: raw['linkedinUrl'] as String? ?? '',
      telegram: raw['telegram'] as String? ?? '',
      website: raw['website'] as String? ?? '',
      visible: ContactType.values
          .where((e) => (raw['visible'] as List? ?? ['email']).contains(e.name))
          .toSet(),
      preferred: ContactType.values
          .where(
            (e) => (raw['preferred'] as List? ?? ['email']).contains(e.name),
          )
          .toSet(),
    );
  }

  static Map<String, Object?> preferences(CareerPreferences value) => {
    'workModes': value.workModes.map((e) => e.name).toList(),
    'employmentTypes': value.employmentTypes.map((e) => e.name).toList(),
    'salaryEnabled': value.salaryEnabled,
    'minimumSalary': value.minimumSalary,
    'currency': value.currency,
    'relocation': value.relocation,
    'businessTrips': value.businessTrips.name,
  };
  static CareerPreferences readPreferences(Object? raw) {
    if (raw is! Map) return const CareerPreferences();
    return CareerPreferences(
      workModes: WorkMode.values
          .where((e) => (raw['workModes'] as List? ?? []).contains(e.name))
          .toSet(),
      employmentTypes: EmploymentType.values
          .where(
            (e) => (raw['employmentTypes'] as List? ?? []).contains(e.name),
          )
          .toSet(),
      salaryEnabled: raw['salaryEnabled'] as bool? ?? false,
      minimumSalary: (raw['minimumSalary'] as num?)?.toInt(),
      currency: raw['currency'] as String? ?? 'KZT',
      relocation: raw['relocation'] as bool? ?? false,
      businessTrips: BusinessTrips.values.firstWhere(
        (e) => e.name == raw['businessTrips'],
        orElse: () => BusinessTrips.notReady,
      ),
    );
  }
}
