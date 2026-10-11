import 'auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> watchUser();
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> sendVerificationEmail();
  Future<void> reloadUser();
}
