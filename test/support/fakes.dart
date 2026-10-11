import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devcv/features/profile/domain/profile_entries.dart';
import 'package:devcv/features/profile/domain/avatar_repository.dart';
import 'package:devcv/features/profile/data/details_mapper.dart';
import 'package:devcv/features/profile/data/entry_mapper.dart';
import 'package:devcv/features/resume/domain/resume_config.dart';
import 'package:devcv/features/resume/domain/resume_document.dart';

import 'package:devcv/core/errors/app_failure.dart';
import 'package:devcv/features/auth/domain/auth_repository.dart';
import 'package:devcv/features/auth/domain/auth_user.dart';
import 'package:devcv/features/profile/domain/developer_profile.dart';
import 'package:devcv/features/profile/domain/profile_repository.dart';

const verifiedUser = AuthUser(
  uid: 'user-1',
  email: 'dev@example.com',
  emailVerified: true,
);
const unverifiedUser = AuthUser(
  uid: 'user-1',
  email: 'dev@example.com',
  emailVerified: false,
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user});
  AuthUser? user;
  final _changes = StreamController<AuthUser?>.broadcast();
  AppFailure? failure;
  Completer<void>? gate;
  int signInCalls = 0;
  int registerCalls = 0;
  int googleCalls = 0;
  int verificationCalls = 0;
  int resetCalls = 0;
  String? receivedEmail;
  bool verificationConfirmed = false;

  void emit(AuthUser? value) {
    user = value;
    _changes.add(value);
  }

  @override
  Stream<AuthUser?> watchUser() async* {
    yield user;
    yield* _changes.stream;
  }

  Future<void> _complete() async {
    await gate?.future;
    final error = failure;
    if (error != null) throw error;
  }

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls++;
    receivedEmail = email;
    await _complete();
    emit(verifiedUser);
  }

  @override
  Future<void> register(String email, String password) async {
    registerCalls++;
    receivedEmail = email;
    await _complete();
    verificationCalls++;
    emit(unverifiedUser);
  }

  @override
  Future<void> signInWithGoogle() async {
    googleCalls++;
    await _complete();
    emit(verifiedUser);
  }

  @override
  Future<void> signOut() async {
    await _complete();
    emit(null);
  }

  @override
  Future<void> resetPassword(String email) async {
    resetCalls++;
    receivedEmail = email;
    await _complete();
  }

  @override
  Future<void> sendVerificationEmail() async {
    verificationCalls++;
    await _complete();
  }

  @override
  Future<void> reloadUser() async {
    await _complete();
    emit(verificationConfirmed ? verifiedUser : unverifiedUser);
  }

  Future<void> dispose() => _changes.close();
}

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<void> updateDetails(String uid, Map<String, Object?> details) async {
    final profile = profiles[uid];
    if (profile == null) {
      throw const AppFailure('Сначала сохраните основную информацию профиля');
    }
    final updated = profile.copyWith(
      aboutMe: details['aboutMe'] as String?,
      contacts: details.containsKey('contacts')
          ? DetailsMapper.readContacts(details['contacts'])
          : null,
      preferences: details.containsKey('preferences')
          ? DetailsMapper.readPreferences(details['preferences'])
          : null,
      avatarPath: details['avatarPath'] as String?,
      avatarUrl: details['avatarUrl'] as String?,
    );
    profiles[uid] = updated;
    _controller(uid).add(updated);
  }

  final profiles = <String, DeveloperProfile?>{};
  final watchedUids = <String>[];
  final _changes = <String, StreamController<DeveloperProfile?>>{};
  AppFailure? failure;
  Completer<void>? loadGate;
  Completer<void>? saveGate;
  int saveCalls = 0;
  DeveloperProfile? lastSaved;

  StreamController<DeveloperProfile?> _controller(String uid) => _changes
      .putIfAbsent(uid, () => StreamController<DeveloperProfile?>.broadcast());

  @override
  Future<DeveloperProfile?> getProfile(String uid) async {
    await loadGate?.future;
    final error = failure;
    if (error != null) throw error;
    return profiles[uid];
  }

  @override
  Stream<DeveloperProfile?> watchProfile(String uid) async* {
    watchedUids.add(uid);
    yield await getProfile(uid);
    yield* _controller(uid).stream;
  }

  @override
  Future<void> saveProfile(DeveloperProfile profile) async {
    saveCalls++;
    await saveGate?.future;
    final error = failure;
    if (error != null) throw error;
    lastSaved = profile;
    profiles[profile.uid] = profile;
    _controller(profile.uid).add(profile);
  }

  Future<void> dispose() async {
    if (loadGate != null && !(loadGate?.isCompleted ?? true)) {
      loadGate?.complete();
    }
    for (final controller in _changes.values) {
      await controller.close();
    }
  }
}

