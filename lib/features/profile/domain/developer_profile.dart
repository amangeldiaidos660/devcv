class DeveloperProfile {
  const DeveloperProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.birthDate,
    required this.city,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String fullName;
  final DateTime? birthDate;
  final String city;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
