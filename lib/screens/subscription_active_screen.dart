import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/models/subscription.dart';
import 'package:baby_subscription/providers/subscription_provider.dart';
import 'package:baby_subscription/models/payment_record.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_subscription/providers/stock_provider.dart';

class SubscriptionActiveScreen extends StatefulWidget {
  final BabyProfile babyProfile;
  final Subscription subscription;
  final PaymentMethod paymentMethod;
  final String transactionId;
  final DateTime paymentDate;

  const SubscriptionActiveScreen({
    super.key,
    required this.babyProfile,
    required this.subscription,
    required this.paymentMethod,
    required this.transactionId,
    required this.paymentDate,
  });

  @override
  State<SubscriptionActiveScreen> createState() =>
      _SubscriptionActiveScreenState();
}

class _SubscriptionActiveScreenState extends State<SubscriptionActiveScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkAnim;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) _checkCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  Future<void> _onPedidoRecibido(Subscription sub, BabyProfile baby) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PedidoRecibidoSheet(
        subscription: sub,
        baby: baby,
        transactionId: widget.transactionId,
        paymentDate: widget.paymentDate,
      ),
    );
  }

  Future<void> _cancelSubscription() async {
  final confirm = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CancelSheet(babyName: widget.babyProfile.name),
  );
  if (confirm != true || !mounted) return;

  final subProv = context.read<SubscriptionProvider>();
  final stockProv = context.read<StockProvider>(); // ← nuevo
  final ok = await subProv.cancelSubscription(stockProv); // ← pasar stockProv
  if (!mounted) return;

  if (ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Suscripción cancelada exitosamente.'),
        backgroundColor: AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(subProv.errorMessage ?? 'Error al cancelar.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final baby = widget.babyProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mi suscripción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            tooltip: 'Inicio',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              ScaleTransition(
                scale: _checkAnim,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _showContent ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    Text(
                      '¡Suscripción activa!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu primer pedido llegará pronto 🍼',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _StatusBadge(isActive: sub.isActive),
                    const SizedBox(height: 20),
                    _InfoCard(baby: baby, sub: sub),
                    const SizedBox(height: 16),
                    _PaymentCard(
                      method: widget.paymentMethod,
                      monthlyCost: sub.estimatedMonthlyCost,
                    ),
                    const SizedBox(height: 16),
                    _ReceiptCard(
                      transactionId: widget.transactionId,
                      paymentDate: widget.paymentDate,
                    ),
                    const SizedBox(height: 16),
                    _DeliveriesPreview(frequency: sub.frequency),
                    const SizedBox(height: 28),
                    // Botón "Pedido recibido"
                    ElevatedButton(
                      onPressed: () => _onPedidoRecibido(sub, baby),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Pedido recibido ✅',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _cancelSubscription,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.error.withOpacity(0.6),
                          width: 1.5,
                        ),
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Cancelar suscripción',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Puedes cancelar en cualquier momento',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withOpacity(0.12)
            : AppColors.divider,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive
              ? AppColors.success.withOpacity(0.5)
              : AppColors.textSecondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.success : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Activa' : 'Cancelada',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final BabyProfile baby;
  final Subscription sub;
  const _InfoCard({required this.baby, required this.sub});

  String _formatDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.child_care_rounded,
            label: 'Bebé',
            value: baby.name,
          ),
          const Divider(color: AppColors.divider, height: 0),
          _DetailRow(
            icon: Icons.baby_changing_station_rounded,
            label: 'Talla',
            value: '${sub.diaperType.label} · ${sub.diaperType.weightRange}',
          ),
          const Divider(color: AppColors.divider, height: 0),
          _DetailRow(
            icon: Icons.inventory_2_outlined,
            label: 'Por pedido',
            value: '${sub.quantityPerOrder} pañales',
          ),
          const Divider(color: AppColors.divider, height: 0),
          _DetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Frecuencia',
            value: sub.frequency.label,
          ),
          const Divider(color: AppColors.divider, height: 0),
          _DetailRow(
            icon: Icons.event_available_rounded,
            label: 'Creada',
            value: _formatDate(sub.createdAt),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentMethod method;
  final double monthlyCost;
  const _PaymentCard({required this.method, required this.monthlyCost});

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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
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
            child: Icon(method.icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Próximo cobro en 30 días',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'COP ${_fmtCOP(monthlyCost)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final String transactionId;
  final DateTime paymentDate;
  const _ReceiptCard({required this.transactionId, required this.paymentDate});

  String _formatDateTime(DateTime d) {
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
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}  ·  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Recibo de compra',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Aprobado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),
          _ReceiptRow(
            label: 'N° de transacción',
            value: transactionId,
            mono: true,
          ),
          const SizedBox(height: 8),
          _ReceiptRow(
            label: 'Fecha y hora',
            value: _formatDateTime(paymentDate),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: mono ? 'monospace' : null,
              letterSpacing: mono ? 0.5 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliveriesPreview extends StatelessWidget {
  final DeliveryFrequency frequency;
  const _DeliveriesPreview({required this.frequency});

  String _formatDate(DateTime d) {
    const weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = [
      'enero',
      'feb',
      'mar',
      'abr',
      'mayo',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${weekDays[d.weekday - 1]} ${d.day} de ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final deliveries = <DateTime>[];
    for (int i = 1; i <= frequency.deliveriesPerMonth; i++) {
      final days = (30 / frequency.deliveriesPerMonth * i).round();
      deliveries.add(now.add(Duration(days: days)));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Próximas entregas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...deliveries.asMap().entries.map((entry) {
            final i = entry.key;
            final date = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? AppColors.primary
                          : AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: i == 0 ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400,
                        color: i == 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (i == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Próxima',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Cancel sheet ──────────────────────────────────────────────────────────────

class _CancelSheet extends StatelessWidget {
  final String babyName;
  const _CancelSheet({required this.babyName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_rounded,
              color: AppColors.error,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cancelar suscripción',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '¿Estás seguro de que deseas cancelar la suscripción de $babyName? Los pedidos pendientes no serán afectados.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Sí, cancelar suscripción'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Mantener suscripción',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hoja "Pedido recibido" ─────────────────────────────────────────────────────

class _PedidoRecibidoSheet extends StatelessWidget {
  final Subscription subscription;
  final BabyProfile baby;
  final String transactionId;
  final DateTime paymentDate;

  const _PedidoRecibidoSheet({
    required this.subscription,
    required this.baby,
    required this.transactionId,
    required this.paymentDate,
  });

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

  static String _fmtDate(DateTime d) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} de ${months[d.month - 1]} de ${d.year}  ·  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final sub = subscription;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),

              // Ícono de éxito
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '¡Pedido confirmado!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Aquí está el resumen de lo que recibirás',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Tarjeta resumen del pedido
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.divider, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado bebé
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              baby.name.isNotEmpty
                                  ? baby.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              baby.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              baby.ageLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 14),

                    // Filas del resumen
                    _PedidoRow(
                      icon: Icons.baby_changing_station_rounded,
                      label: 'Producto',
                      value:
                          '${sub.diaperType.label} · ${sub.diaperType.weightRange}',
                    ),
                    _PedidoRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Cantidad',
                      value: '${sub.quantityPerOrder} pañales',
                    ),
                    _PedidoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Frecuencia',
                      value: sub.frequency.label,
                    ),
                    _PedidoRow(
                      icon: Icons.payments_outlined,
                      label: 'Pago',
                      value: 'COP ${_fmtCOP(sub.estimatedMonthlyCost)}/mes',
                      highlight: true,
                    ),
                    _PedidoRow(
                      icon: Icons.receipt_long_rounded,
                      label: 'Transacción',
                      value: transactionId,
                      mono: true,
                    ),
                    _PedidoRow(
                      icon: Icons.schedule_rounded,
                      label: 'Fecha',
                      value: _fmtDate(paymentDate),
                    ),
                    const SizedBox(height: 6),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 14),

                    // Estado del pedido
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_rounded,
                            size: 20,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'En camino a tu hogar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                                Text(
                                  'Tu pedido fue procesado y llegará según la frecuencia seleccionada',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.success.withOpacity(0.8),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botón cerrar
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Entendido, gracias 🎉'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PedidoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final bool mono;

  const _PedidoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: highlight ? AppColors.primaryDark : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: highlight ? 14 : 13,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w600,
                color: highlight
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
                fontFamily: mono ? 'monospace' : null,
                letterSpacing: mono ? 0.4 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
