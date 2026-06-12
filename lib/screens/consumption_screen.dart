import 'dart:math' as math;

import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/providers/consumption_provider.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:baby_subscription/providers/stock_provider.dart';

/// Full-page screen for tracking daily diaper usage.
/// Covers SCRUM-38 (log), SCRUM-39 (averages), SCRUM-40 (suggestion),
/// SCRUM-41 (persisted in SQLite via DatabaseService) and
/// SCRUM-42 (bar-chart trend).
class ConsumptionScreen extends StatefulWidget {
  final BabyProfile babyProfile;

  const ConsumptionScreen({super.key, required this.babyProfile});

  @override
  State<ConsumptionScreen> createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends State<ConsumptionScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final prov = context.read<ConsumptionProvider>();
    await prov.loadHistory(widget.babyProfile.id!);
    
    // Cargar stock del bebé
    await context.read<StockProvider>().loadStock(widget.babyProfile.id!);
    
    final today = prov.todayEntry;
    if (today != null && mounted) {
      _controller.text = today.diaperCount.toString();
    }
  });
}

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
  final count = int.tryParse(_controller.text.trim());
  if (count == null || count < 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ingresa un número válido (mínimo 0).'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return;
  }
  _focusNode.unfocus();

  // Obtener consumo anterior de hoy para calcular la diferencia
  final prov = context.read<ConsumptionProvider>();
  final previousCount = prov.todayEntry?.diaperCount ?? 0;
  final diff = count - previousCount; // puede ser positivo o negativo

  final ok = await prov.logToday(widget.babyProfile.id!, count);

  if (ok && diff != 0) {
    // Descontar del stock solo la diferencia respecto al registro anterior
    await context.read<StockProvider>().registerUsage(
      diapersUsed: diff,
      babyName: widget.babyProfile.name,
      babyProfileId: widget.babyProfile.id!,
    );
  }

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ok ? '✓ Registro guardado' : 'Error al guardar'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Seguimiento de consumo · ${widget.babyProfile.name}'),
      ),
      body: Consumer<ConsumptionProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading && prov.history.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Daily input (SCRUM-38) ─────────────────────────────────
                _DailyInputCard(
                  controller: _controller,
                  focusNode: _focusNode,
                  onSave: _save,
                  isLoading: prov.isLoading,
                ),
                const SizedBox(height: 20),

                // ── Averages (SCRUM-39) ───────────────────────────────────
                _AveragesCard(
                  weekly: prov.weeklyAverage,
                  monthly: prov.monthlyAverage,
                ),
                const SizedBox(height: 20),

                // ── Suggestion (SCRUM-40) ─────────────────────────────────
                if (prov.suggestedMonthlyQuantity > 0)
                  _SuggestionCard(quantity: prov.suggestedMonthlyQuantity),

                if (prov.suggestedMonthlyQuantity > 0)
                  const SizedBox(height: 20),

                // ── Trend chart (SCRUM-42) ────────────────────────────────
                _TrendChart(dailyTotals: prov.getDailyTotals(days: 30)),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily input card (SCRUM-38)
// ─────────────────────────────────────────────────────────────────────────────

class _DailyInputCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSave;
  final bool isLoading;

  const _DailyInputCard({
    required this.controller,
    required this.focusNode,
    required this.onSave,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.baby_changing_station_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pañales usados hoy',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ej. 6',
                    suffixText: 'pañales',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 54),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Registrar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Si ya registraste hoy, el valor se actualizará.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Averages card (SCRUM-39)
// ─────────────────────────────────────────────────────────────────────────────

class _AveragesCard extends StatelessWidget {
  final double weekly;
  final double monthly;

  const _AveragesCard({required this.weekly, required this.monthly});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Promedios de consumo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AverageTile(
                  label: 'Promedio semanal',
                  sublabel: 'últimos 7 días',
                  value: weekly,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AverageTile(
                  label: 'Promedio mensual',
                  sublabel: 'últimos 30 días',
                  value: monthly,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AverageTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final double value;
  final Color color;

  const _AverageTile({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(fontSize: 10, color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          Text(
            value == 0 ? '—' : '${value.toStringAsFixed(1)} /día',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestion card (SCRUM-40)
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final int quantity;

  const _SuggestionCard({required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sugerencia de cantidad mensual',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$quantity pañales al mes',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trend chart (SCRUM-42) – simple bar chart, no external packages
// ─────────────────────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<MapEntry<DateTime, int>> dailyTotals;

  const _TrendChart({required this.dailyTotals});

  @override
  Widget build(BuildContext context) {
    final hasData = dailyTotals.any((e) => e.value > 0);
    final maxVal = dailyTotals.isEmpty
        ? 1
        : dailyTotals.map((e) => e.value).reduce(math.max);
    final effectiveMax = maxVal == 0 ? 1 : maxVal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tendencia de consumo (30 días)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!hasData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.insert_chart_outlined_rounded,
                      size: 40,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sin datos aún.\nEmpieza a registrar los pañales del día.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: CustomPaint(
                painter: _BarChartPainter(
                  data: dailyTotals,
                  maxValue: effectiveMax,
                  barColor: AppColors.primary,
                  todayColor: AppColors.accent,
                ),
                size: const Size(double.infinity, 130),
              ),
            ),
          if (hasData) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ChartLabel(
                  dailyTotals.isNotEmpty
                      ? dailyTotals.first.key
                      : DateTime.now(),
                  prefix: 'Hace 30 días',
                ),
                _ChartLabel(DateTime.now(), prefix: 'Hoy'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartLabel extends StatelessWidget {
  final DateTime date;
  final String prefix;

  const _ChartLabel(this.date, {required this.prefix});

  @override
  Widget build(BuildContext context) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final label = '${date.day} ${months[date.month - 1]}';
    return Column(
      crossAxisAlignment: prefix == 'Hoy'
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          prefix,
          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<MapEntry<DateTime, int>> data;
  final int maxValue;
  final Color barColor;
  final Color todayColor;

  _BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.barColor,
    required this.todayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final barWidth = size.width / data.length;
    final gap = barWidth * 0.25;
    final effectiveBarWidth = barWidth - gap;
    final todayDate = DateTime.now();

    final normalPaint = Paint()
      ..color = barColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final todayPaint = Paint()
      ..color = todayColor
      ..style = PaintingStyle.fill;

    final zeroPaint = Paint()
      ..color = barColor.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final isToday =
          entry.key.year == todayDate.year &&
          entry.key.month == todayDate.month &&
          entry.key.day == todayDate.day;

      final barHeightRatio = entry.value / maxValue;
      final barHeight = entry.value == 0
          ? 3.0
          : barHeightRatio * (size.height - 10);

      final left = i * barWidth + gap / 2;
      final top = size.height - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, effectiveBarWidth, barHeight),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        rect,
        entry.value == 0 ? zeroPaint : (isToday ? todayPaint : normalPaint),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.data != data || old.maxValue != maxValue;
}
