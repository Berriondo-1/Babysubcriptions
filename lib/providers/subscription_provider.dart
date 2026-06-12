import 'package:baby_subscription/models/subscription.dart';
import 'package:baby_subscription/providers/stock_provider.dart';
import 'package:baby_subscription/services/database_service.dart';
import 'package:baby_subscription/services/firestore_service.dart';
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

  Future<bool> saveSubscription(
    Subscription sub,
    StockProvider stockProvider, // ← nuevo parámetro
  ) async {
    _setLoading(true);
    try {
      final isNew = sub.id == null; // es nueva si no tiene id
      _current = await DatabaseService.instance.saveSubscription(sub);
      await FirestoreService.instance.saveSubscription(_current!);

      // Si es una suscripción nueva, inicializar el stock
      if (isNew) {
        await stockProvider.replenishStock(
          _current!.quantityPerOrder,
          _current!.babyProfileId,
        );
      }

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error guardando suscripción: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelSubscription(StockProvider stockProvider) async {
    if (_current?.id == null) return false;
    _setLoading(true);
    try {
      await DatabaseService.instance.cancelSubscription(_current!.id!);
      await FirestoreService.instance.cancelSubscription(_current!.babyProfileId);

      // Resetear el stock al cancelar
      await stockProvider.resetStock(_current!.babyProfileId);

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