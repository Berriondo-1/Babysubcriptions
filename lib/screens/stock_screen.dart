import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/providers/stock_provider.dart';
import 'package:baby_subscription/providers/subscription_provider.dart';
import 'package:baby_subscription/providers/auth_provider.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StockScreen extends StatefulWidget {
  final BabyProfile babyProfile;
  const StockScreen({super.key, required this.babyProfile});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  int _newThreshold = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final stockProv = context.read<StockProvider>();
      await stockProv.loadStock(widget.babyProfile.id!);
      setState(() => _newThreshold = stockProv.alertThreshold);

      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        await context.read<SubscriptionProvider>().loadSubscription(
          userId,
          widget.babyProfile.id!,
        );
      }
    });
  }

  Future<void> _saveThreshold() async {
    await context.read<StockProvider>().setThreshold(_newThreshold);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Umbral actualizado: $_newThreshold pañales'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();
    final sub = context.watch<SubscriptionProvider>().current;
    final total = sub?.quantityPerOrder ?? 0;
    final current = stockProv.currentStock;
    final used = (total - current).clamp(0, total);
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Stock · ${widget.babyProfile.name}'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header bebé ──────────────────────────────────────
            _BabyHeader(profile: widget.babyProfile),
            const SizedBox(height: 24),

            // ── Tarjeta principal de stock ───────────────────────
            _StockMainCard(
              current: current,
              total: total,
              used: used,
              progress: progress,
              isLow: stockProv.isStockLow,
            ),
            const SizedBox(height: 20),

            // ── Desglose ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Total pedido',
                    value: '$total',
                    unit: 'pañales',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Usados',
                    value: '$used',
                    unit: 'pañales',
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.savings_outlined,
                    label: 'Quedan',
                    value: '$current',
                    unit: 'pañales',
                    color: stockProv.isStockLow
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Alerta si stock bajo ──────────────────────────────
            if (stockProv.isStockLow) ...[
              _AlertBanner(remaining: current),
              const SizedBox(height: 20),
            ],

            // ── Configurar umbral de alerta ──────────────────────
            Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Umbral de alerta',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _ThresholdCard(
              value: _newThreshold,
              onChanged: (v) => setState(() => _newThreshold = v),
              onSave: _saveThreshold,
            ),
            const SizedBox(height: 24),

            // ── Info suscripción ─────────────────────────────────
            if (sub != null) ...[
              Row(
                children: [
                  const Icon(Icons.subscriptions_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Suscripción activa',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              _SubInfoCard(sub: sub),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _BabyHeader extends StatelessWidget {
  final BabyProfile profile;
  const _BabyHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text(
                  'Talla: ${profile.sizeShort}  ·  ${profile.ageLabel}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockMainCard extends StatelessWidget {
  final int current;
  final int total;
  final int used;
  final double progress;
  final bool isLow;
  const _StockMainCard({
    required this.current,
    required this.total,
    required this.used,
    required this.progress,
    required this.isLow,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLow ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLow
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pañales disponibles',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                    Text(
                      '$current pañales',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              color: color, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isLow ? 'Stock bajo' : 'OK',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(
                total > 0
                    ? '${(progress * 100).round()}% disponible'
                    : 'Sin suscripción activa',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              Text('$total',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final int remaining;
  const _AlertBanner({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¡Stock bajo!',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error)),
                Text('Solo quedan $remaining pañales. Considera reordenar.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdCard extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onSave;
  const _ThresholdCard({
    required this.value,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alertar cuando queden:',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$value pañales',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.15),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 5,
              max: 50,
              divisions: 9,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5', style: Theme.of(context).textTheme.bodyMedium),
              Text('50', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onSave,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Guardar umbral'),
          ),
        ],
      ),
    );
  }
}

class _SubInfoCard extends StatelessWidget {
  final sub;
  const _SubInfoCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _Row(
            icon: Icons.baby_changing_station_rounded,
            label: 'Talla',
            value: '${sub.diaperType.label} · ${sub.diaperType.weightRange}',
          ),
          const Divider(color: AppColors.divider, height: 20),
          _Row(
            icon: Icons.inventory_2_outlined,
            label: 'Cantidad por pedido',
            value: '${sub.quantityPerOrder} pañales',
          ),
          const Divider(color: AppColors.divider, height: 20),
          _Row(
            icon: Icons.calendar_month_outlined,
            label: 'Frecuencia',
            value: sub.frequency.label,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark)),
      ],
    );
  }
}