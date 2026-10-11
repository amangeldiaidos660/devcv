import 'profile_details.dart';

class DeveloperProfile {
  const DeveloperProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.birthDate,
    required this.city,
    this.createdAt,
    this.updatedAt,
    this.contacts = const ProfileContacts(),
    this.preferences = const CareerPreferences(),
    this.aboutMe = '',
    this.avatarUrl,
    this.avatarPath,
  });

  final String uid;
  final String email;
  final String fullName;
  final DateTime? birthDate;
  final String city;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ProfileContacts contacts;
  final CareerPreferences preferences;
  final String aboutMe;
  final String? avatarUrl, avatarPath;

  DeveloperProfile copyWith({
    String? fullName,
    DateTime? birthDate,
    String? city,
    ProfileContacts? contacts,
    CareerPreferences? preferences,
    String? aboutMe,
    String? avatarUrl,
    String? avatarPath,
  }) => DeveloperProfile(
    uid: uid,
    email: email,
    fullName: fullName ?? this.fullName,
    birthDate: birthDate ?? this.birthDate,
    city: city ?? this.city,
    contacts: contacts ?? this.contacts,
    preferences: preferences ?? this.preferences,
    aboutMe: aboutMe ?? this.aboutMe,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    avatarPath: avatarPath ?? this.avatarPath,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
