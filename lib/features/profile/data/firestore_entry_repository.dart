import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/profile_entries.dart';
import 'entry_mapper.dart';

class FirestoreEntryRepository implements EntryRepository {
  FirestoreEntryRepository(this._firestore, this._auth);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    EntryKind kind,
  ) => _firestore.collection('users').doc(uid).collection(kind.collection);
  void _authorize(String uid) {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid || !user.emailVerified) {
      throw const AppFailure('Войдите в свой аккаунт');
    }
  }

  AppFailure _failure(FirebaseException error) =>
      AppFailure(switch (error.code) {
        'permission-denied' => 'Нет доступа. Проверьте правила Firestore',
        'unavailable' => 'Проверьте подключение к интернету',
        _ => 'Не удалось сохранить или загрузить раздел. Попробуйте ещё раз',
      }, code: error.code);
  @override
  Stream<List<ProfileEntry>> watchEntries(String uid, EntryKind kind) async* {
    _authorize(uid);
    try {
      await for (final snapshot in _collection(
        uid,
        kind,
      ).orderBy('createdAt', descending: true).snapshots()) {
        yield snapshot.docs
            .map((doc) => EntryMapper.read(kind, doc.id, doc.data()))
            .toList();
      }
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> saveEntry(String uid, ProfileEntry entry) async {
    _authorize(uid);
    validateEntry(entry);
    try {
      final collection = _collection(uid, entry.kind);
      final document = entry.id.isEmpty
          ? collection.doc()
          : collection.doc(entry.id);
      await _firestore.runTransaction((transaction) async {
        final previous = await transaction.get(document);
        if (entry case Project(
          projectType: ProjectType.work,
          :final experienceId,
        )) {
          final experience = await transaction.get(
            _collection(uid, EntryKind.experience).doc(experienceId),
          );
          if (!experience.exists) {
            throw const AppFailure(
              'Выбранное место работы больше не существует',
            );
          }
        }
        transaction.set(document, {
          ...EntryMapper.write(entry),
          if (!previous.exists) 'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<void> deleteEntry(String uid, EntryKind kind, String id) async {
    _authorize(uid);
    try {
      if (kind == EntryKind.experience) {
        final linked = await _collection(
          uid,
          EntryKind.project,
        ).where('experienceId', isEqualTo: id).limit(1).get();
        if (linked.docs.isNotEmpty) {
          throw const AppFailure(
            'Сначала измените или удалите проекты, связанные с этим местом работы',
          );
        }
      }
      await _collection(uid, kind).doc(id).delete();
    } on FirebaseException catch (error) {
      throw _failure(error);
    }
  }
}
