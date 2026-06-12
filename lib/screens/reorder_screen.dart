import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/models/subscription.dart';
import 'package:baby_subscription/providers/auth_provider.dart';
import 'package:baby_subscription/providers/stock_provider.dart';
import 'package:baby_subscription/providers/subscription_provider.dart';
import 'package:baby_subscription/screens/subscription_screen.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReorderScreen extends StatefulWidget {
  final BabyProfile babyProfile;

  const ReorderScreen({super.key, required this.babyProfile});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  int _newThreshold = 10;

  static String _fmtCOP(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buf.write('.');
      buf.write(s[i]);
      c++;
    }
    return buf.toString().split('').reversed.join();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockProv = context.read<StockProvider>();
      _newThreshold = stockProv.alertThreshold;

      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<SubscriptionProvider>().loadSubscription(
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

  void _goToSubscription() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(babyProfile: widget.babyProfile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProv = context.watch<StockProvider>();
    final sub = context.watch<SubscriptionProvider>().current;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reordenar pañales'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bebé
              _BabyHeader(profile: widget.babyProfile),
              const SizedBox(height: 24),

              // Alerta de stock bajo
              if (stockProv.isStockLow)
                _StockAlertBanner(remaining: stockProv.currentStock),
              if (stockProv.isStockLow) const SizedBox(height: 16),

              // Stock actual
              _StockCard(
                current: stockProv.currentStock,
                threshold: stockProv.alertThreshold,
              ),
              const SizedBox(height: 24),

              // Configurar umbral
              Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Umbral de alerta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ThresholdSelector(
                value: _newThreshold,
                onChanged: (v) => setState(() => _newThreshold = v),
                onSave: _saveThreshold,
              ),
              const SizedBox(height: 24),

              // Suscripción activa
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tu suscripción',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              sub != null
                  ? _SubscriptionSummary(sub: sub)
                  : const _NoSubscriptionCard(),
              const SizedBox(height: 32),

              // Botón reordenar
              ElevatedButton(
                onPressed: _goToSubscription,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Reordenar ahora'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

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
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Talla recomendada: ${profile.sizeShort}  ·  ${profile.ageLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockAlertBanner extends StatelessWidget {
  final int remaining;
  const _StockAlertBanner({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.4), width: 1),
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
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Stock bajo!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  'Solo quedan $remaining pañales disponibles.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final int current;
  final int threshold;
  const _StockCard({required this.current, required this.threshold});

  @override
  Widget build(BuildContext context) {
    final isLow = current <= threshold;
    final color = isLow ? AppColors.error : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock actual',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$current pañales',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isLow ? 'Bajo' : 'OK',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onSave;
  const _ThresholdSelector({
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
              Text(
                'Alertar cuando queden:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$value pañales',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Guardar umbral'),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionSummary extends StatelessWidget {
  final Subscription sub;
  const _SubscriptionSummary({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
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
            label: 'Cantidad',
            value: '${sub.quantityPerOrder} pañales',
          ),
          const Divider(color: AppColors.divider, height: 20),
          _Row(
            icon: Icons.calendar_month_outlined,
            label: 'Frecuencia',
            value: sub.frequency.label,
          ),
          const Divider(color: AppColors.divider, height: 20),
          _Row(
            icon: Icons.attach_money_rounded,
            label: 'Costo mensual',
            value: 'COP ${(sub.estimatedMonthlyCost)}',
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
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _NoSubscriptionCard extends StatelessWidget {
  const _NoSubscriptionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No tienes una suscripción activa. Crea una para recibir pañales automáticamente.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
