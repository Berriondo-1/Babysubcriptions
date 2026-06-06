import 'dart:convert';

enum DeliveryStatus { pending, inTransit, delivered }

extension DeliveryStatusExt on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.pending:    return 'Pendiente';
      case DeliveryStatus.inTransit:  return 'En camino';
      case DeliveryStatus.delivered:  return 'Entregado';
    }
  }
}

class OrderRecord {
  final int? id;
  final int userId;
  final String orderNumber;
  final String diaperTypeLabel;
  final int quantity;
  final String frequencyLabel;
  final double totalAmount;
  final String paymentMethodLabel;
  final DeliveryStatus deliveryStatus;
  final DateTime createdAt;

  const OrderRecord({
    this.id,
    required this.userId,
    required this.orderNumber,
    required this.diaperTypeLabel,
    required this.quantity,
    required this.frequencyLabel,
    required this.totalAmount,
    required this.paymentMethodLabel,
    this.deliveryStatus = DeliveryStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'order_number': orderNumber,
    'diaper_type_label': diaperTypeLabel,
    'quantity': quantity,
    'frequency_label': frequencyLabel,
    'total_amount': totalAmount,
    'payment_method_label': paymentMethodLabel,
    'delivery_status': deliveryStatus.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory OrderRecord.fromMap(Map<String, dynamic> m) => OrderRecord(
    id: m['id'] as int?,
    userId: m['user_id'] as int,
    orderNumber: m['order_number'] as String,
    diaperTypeLabel: m['diaper_type_label'] as String,
    quantity: m['quantity'] as int,
    frequencyLabel: m['frequency_label'] as String,
    totalAmount: (m['total_amount'] as num).toDouble(),
    paymentMethodLabel: m['payment_method_label'] as String,
    deliveryStatus: DeliveryStatus.values.firstWhere(
      (e) => e.name == m['delivery_status'],
      orElse: () => DeliveryStatus.pending,
    ),
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}
