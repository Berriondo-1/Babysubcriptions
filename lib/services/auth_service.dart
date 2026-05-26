import 'dart:convert';
import 'package:baby_subscription/models/app_user.dart';
import 'package:baby_subscription/services/database_service.dart';
import 'package:crypto/crypto.dart';
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

  static const String _sessionKey = 'logged_in_user_id';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final existing = await DatabaseService.instance.getUserByEmail(email.trim().toLowerCase());
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
    return created;
  }

  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await DatabaseService.instance.getUserByEmail(email.trim().toLowerCase());
    if (user == null || user.provider != AppAuthProvider.email) {
      throw const AuthException('Correo o contraseña incorrectos.');
    }
    if (user.passwordHash != _hashPassword(password)) {
      throw const AuthException('Correo o contraseña incorrectos.');
    }
    await _persistSession(user.id!);
    return user;
  }

  Future<AppUser> loginWithSocialProvider({
    required AppAuthProvider provider,
    required String email,
    String? displayName,
  }) async {
    var user = await DatabaseService.instance.getUserByEmail(email.trim().toLowerCase());
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
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<AppUser?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_sessionKey);
    if (userId == null) return null;
    final db = await DatabaseService.instance.database;
    final users = await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (users.isEmpty) return null;
    return AppUser.fromMap(users.first);
  }

  Future<void> _persistSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, userId);
  }
}
