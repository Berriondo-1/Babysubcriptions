import 'package:baby_subscription/models/diaper_consumption.dart';
import 'package:baby_subscription/services/database_service.dart';
import 'package:flutter/material.dart';

class ConsumptionProvider extends ChangeNotifier {
  List<DiaperConsumption> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DiaperConsumption> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Averages ───────────────────────────────────────────────────────────────

  /// Average diapers per day over the last 7 days (0.0 if no data).
  double get weeklyAverage {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = _history.where((e) => e.date.isAfter(cutoff)).toList();
    if (recent.isEmpty) return 0;
    final total = recent.fold<int>(0, (s, e) => s + e.diaperCount);
    return total / 7;
  }

  /// Average diapers per day over the last 30 days (0.0 if no data).
  double get monthlyAverage {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = _history.where((e) => e.date.isAfter(cutoff)).toList();
    if (recent.isEmpty) return 0;
    final total = recent.fold<int>(0, (s, e) => s + e.diaperCount);
    return total / 30;
  }

  /// Suggested monthly quantity based on monthly average (rounds up, min 30).
  int get suggestedMonthlyQuantity {
    final avg = monthlyAverage;
    if (avg == 0) return 0;
    final suggested = (avg * 30).ceil();
    return suggested < 30 ? 30 : suggested;
  }

  // ── Last 30 days for chart ─────────────────────────────────────────────────

  /// Returns one entry per day for the last [days] days.
  /// Days with no log show 0.
  List<MapEntry<DateTime, int>> getDailyTotals({int days = 30}) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days - 1 - i));
      final count = _history
          .where(
            (e) =>
                e.date.year == day.year &&
                e.date.month == day.month &&
                e.date.day == day.day,
          )
          .fold<int>(0, (s, e) => s + e.diaperCount);
      return MapEntry(day, count);
    });
  }

  // ── Entry for today ────────────────────────────────────────────────────────

  DiaperConsumption? get todayEntry {
    final today = DateTime.now();
    try {
      return _history.firstWhere(
        (e) =>
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day,
      );
    } catch (_) {
      return null;
    }
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> loadHistory(int babyProfileId) async {
    _setLoading(true);
    try {
      _history = await DatabaseService.instance.getConsumptionHistory(
        babyProfileId,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar el historial: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> logToday(int babyProfileId, int count) async {
    _setLoading(true);
    try {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final existing = todayEntry;
      final entry = DiaperConsumption(
        id: existing?.id,
        babyProfileId: babyProfileId,
        date: today,
        diaperCount: count,
      );
      final saved = await DatabaseService.instance.saveConsumption(entry);

      // Replace or add in local list
      if (existing != null) {
        final idx = _history.indexWhere((e) => e.id == existing.id);
        if (idx >= 0) _history[idx] = saved;
      } else {
        _history.add(saved);
        _history.sort((a, b) => b.date.compareTo(a.date));
      }
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar el consumo: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clear() {
    _history = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
