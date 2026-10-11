import 'dart:typed_data';

abstract interface class AvatarRepository {
  Future<bool> selectAndUpload(String uid, String? previousPath);
  Future<Uint8List?> loadBytes(String uid, String path);
}
