import 'package:baby_subscription/models/subscription.dart';
import 'package:baby_subscription/services/database_service.dart';
import 'package:flutter/material.dart';

class SubscriptionProvider extends ChangeNotifier {
  Subscription? _current;
  bool _isLoading = false;
  String? _errorMessage;

  Subscription? get current => _current;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveSubscription => _current != null && _current!.isActive;

  Future<void> loadSubscription(int userId, int babyProfileId) async {
    _setLoading(true);
    try {
      _current = await DatabaseService.instance
          .getActiveSubscription(userId, babyProfileId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error cargando suscripción: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveSubscription(Subscription sub) async {
    _setLoading(true);
    try {
      _current = await DatabaseService.instance.saveSubscription(sub);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error guardando suscripción: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelSubscription() async {
    if (_current?.id == null) return false;
    _setLoading(true);
    try {
      await DatabaseService.instance.cancelSubscription(_current!.id!);
      _current = _current!.copyWith(isActive: false);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error cancelando suscripción: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clear() {
    _current = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}