import 'package:baby_subscription/models/subscription.dart';
import 'package:baby_subscription/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockProvider extends ChangeNotifier {
  int _currentStock = 0;
  int _alertThreshold = 10;
  bool _isLoading = false;
  String? _errorMessage;

  int get currentStock => _currentStock;
  int get alertThreshold => _alertThreshold;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isStockLow => _currentStock <= _alertThreshold && _currentStock >= 0;

  static const _thresholdKey = 'stock_alert_threshold';
  // Clave con babyProfileId para tener stock separado por bebé
  static String _stockKey(int babyProfileId) => 'stock_current_$babyProfileId';

  /// Cargar stock y umbral guardados para un bebé específico
  Future<void> loadStock(int babyProfileId) async {
    final prefs = await SharedPreferences.getInstance();
    _alertThreshold = prefs.getInt(_thresholdKey) ?? 10;
    _currentStock = prefs.getInt(_stockKey(babyProfileId)) ?? 0;
    notifyListeners();
  }

  /// Inicializar stock con la cantidad de una suscripción (solo si es 0)
  Future<void> initStockFromSubscription(
      Subscription sub, int babyProfileId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_stockKey(babyProfileId));
    // Solo inicializa si nunca se ha guardado un stock para este bebé
    if (saved == null) {
      _currentStock = sub.quantityPerOrder;
      await prefs.setInt(_stockKey(babyProfileId), _currentStock);
      notifyListeners();
    }
  }

  /// Guardar umbral configurado por el usuario
  Future<void> setThreshold(int value) async {
    _alertThreshold = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_thresholdKey, value);
    notifyListeners();
    await checkStockAlert(babyName: '');
  }

  /// Registrar consumo manual y descontar del stock
  Future<void> registerUsage({
    required int diapersUsed,
    required String babyName,
    required int babyProfileId,
  }) async {
    _currentStock = (_currentStock - diapersUsed).clamp(0, 99999);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stockKey(babyProfileId), _currentStock);
    notifyListeners();
    await checkStockAlert(babyName: babyName);
  }

  /// Revisar si se debe disparar la notificación
  Future<void> checkStockAlert({required String babyName}) async {
    if (isStockLow && babyName.isNotEmpty) {
      await NotificationService.instance.showStockAlert(
        babyName: babyName,
        remainingDiapers: _currentStock,
      );
    } else {
      await NotificationService.instance.cancelStockAlert();
    }
  }

  /// Reponer stock después de una nueva suscripción/entrega
  Future<void> replenishStock(int quantity, int babyProfileId) async {
    _currentStock += quantity;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stockKey(babyProfileId), _currentStock);
    notifyListeners();
    NotificationService.instance.cancelStockAlert();
  }

  /// Reiniciar stock (cuando se cancela suscripción)
  Future<void> resetStock(int babyProfileId) async {
    _currentStock = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stockKey(babyProfileId));
    notifyListeners();
  }
}