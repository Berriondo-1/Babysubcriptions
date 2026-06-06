import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/models/subscription.dart';
import 'package:baby_subscription/providers/subscription_provider.dart';
import 'package:baby_subscription/screens/subscription_active_screen.dart';
import 'package:baby_subscription/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

enum PaymentMethod { card, paypal, transferencia }

extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.card:
        return 'Tarjeta de crédito/débito';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.transferencia:
        return 'Transferencia bancaria';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.paypal:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethod.transferencia:
        return Icons.account_balance_rounded;
    }
  }
}

class PaymentScreen extends StatefulWidget {
  final BabyProfile babyProfile;
  final Subscription subscription;

  const PaymentScreen({
    super.key,
    required this.babyProfile,
    required this.subscription,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  PaymentMethod _selectedMethod = PaymentMethod.card;
  bool _processing = false;
  bool _termsAccepted = false;

  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _cardFormValid {
    if (_selectedMethod != PaymentMethod.card) return true;
    return _cardNumberCtrl.text.replaceAll(' ', '').length == 16 &&
        _cardNameCtrl.text.trim().length >= 3 &&
        _expiryCtrl.text.length == 5 &&
        _cvvCtrl.text.length >= 3;
  }

  bool get _canPay => _termsAccepted && _cardFormValid;

  Future<void> _processPay() async {
    if (!_canPay) return;
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => SubscriptionActiveScreen(
          babyProfile: widget.babyProfile,
          subscription: widget.subscription,
          paymentMethod: _selectedMethod,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirmar pago'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: _processing
            ? _ProcessingOverlay(anim: _pulseAnim)
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OrderSummaryCard(
                      babyProfile: widget.babyProfile,
                      subscription: sub,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(
                      title: 'Método de pago',
                      icon: Icons.payment_rounded,
                    ),
                    const SizedBox(height: 12),
                    _PaymentMethodSelector(
                      selected: _selectedMethod,
                      onChanged: (m) => setState(() => _selectedMethod = m),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedMethod == PaymentMethod.card) ...[
                      _CardForm(
                        numberCtrl: _cardNumberCtrl,
                        nameCtrl: _cardNameCtrl,
                        expiryCtrl: _expiryCtrl,
                        cvvCtrl: _cvvCtrl,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_selectedMethod == PaymentMethod.paypal) ...[
                      _InfoBanner(
                        icon: Icons.account_balance_wallet_rounded,
                        text:
                            'Serás redirigido a PayPal para completar el pago de forma segura.',
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_selectedMethod == PaymentMethod.transferencia) ...[
                      const _TransferInfo(),
                      const SizedBox(height: 16),
                    ],
                    _TermsCheckbox(
                      accepted: _termsAccepted,
                      onChanged: (v) =>
                          setState(() => _termsAccepted = v ?? false),
                    ),
                    const SizedBox(height: 24),
                    AnimatedOpacity(
                      opacity: _canPay ? 1.0 : 0.6,
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: _canPay ? _processPay : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size(double.infinity, 54),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Pagar COP ${sub.estimatedMonthlyCost.toStringAsFixed(0)}/mes',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.security_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pago seguro con cifrado SSL',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
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

// ── Sub-widgets ──────────────────────────────────────────────────────────────

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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final BabyProfile babyProfile;
  final Subscription subscription;
  const _OrderSummaryCard({
    required this.babyProfile,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
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
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    babyProfile.name.isNotEmpty
                        ? babyProfile.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suscripción para ${babyProfile.name}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Talla ${sub.diaperType.label}  ·  ${sub.frequency.label}',
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
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Pañales por pedido',
            value: '${sub.quantityPerOrder} uds',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Precio por unidad',
            value: 'COP ${sub.diaperType.pricePerUnit.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Entregas al mes',
            value: '${sub.frequency.deliveriesPerMonth}',
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total mensual',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                'COP ${sub.estimatedMonthlyCost.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;
  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PaymentMethod.values.map((method) {
        final isSelected = method == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onChanged(method),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      method.icon,
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    method.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: 2,
                      ),
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CardForm extends StatelessWidget {
  final TextEditingController numberCtrl, nameCtrl, expiryCtrl, cvvCtrl;
  final VoidCallback onChanged;

  const _CardForm({
    required this.numberCtrl,
    required this.nameCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Column(
        children: [
          TextField(
            controller: numberCtrl,
            onChanged: (_) => onChanged(),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            maxLength: 19,
            decoration: const InputDecoration(
              labelText: 'Número de tarjeta',
              counterText: '',
              prefixIcon: Icon(
                Icons.credit_card_rounded,
                color: AppColors.primary,
              ),
              hintText: '1234 5678 9012 3456',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: nameCtrl,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre en la tarjeta',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
              ),
              hintText: 'Como aparece en la tarjeta',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: expiryCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryFormatter(),
                  ],
                  maxLength: 5,
                  decoration: const InputDecoration(
                    labelText: 'Vencimiento',
                    counterText: '',
                    prefixIcon: Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                    ),
                    hintText: 'MM/AA',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: cvvCtrl,
                  onChanged: (_) => onChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    counterText: '',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                    ),
                    hintText: '•••',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferInfo extends StatelessWidget {
  const _TransferInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos bancarios',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _BankRow(label: 'Banco', value: 'BabyBank S.A.'),
          _BankRow(label: 'Cuenta', value: '001-2345-6789-01'),
          _BankRow(label: 'Tipo', value: 'Ahorros'),
          _BankRow(label: 'Titular', value: 'BabySubscription LLC'),
          const SizedBox(height: 8),
          Text(
            'Envía el comprobante a pagos@babysubscription.com con tu número de pedido.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  const _BankRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
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

class _TermsCheckbox extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool?> onChanged;
  const _TermsCheckbox({required this.accepted, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!accepted),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: accepted,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Acepto los términos de suscripción recurrente. El cobro se realizará automáticamente según la frecuencia seleccionada. Puedo cancelar en cualquier momento.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  final Animation<double> anim;
  const _ProcessingOverlay({required this.anim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: anim,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Procesando pago...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Por favor no cierres la app',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.primaryLight,
              borderRadius: BorderRadius.all(Radius.circular(8)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Formatters ───────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length > 4) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
