import 'developer_profile.dart';

abstract interface class ProfileRepository {
  Future<DeveloperProfile?> getProfile(String uid);
  Stream<DeveloperProfile?> watchProfile(String uid);
  Future<void> saveProfile(DeveloperProfile profile);
  Future<void> updateDetails(String uid, Map<String, Object?> details);
}
