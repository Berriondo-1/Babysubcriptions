import 'dart:convert';
import 'package:baby_subscription/models/app_user.dart';
import 'package:baby_subscription/services/database_service.dart';
import 'package:baby_subscription/services/firestore_service.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const String _sessionKey = 'logged_in_user_id';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ─── Email/Contraseña ─────────────────────────────────────────────────────

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final existing = await DatabaseService.instance.getUserByEmail(
      email.trim().toLowerCase(),
    );
    if (existing != null) {
      throw const AuthException('Ya existe una cuenta con este correo.');
    }
    final user = AppUser(
      email: email.trim().toLowerCase(),
      displayName: displayName?.trim(),
      provider: AppAuthProvider.email,
      passwordHash: _hashPassword(password),
      createdAt: DateTime.now(),
    );
    final created = await DatabaseService.instance.createUser(user);
    await _persistSession(created.id!);

    // Sincronizar con Firestore
    await FirestoreService.instance.saveUser(
      email: created.email,
      displayName: created.displayName,
      provider: 'email',
    );

    return created;
  }

  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await DatabaseService.instance.getUserByEmail(
      email.trim().toLowerCase(),
    );
    if (user == null || user.provider != AppAuthProvider.email) {
      throw const AuthException('Correo o contraseña incorrectos.');
    }
    if (user.passwordHash != _hashPassword(password)) {
      throw const AuthException('Correo o contraseña incorrectos.');
    }
    await _persistSession(user.id!);
    return user;
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────────

  Future<AppUser> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Inicio de sesión cancelado.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = result.user!;

      return await _upsertSocialUser(
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName,
        provider: AppAuthProvider.google,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  // ─── GitHub Sign-In ────────────────────────────────────────────────────────

  Future<AppUser> loginWithGitHub(context) async {
    try {
      final provider = GithubAuthProvider();
      final result = await _firebaseAuth.signInWithProvider(provider);
      final firebaseUser = result.user!;

      return await _upsertSocialUser(
        email: firebaseUser.email ?? '${firebaseUser.uid}@github.com',
        displayName: firebaseUser.displayName,
        provider: AppAuthProvider.github,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<AppUser> _upsertSocialUser({
    required String email,
    required String? displayName,
    required AppAuthProvider provider,
  }) async {
    var user = await DatabaseService.instance.getUserByEmail(
      email.trim().toLowerCase(),
    );
    if (user == null) {
      user = AppUser(
        email: email.trim().toLowerCase(),
        displayName: displayName,
        provider: provider,
        createdAt: DateTime.now(),
      );
      user = await DatabaseService.instance.createUser(user);
    }
    await _persistSession(user.id!);

    // Sincronizar con Firestore
    await FirestoreService.instance.saveUser(
      email: user.email,
      displayName: user.displayName,
      provider: provider.name,
    );

    return user;
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo usando otro método.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Intenta de nuevo.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'cancelled-popup-request':
      case 'popup-closed-by-user':
        return 'Inicio de sesión cancelado.';
      default:
        return 'Error de autenticación. Intenta de nuevo.';
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<AppUser?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_sessionKey);
    if (userId == null) return null;
    final db = await DatabaseService.instance.database;
    final users = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (users.isEmpty) return null;
    return AppUser.fromMap(users.first);
  }

  Future<void> _persistSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, userId);
  }
}