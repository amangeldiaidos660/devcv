import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_error_mapper.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._google);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleInitialization;

  @override
  Stream<AuthUser?> watchUser() => _auth.userChanges().transform(
    StreamTransformer<User?, AuthUser?>.fromHandlers(
      handleData: (user, sink) => sink.add(
        user == null
            ? null
            : AuthUser(
                uid: user.uid,
                email: user.email,
                emailVerified: user.emailVerified,
              ),
      ),
      handleError: (error, stack, sink) => sink.addError(
        error is FirebaseAuthException
            ? authFailure(error.code)
            : const AppFailure('Не удалось проверить авторизацию'),
        stack,
      ),
    ),
  );

  Future<void> _execute(Future<void> Function() operation) async {
    try {
      await operation();
    } on FirebaseAuthException catch (error) {
      throw authFailure(error.code);
    }
  }

  @override
  Future<void> signIn(String email, String password) => _execute(() async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  });

  @override
  Future<void> register(String email, String password) => _execute(() async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _auth.currentUser?.sendEmailVerification();
  });

  Future<void> _initializeGoogle() async {
    const clientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    if (defaultTargetPlatform == TargetPlatform.iOS && clientId.isEmpty) {
      throw authFailure('google-configuration');
    }
    try {
      await (_googleInitialization ??= _google.initialize(
        clientId: clientId.isEmpty ? null : clientId,
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      ));
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle() => _execute(() async {
    try {
      await _initializeGoogle();
      final account = await _google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) throw authFailure('google-configuration');
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return;
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw authFailure('google-configuration');
      }
      throw authFailure('google-unavailable');
    }
  });

  @override
  Future<void> signOut() => _execute(() async {
    await _auth.signOut();
    if (_googleInitialization != null) {
      try {
        await _google.signOut();
      } on GoogleSignInException {
        _googleInitialization = null;
      }
    }
  });

  @override
  Future<void> resetPassword(String email) =>
      _execute(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> sendVerificationEmail() => _execute(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AppFailure('Войдите в аккаунт');
    await user.sendEmailVerification();
  });

  @override
  Future<void> reloadUser() => _execute(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AppFailure('Войдите в аккаунт');
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
  });
}
