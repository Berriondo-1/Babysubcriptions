import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/models/subscription.dart';
import 'package:baby_subscription/providers/auth_provider.dart';
import 'package:baby_subscription/providers/subscription_provider.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubscriptionScreen extends StatefulWidget {
  final BabyProfile babyProfile;

  const SubscriptionScreen({super.key, required this.babyProfile});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  DiaperType _selectedType = DiaperType.size1;
  double _quantity = 100;
  DeliveryFrequency _selectedFrequency = DeliveryFrequency.monthly;

  double get _estimatedCost =>
      _selectedType.pricePerUnit * _quantity * _selectedFrequency.deliveriesPerMonth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context
            .read<SubscriptionProvider>()
            .loadSubscription(userId, widget.babyProfile.id!);
      }
    });
    _prefillFromBabyProfile();
  }

  void _prefillFromBabyProfile() {
    final w = widget.babyProfile.weightKg;
    if (w < 3)        _selectedType = DiaperType.newborn;
    else if (w < 5)   _selectedType = DiaperType.size1;
    else if (w < 8)   _selectedType = DiaperType.size2;
    else if (w < 11)  _selectedType = DiaperType.size3;
    else if (w < 14)  _selectedType = DiaperType.size4;
    else              _selectedType = DiaperType.size5;
  }

  Future<void> _save() async {
    final authProv = context.read<AuthProvider>();
    final subProv = context.read<SubscriptionProvider>();
    final existing = subProv.current;

    final sub = Subscription(
      id: existing?.id,
      userId: authProv.currentUser!.id!,
      babyProfileId: widget.babyProfile.id!,
      diaperType: _selectedType,
      quantityPerOrder: _quantity.round(),
      frequency: _selectedFrequency,
      isActive: true,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    final ok = await subProv.saveSubscription(sub);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Suscripción guardada! Procede al pago para activarla.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // TODO HU-04: navegar a pantalla de pago
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(subProv.errorMessage ?? 'Error al guardar.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<SubscriptionProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configurar suscripción'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _BabyHeader(profile: widget.babyProfile),
              const SizedBox(height: 24),

              // Diaper type
              _SectionTitle(title: 'Tipo de pañal', icon: Icons.baby_changing_station_rounded),
              const SizedBox(height: 12),
              _DiaperTypeSelector(
                selected: _selectedType,
                onChanged: (t) => setState(() => _selectedType = t),
              ),
              const SizedBox(height: 24),

              // Quantity
              _SectionTitle(title: 'Cantidad por pedido', icon: Icons.inventory_2_outlined),
              const SizedBox(height: 12),
              _QuantitySlider(
                value: _quantity,
                onChanged: (v) => setState(() => _quantity = v),
              ),
              const SizedBox(height: 24),

              // Frequency
              _SectionTitle(title: 'Frecuencia de entrega', icon: Icons.calendar_month_outlined),
              const SizedBox(height: 12),
              _FrequencySelector(
                selected: _selectedFrequency,
                onChanged: (f) => setState(() => _selectedFrequency = f),
              ),
              const SizedBox(height: 24),

              // Cost summary
              _CostCard(cost: _estimatedCost),
              const SizedBox(height: 32),

              // CTA
              ElevatedButton(
                onPressed: isLoading ? null : _save,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continuar al pago'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
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

// ─── Sub-widgets ────────────────────────────────────────────────────────────

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

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _DiaperTypeSelector extends StatelessWidget {
  final DiaperType selected;
  final ValueChanged<DiaperType> onChanged;
  const _DiaperTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: DiaperType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type.weightRange,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white.withOpacity(0.85)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuantitySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _QuantitySlider({required this.value, required this.onChanged});

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
                'Unidades',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${value.round()} uds',
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
              value: value,
              min: 20,
              max: 300,
              divisions: 28,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('20', style: Theme.of(context).textTheme.bodyMedium),
              Text('300', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  final DeliveryFrequency selected;
  final ValueChanged<DeliveryFrequency> onChanged;
  const _FrequencySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DeliveryFrequency.values.map((freq) {
        final isSelected = freq == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: freq != DeliveryFrequency.monthly ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(freq),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    freq.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CostCard extends StatelessWidget {
  final double cost;
  const _CostCard({required this.cost});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.attach_money_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Costo estimado mensual',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${cost.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
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