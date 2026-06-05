import 'package:baby_subscription/models/subscription.dart';
import 'package:baby_subscription/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockProvider extends ChangeNotifier {
  int _currentStock = 0;
  int _alertThreshold = 10; // umbral por defecto
  bool _isLoading = false;
  String? _errorMessage;

  int get currentStock => _currentStock;
  int get alertThreshold => _alertThreshold;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isStockLow => _currentStock <= _alertThreshold;

  static const _thresholdKey = 'stock_alert_threshold';

  /// Cargar umbral guardado en preferencias
  Future<void> loadThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    _alertThreshold = prefs.getInt(_thresholdKey) ?? 10;
    notifyListeners();
  }

  /// Guardar umbral configurado por el usuario
  Future<void> setThreshold(int value) async {
    _alertThreshold = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_thresholdKey, value);
    notifyListeners();
    // Revisar si ya hay stock bajo con el nuevo umbral
    await checkStockAlert(babyName: '');
  }

  /// Calcular stock estimado según la suscripción y días transcurridos
  void calculateStock(Subscription sub, DateTime lastDelivery) {
    final daysSince = DateTime.now().difference(lastDelivery).inDays;
    final delivered = sub.quantityPerOrder;
    final usedEstimate = daysSince * (sub.quantityPerOrder /
        (30 / sub.frequency.deliveriesPerMonth));
    _currentStock = (delivered - usedEstimate).round().clamp(0, delivered);
    notifyListeners();
  }

  /// Registrar consumo manual y verificar alerta
  Future<void> registerUsage({
    required int diapersUsed,
    required String babyName,
  }) async {
    _currentStock = (_currentStock - diapersUsed).clamp(0, 99999);
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

  /// Reponer stock después de una entrega
  void replenishStock(int quantity) {
    _currentStock += quantity;
    notifyListeners();
    NotificationService.instance.cancelStockAlert();
  }
}