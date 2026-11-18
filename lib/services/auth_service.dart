
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn google = GoogleSignIn.instance;

  // GOOGLE SIGN IN
  Future<User?> signInWithGoogle() async {
    await google.initialize();

    final googleUser = await google.authenticate();
    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final result = await auth.signInWithCredential(credential);
    return result.user;
  }

  // REGISTER WITH EMAIL
  Future<User?> registerWithEmail(
    String email,
    String password,
  ) async {
    final result = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await result.user?.sendEmailVerification();
    await auth.signOut();

    return result.user;
  }

  // EMAIL LOGIN
  Future<User?> signInWithEmail(
    String email,
    String password,
  ) async {
    final result = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await result.user?.reload();
    final user = auth.currentUser;

    if (user != null && !user.emailVerified) {
      await auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Please verify your email before logging in.',
      );
    }

    return user;
  }

  // FORGOT PASSWORD
  Future<void> resetPassword(String email) async {
    await auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // LOGOUT
  Future<void> logout() async {
    await auth.signOut();

    try {
      await google.signOut();
    } catch (_) {
      // No active Google session.
    }
  }

  Stream<User?> get userStream => auth.authStateChanges();
}
