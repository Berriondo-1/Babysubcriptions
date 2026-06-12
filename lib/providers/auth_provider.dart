import 'package:baby_subscription/models/app_user.dart';
import 'package:baby_subscription/services/auth_service.dart';
import 'package:flutter/material.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

enum SocialProvider { google, apple, github }

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();
    _currentUser = await AuthService.instance.getLoggedInUser();
    _status = _currentUser != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await AuthService.instance.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      _currentUser = await AuthService.instance.loginWithEmail(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

Future<bool> loginWithSocial(SocialProvider provider) async {
  _setLoading(true);
  try {
    switch (provider) {
      case SocialProvider.google:
        _currentUser = await AuthService.instance.loginWithGoogle();
        break;
      case SocialProvider.github:
        _currentUser = await AuthService.instance.loginWithGitHub(null);
        break;
      case SocialProvider.apple:
        throw const AuthException('Apple Sign-In próximamente disponible.');
    }
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    return true;
  } on AuthException catch (e) {
    _errorMessage = e.message;
    return false;
  } finally {
    _setLoading(false);
  }
}
  Future<void> logout() async {
    await AuthService.instance.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
