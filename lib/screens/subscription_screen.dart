import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/models/subscription.dart';
import 'package:baby_subscription/providers/auth_provider.dart';
import 'package:baby_subscription/providers/subscription_provider.dart';
import 'package:baby_subscription/screens/payment_screen.dart';
import 'package:baby_subscription/services/admin_service.dart';
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
  // Producto seleccionado del catálogo de Firestore
  Map<String, dynamic>? _selectedProduct;

  // Lista de productos cargados desde Firestore
  List<Map<String, dynamic>> _products = [];
  bool _loadingProducts = true;

  // Cantidad seleccionada (limitada por stock del producto)
  int _quantity = 1;

  DeliveryFrequency _selectedFrequency = DeliveryFrequency.monthly;

  /// Precio por unidad del producto seleccionado
  double get _pricePerUnit {
    if (_selectedProduct == null) return 0;
    final packPrice = (_selectedProduct!['packPrice'] as num?)?.toDouble() ?? 0;
    final unitsPerPack =
        (_selectedProduct!['unitsPerPack'] as num?)?.toInt() ?? 1;
    return unitsPerPack > 0 ? packPrice / unitsPerPack : 0;
  }

  /// Stock disponible del producto seleccionado
  int get _availableStock {
    if (_selectedProduct == null) return 0;
    return (_selectedProduct!['stockQuantity'] as num?)?.toInt() ?? 0;
  }

  double get _estimatedCost =>
      _pricePerUnit * _quantity * _selectedFrequency.deliveriesPerMonth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<SubscriptionProvider>().loadSubscription(
          userId,
          widget.babyProfile.id!,
        );
      }
    });
    _loadProducts();
  }

  /// Carga productos desde Firestore y pre-selecciona el que coincida con
  /// la talla recomendada para el bebé (y tenga stock > 0).
  Future<void> _loadProducts() async {
    final all = await AdminService.instance.getProductsOnce();
    // Solo productos con stock disponible
    final available = all.where((p) {
      final qty = (p['stockQuantity'] as num?)?.toInt() ?? 0;
      return qty > 0;
    }).toList();

    if (!mounted) return;
    setState(() {
      _products = available;
      _loadingProducts = false;
    });

    if (available.isNotEmpty) {
      _preselectByBabySize(available);
    }
  }

  void _preselectByBabySize(List<Map<String, dynamic>> products) {
    final w = widget.babyProfile.weightKg;
    String idealSize;
    if (w < 3) {
      idealSize = 'newborn';
    } else if (w < 5) {
      idealSize = 'size1';
    } else if (w < 8) {
      idealSize = 'size2';
    } else if (w < 11) {
      idealSize = 'size3';
    } else if (w < 14) {
      idealSize = 'size4';
    } else {
      idealSize = 'size5';
    }

    // Busca el primer producto con la talla ideal
    final match = products.firstWhere(
      (p) => p['size'] == idealSize,
      orElse: () => products.first,
    );

    setState(() {
      _selectedProduct = match;
      // Inicializa quantity: mínimo entre 1 y el stock disponible
      _quantity = _availableStock.clamp(1, _availableStock);
    });
  }

  void _onProductChanged(Map<String, dynamic>? product) {
    if (product == null) return;
    setState(() {
      _selectedProduct = product;
      // Ajusta quantity si excede el nuevo stock
      final maxStock = (product['stockQuantity'] as num?)?.toInt() ?? 1;
      _quantity = _quantity.clamp(1, maxStock);
    });
  }

  Future<void> _save() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un producto para continuar'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProv = context.read<AuthProvider>();
    final subProv = context.read<SubscriptionProvider>();
    final existing = subProv.current;

    // Mapear el tamaño del producto al DiaperType
    final sizeStr = _selectedProduct!['size'] as String? ?? 'size1';
    final diaperType = DiaperType.values.firstWhere(
      (e) => e.name == sizeStr,
      orElse: () => DiaperType.size1,
    );

    final sub = Subscription(
      id: existing?.id,
      userId: authProv.currentUser!.id!,
      babyProfileId: widget.babyProfile.id!,
      diaperType: diaperType,
      quantityPerOrder: _quantity,
      frequency: _selectedFrequency,
      isActive: true,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          babyProfile: widget.babyProfile,
          subscription: sub,
          // Pasamos el docId del producto para decrementar stock al confirmar pago
          catalogProductId: _selectedProduct!['docId'] as String?,
        ),
      ),
    );
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
        child: _loadingProducts
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _products.isEmpty
            ? _EmptyStock()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con info del bebé
                    _BabyHeader(profile: widget.babyProfile),
                    const SizedBox(height: 24),

                    // Dropdown de producto
                    _SectionTitle(
                      title: 'Producto',
                      icon: Icons.baby_changing_station_rounded,
                    ),
                    const SizedBox(height: 12),
                    _ProductDropdown(
                      products: _products,
                      selected: _selectedProduct,
                      onChanged: _onProductChanged,
                    ),
                    const SizedBox(height: 24),

                    // Cantidad (limitada al stock)
                    _SectionTitle(
                      title: 'Cantidad por pedido',
                      icon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 12),
                    if (_selectedProduct != null)
                      _QuantitySelector(
                        value: _quantity,
                        maxStock: _availableStock,
                        onChanged: (v) => setState(() => _quantity = v),
                      ),
                    const SizedBox(height: 24),

                    // Frecuencia
                    _SectionTitle(
                      title: 'Frecuencia de entrega',
                      icon: Icons.calendar_month_outlined,
                    ),
                    const SizedBox(height: 12),
                    _FrequencySelector(
                      selected: _selectedFrequency,
                      onChanged: (f) =>
                          setState(() => _selectedFrequency = f),
                    ),
                    const SizedBox(height: 24),

                    // Costo estimado
                    _CostCard(cost: _estimatedCost),
                    const SizedBox(height: 32),

                    // CTA
                    ElevatedButton(
                      onPressed: isLoading ? null : _save,
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Continuar al pago'),
                                SizedBox(width: 8),
                                Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18),
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

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _EmptyStock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😔', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Sin stock disponible',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Por el momento no hay pañales disponibles. Vuelve pronto.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

