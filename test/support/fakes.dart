import 'dart:async';

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