DeveloperProfile sampleProfile({String uid = 'user-1'}) => DeveloperProfile(
  uid: uid,
  email: 'dev@example.com',
  fullName: 'Айдос Разработчик',
  birthDate: DateTime(2000, 1, 15),
  city: 'Алматы',
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 2),
);

class FakeEntryRepository implements EntryRepository {
  final values = <EntryKind, List<ProfileEntry>>{};
  final _changes = <EntryKind, StreamController<List<ProfileEntry>>>{};
  int saved = 0;
  AppFailure? failure;
  @override
  Stream<List<ProfileEntry>> watchEntries(String uid, EntryKind kind) async* {
    final error = failure;
    if (error != null) throw error;
    yield values[kind] ?? [];
    yield* _changes
        .putIfAbsent(
          kind,
          () => StreamController<List<ProfileEntry>>.broadcast(),
        )
        .stream;
  }

  @override
  Future<void> saveEntry(String uid, ProfileEntry entry) async {
    validateEntry(entry);
    final error = failure;
    if (error != null) throw error;
    saved++;
    final stored = EntryMapper.read(
      entry.kind,
      entry.id.isEmpty ? 'entry-$saved' : entry.id,
      {
        ...EntryMapper.write(entry),
        'createdAt': Timestamp.fromDate(DateTime(2024)),
        'updatedAt': Timestamp.fromDate(DateTime(2024)),
      },
    );
    final list = [...values[entry.kind] ?? <ProfileEntry>[]]
      ..removeWhere((e) => e.id == stored.id)
      ..add(stored);
    values[entry.kind] = list;
    _changes[entry.kind]?.add(list);
  }

  @override
  Future<void> deleteEntry(String uid, EntryKind kind, String id) async {
    values[kind] = [...values[kind] ?? <ProfileEntry>[]]
      ..removeWhere((e) => e.id == id);
    _changes[kind]?.add(values[kind]!);
  }

  Future<void> dispose() async {
    for (final c in _changes.values) {
      await c.close();
    }
  }
}

class FakeResumeRepository implements ResumeConfigRepository {
  ResumeConfig? config;
  @override
  Future<ResumeConfig?> load(String uid) async => config;
  @override
  Future<void> save(String uid, ResumeConfig value) async {
    config = value;
  }
}

class FakeAvatarRepository implements AvatarRepository {
  int uploadCalls = 0, loadCalls = 0;
  AppFailure? failure;
  Uint8List? bytes;
  @override
  Future<bool> selectAndUpload(String uid, String? previousPath) async {
    uploadCalls++;
    final error = failure;
    if (error != null) throw error;
    return false;
  }

  @override
  Future<Uint8List?> loadBytes(String uid, String path) async {
    loadCalls++;
    final error = failure;
    if (error != null) throw error;
    return bytes;
  }
}

class FakePdfGenerator implements ResumePdfGenerator {
  ResumeDocument? lastDocument;
  @override
  Future<Uint8List> generate(ResumeDocument document) async {
    lastDocument = document;
    return Uint8List.fromList('%PDF-1.7'.codeUnits);
  }
}

class FakeResumeExporter implements ResumeExporter {
  bool cancel = false;
  int calls = 0;
  @override
  Future<Uri?> save(Uint8List bytes, String fileName) async {
    calls++;
    return cancel ? null : Uri.parse('content://documents/$fileName');
  }
}
