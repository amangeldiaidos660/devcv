import 'developer_profile.dart';
import 'profile_entries.dart';

abstract final class ProfileCompletion {
  static int calculate({
    required DeveloperProfile? profile,
    required String? email,
    required bool emailVerified,
    DateTime? now,
    Map<EntryKind, int>? counts,
  }) {
    final today = now ?? DateTime.now();
    final birthDate = profile?.birthDate;
    final fields = [
      (profile?.fullName.trim().length ?? 0) >= 2,
      birthDate != null &&
          !birthDate.isAfter(DateTime(today.year, today.month, today.day)),
      (profile?.city.trim().length ?? 0) >= 2,
      emailVerified && (email?.trim().isNotEmpty ?? false),
    ];
    if (counts == null) {
      return (fields.where((filled) => filled).length * 100 / fields.length)
          .round();
    }
    final basic = (fields.take(3).where((filled) => filled).length * 20 / 3)
        .round();
    return basic +
        (fields.last ? 10 : 0) +
        ((counts[EntryKind.experience] ?? 0) > 0 ? 20 : 0) +
        ((counts[EntryKind.education] ?? 0) > 0 ? 10 : 0) +
        ((counts[EntryKind.skill] ?? 0) > 0 ? 15 : 0) +
        ((counts[EntryKind.project] ?? 0) > 0 ? 10 : 0) +
        ((counts[EntryKind.language] ?? 0) > 0 ? 5 : 0) +
        (profile?.preferences.isFilled == true ? 5 : 0) +
        (profile?.aboutMe.trim().isNotEmpty == true ? 5 : 0);
  }
}
