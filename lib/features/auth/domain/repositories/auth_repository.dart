import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<AppUser> signInWithEmailAndPassword(String email, String password);
  Future<void> updatePassword(String newPassword);
  Future<void> signOut();
}
