import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/utils/validators.dart';
import '../domain/developer_profile.dart';
import '../domain/profile_repository.dart';
import 'profile_mapper.dart';

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._firestore, this._auth, this._cache);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalCacheService _cache;

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _firestore.collection('users').doc(uid);

  AppFailure _failure(FirebaseException error) =>
      AppFailure(switch (error.code) {
        'permission-denied' => 'Нет доступа к профилю. Проверьте подтверждение email и правила Firestore',
        'unavailable' ||
        'deadline-exceeded' => 'Проверьте подключение к интернету',
        'unauthenticated' => 'Войдите в аккаунт повторно',
        _ => 'Не удалось загрузить или сохранить профиль. Попробуйте ещё раз',
      }, code: error.code);

  bool _temporary(FirebaseException error) =>
      error.code == 'unavailable' || error.code == 'deadline-exceeded';

  DeveloperProfile? _cached(String uid) {
    try {
      final value = _cache.read<Object>('profile:$uid');
      return value is Map
          ? ProfileMapper.fromCache(uid, Map<Object?, Object?>.from(value))
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<DeveloperProfile?> _readSnapshot(
    String uid,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final data = snapshot.data();
    final profile = data == null
        ? null
        : ProfileMapper.fromFirestore(uid, data);
    if (!snapshot.metadata.isFromCache && !snapshot.metadata.hasPendingWrites) {
      try {
        if (profile == null) {
          await _cache.remove('profile:$uid');
        } else {
          await _cache.write('profile:$uid', ProfileMapper.toCache(profile));
        }
      } catch (_) {
        return profile;
      }
    }
    return profile;
  }

  @override
  Future<DeveloperProfile?> getProfile(String uid) async {
    try {
      return await _readSnapshot(uid, await _document(uid).get());
    } on FirebaseException catch (error) {
      final cached = _temporary(error) ? _cached(uid) : null;
      if (cached != null) return cached;
      throw _failure(error);
    }
  }

  @override
  Stream<DeveloperProfile?> watchProfile(String uid) async* {
    try {
      await for (final snapshot in _document(
        uid,
      ).snapshots(includeMetadataChanges: true)) {
        yield await _readSnapshot(uid, snapshot);
      }
    } on FirebaseException catch (error) {
      final cached = _temporary(error) ? _cached(uid) : null;
      if (cached != null) {
        yield cached;
      } else {
        throw _failure(error);
      }
    }
  }

  @override
  Future<void> saveProfile(DeveloperProfile profile) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != profile.uid || !user.emailVerified) {
      throw const AppFailure('Войдите в аккаунт с подтверждённым email');
    }
    final email = user.email;
    if (email == null) throw const AppFailure('В аккаунте отсутствует email');
    final message =
        Validators.fullName(profile.fullName) ??
        Validators.city(profile.city) ??
        Validators.birthDate(profile.birthDate);
    if (message != null) throw AppFailure(message);
    final sanitized = profile.copyWith(
      fullName: profile.fullName.trim(),
      city: profile.city.trim(),
    );
    try {
      await _firestore.runTransaction((transaction) async {
        final reference = _document(user.uid);
        final existing = await transaction.get(reference);
        final data = ProfileMapper.toFirestore(
          sanitized,
          isNew: !existing.exists,
        );
        data['email'] = email;
        if (existing.exists) {
          for (final key in [
            'contacts',
            'preferences',
            'aboutMe',
            'avatarUrl',
            'avatarPath',
          ]) {
            data.remove(key);
          }
        }
        transaction.set(reference, data, SetOptions(merge: true));
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> updateDetails(String uid, Map<String, Object?> details) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid || !user.emailVerified) {
      throw const AppFailure('Войдите в свой аккаунт');
    }
    const allowed = {
      'contacts',
      'preferences',
      'aboutMe',
      'avatarUrl',
      'avatarPath',
    };
    if (details.keys.any((key) => !allowed.contains(key))) {
      throw const AppFailure('Некорректные поля профиля');
    }
    try {
      await _document(uid)
          .update({...details, 'updatedAt': FieldValue.serverTimestamp()});
    } on FirebaseException catch (error) {
      if (error.code == 'not-found') {
        throw const AppFailure('Сначала сохраните основную информацию профиля');
      }
      throw _failure(error);
    }
  }
}
