import 'package:flutter/material.dart';

// PaymentMethod se define aquí (en el modelo) y payment_screen.dart lo importa
// para evitar la dependencia circular invertida anterior.
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

enum PaymentStatus { approved, rejected, pending }

extension PaymentStatusExt on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.approved:
        return 'Aprobado';
      case PaymentStatus.rejected:
        return 'Rechazado';
      case PaymentStatus.pending:
        return 'Procesando';
    }
  }
}

class PaymentRecord {
  final int? id;
  final int subscriptionId;
  final int userId;
  final String transactionId;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;

  const PaymentRecord({
    this.id,
    required this.subscriptionId,
    required this.userId,
    required this.transactionId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'subscription_id': subscriptionId,
    'user_id': userId,
    'transaction_id': transactionId,
    'amount': amount,
    'payment_method': paymentMethod.name,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory PaymentRecord.fromMap(Map<String, dynamic> m) => PaymentRecord(
    id: m['id'] as int?,
    subscriptionId: m['subscription_id'] as int,
    userId: m['user_id'] as int,
    transactionId: m['transaction_id'] as String,
    amount: (m['amount'] as num).toDouble(),
    paymentMethod: PaymentMethod.values.firstWhere(
      (e) => e.name == m['payment_method'],
      orElse: () => PaymentMethod.card,
    ),
    status: PaymentStatus.values.firstWhere(
      (e) => e.name == m['status'],
      orElse: () => PaymentStatus.approved,
    ),
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}
