import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/avatar_repository.dart';
import '../domain/profile_repository.dart';

class FirebaseAvatarRepository implements AvatarRepository {
  FirebaseAvatarRepository(
    this._storage,
    this._auth,
    this._profiles,
    this._picker,
  );
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final ProfileRepository _profiles;
  final ImagePicker _picker;
  void _authorize(String uid) {
    if (_auth.currentUser?.uid != uid ||
        _auth.currentUser?.emailVerified != true) {
      throw const AppFailure('Войдите в свой аккаунт');
    }
  }

  @override
  Future<bool> selectAndUpload(String uid, String? previousPath) async {
    _authorize(uid);
    XFile? photo;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final lost = await _picker.retrieveLostData();
      if (lost.files?.isNotEmpty == true) photo = lost.files?.first;
    }
    photo ??= await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
      requestFullMetadata: false,
    );
    if (photo == null) return false;
    final bytes = await photo.readAsBytes();
    if (bytes.length >= 5 * 1024 * 1024) {
      throw const AppFailure('Фото должно быть меньше 5 МБ');
    }
    final png = bytes.length > 8 && bytes[0] == 137 && bytes[1] == 80;
    final jpeg = bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216;
    if (!png && !jpeg) {
      throw const AppFailure('Выберите фото в формате JPEG или PNG');
    }
    final path =
        'users/$uid/profile/avatar_${DateTime.now().microsecondsSinceEpoch}.${png ? 'png' : 'jpg'}';
    final reference = _storage.ref(path);
    bool uploaded = false;
    try {
      await reference.putData(
        bytes,
        SettableMetadata(contentType: png ? 'image/png' : 'image/jpeg'),
      );
      uploaded = true;
      final url = await reference.getDownloadURL();
      await _profiles.updateDetails(uid, {
        'avatarUrl': url,
        'avatarPath': path,
      });
    } catch (error) {
      if (uploaded) {
        try {
          await reference.delete();
        } catch (_) {}
      }
      if (error is AppFailure) rethrow;
      throw const AppFailure(
        'Не удалось загрузить фото. Проверьте интернет, bucket и правила Storage',
      );
    }
    if (previousPath != null &&
        previousPath.startsWith('users/$uid/profile/') &&
        previousPath != path) {
      try {
        await _storage.ref(previousPath).delete();
      } catch (_) {}
    }
    return true;
  }

  @override
  Future<Uint8List?> loadBytes(String uid, String path) async {
    _authorize(uid);
    if (!path.startsWith('users/$uid/profile/')) {
      throw const AppFailure('Нет доступа к фото');
    }
    try {
      return await _storage.ref(path).getData(5 * 1024 * 1024);
    } on FirebaseException {
      throw const AppFailure('Не удалось загрузить фото для резюме');
    }
  }
}
