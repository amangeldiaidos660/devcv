import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/storage/local_cache_service.dart';
import '../domain/resume_config.dart';

class FirestoreResumeRepository implements ResumeConfigRepository {
  FirestoreResumeRepository(this._firestore, this._auth, this._cache);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalCacheService _cache;
  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('resumeConfigs')
      .doc('default');
  void _authorize(String uid) {
    if (_auth.currentUser?.uid != uid ||
        _auth.currentUser?.emailVerified != true) {
      throw const AppFailure('Войдите в свой аккаунт');
    }
  }

  @override
  Future<ResumeConfig?> load(String uid) async {
    _authorize(uid);
    try {
      final snapshot = await _doc(uid).get();
      final data = snapshot.data();
      if (!snapshot.metadata.isFromCache) {
        try {
          if (data == null) {
            await _cache.remove('resume:$uid');
          } else {
            await _cache.write('resume:$uid', {...data}..remove('updatedAt'));
          }
        } catch (_) {}
      }
      return data == null ? null : ResumeConfig.fromMap(data);
    } on FirebaseException catch (error) {
      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
        final cached = _cache.read<Object>('resume:$uid');
        if (cached is Map) {
          return ResumeConfig.fromMap(Map<String, dynamic>.from(cached));
        }
      }
      throw const AppFailure('Не удалось загрузить последние настройки резюме');
    }
  }

  @override
  Future<void> save(String uid, ResumeConfig config) async {
    _authorize(uid);
    final error = config.validate();
    if (error != null) throw AppFailure(error);
    try {
      await _doc(uid)
          .set({...config.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
      try {
        await _cache.write('resume:$uid', config.toMap());
      } catch (_) {}
    } on FirebaseException {
      throw const AppFailure(
        'Не удалось сохранить настройки резюме. Проверьте интернет и Firestore Rules',
      );
    }
  }
}
