import 'developer_profile.dart';

abstract final class ProfileCompletion {
  static int calculate({
    required DeveloperProfile? profile,
    required String? email,
    required bool emailVerified,
    DateTime? now,
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
    return (fields.where((filled) => filled).length * 100 / fields.length)
        .round();
  }
}
