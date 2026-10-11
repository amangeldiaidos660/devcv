import 'dart:typed_data';

import '../domain/avatar_repository.dart';

class DisabledAvatarRepository implements AvatarRepository {
  const DisabledAvatarRepository();

  @override
  Future<bool> selectAndUpload(String uid, String? previousPath) async => false;

  @override
  Future<Uint8List?> loadBytes(String uid, String path) async => null;
}