// ── Dropdown de producto ──────────────────────────────────────────────────────

class _ProductDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>?> onChanged;

  const _ProductDropdown({
    required this.products,
    required this.selected,
    required this.onChanged,
  });

  static const _sizeLabels = {
    'newborn': 'Recién nacido',
    'size1': 'Talla 1',
    'size2': 'Talla 2',
    'size3': 'Talla 3',
    'size4': 'Talla 4',
    'size5': 'Talla 5',
  };

  String _productLabel(Map<String, dynamic> p) {
    final name = p['name'] as String? ?? '';
    final brand = p['brand'] as String? ?? '';
    final size = _sizeLabels[p['size']] ?? (p['size'] as String? ?? '');
    final stock = (p['stockQuantity'] as num?)?.toInt() ?? 0;
    return '$name — $brand  ·  $size  (Stock: $stock)';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: AppColors.primary),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          hint: const Text(
            'Selecciona un producto',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          items: products.map((p) {
            final stock = (p['stockQuantity'] as num?)?.toInt() ?? 0;
            final size = _sizeLabels[p['size']] ?? (p['size'] as String? ?? '');
            return DropdownMenuItem<Map<String, dynamic>>(
              value: p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${p['emoji'] ?? '🍼'}  ${p['name'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${p['brand'] ?? ''}  ·  $size',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _stockColor(stock).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Stock: $stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _stockColor(stock),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          selectedItemBuilder: (context) => products.map((p) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _productLabel(p),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _stockColor(int qty) {
    if (qty <= 0) return AppColors.error;
    if (qty <= 10) return Colors.orange;
    return AppColors.success;
  }
}

// ── Selector de cantidad (slider limitado al stock) ───────────────────────────

class _QuantitySelector extends StatelessWidget {
  final int value;
  final int maxStock;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({
    required this.value,
    required this.maxStock,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Si el stock es 0 o 1, no tiene sentido mostrar slider
    final effectiveMax = maxStock < 1 ? 1 : maxStock;
    final effectiveValue = value.clamp(1, effectiveMax);

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
                  '$effectiveValue uds',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (effectiveMax > 1) ...[
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
                value: effectiveValue.toDouble(),
                min: 1,
                max: effectiveMax.toDouble(),
                divisions: effectiveMax > 1 ? effectiveMax - 1 : 1,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1',
                    style: Theme.of(context).textTheme.bodyMedium),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Máx: $effectiveMax',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: Colors.orange),
                  SizedBox(width: 6),
                  Text(
                    'Solo queda 1 unidad en stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
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
                    color:
                        isSelected ? AppColors.primary : AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    freq.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
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
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
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
            child: const Icon(
              Icons.attach_money_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Costo estimado mensual',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  'COP ${cost.toStringAsFixed(0)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
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
