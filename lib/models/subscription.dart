enum DiaperType { newborn, size1, size2, size3, size4, size5 }

enum DeliveryFrequency { weekly, biweekly, monthly }

extension DiaperTypeExt on DiaperType {
  String get label {
    switch (this) {
      case DiaperType.newborn: return 'Newborn';
      case DiaperType.size1:   return 'Size 1';
      case DiaperType.size2:   return 'Size 2';
      case DiaperType.size3:   return 'Size 3';
      case DiaperType.size4:   return 'Size 4';
      case DiaperType.size5:   return 'Size 5';
    }
  }

  String get weightRange {
    switch (this) {
      case DiaperType.newborn: return '< 3 kg';
      case DiaperType.size1:   return '3–5 kg';
      case DiaperType.size2:   return '5–8 kg';
      case DiaperType.size3:   return '8–11 kg';
      case DiaperType.size4:   return '11–14 kg';
      case DiaperType.size5:   return '14–17 kg';
    }
  }

  double get pricePerUnit {
    switch (this) {
      case DiaperType.newborn: return 0.22;
      case DiaperType.size1:   return 0.24;
      case DiaperType.size2:   return 0.26;
      case DiaperType.size3:   return 0.28;
      case DiaperType.size4:   return 0.30;
      case DiaperType.size5:   return 0.32;
    }
  }
}

extension DeliveryFrequencyExt on DeliveryFrequency {
  String get label {
    switch (this) {
      case DeliveryFrequency.weekly:    return 'Weekly';
      case DeliveryFrequency.biweekly:  return 'Bi-weekly';
      case DeliveryFrequency.monthly:   return 'Monthly';
    }
  }

  int get deliveriesPerMonth {
    switch (this) {
      case DeliveryFrequency.weekly:   return 4;
      case DeliveryFrequency.biweekly: return 2;
      case DeliveryFrequency.monthly:  return 1;
    }
  }
}

class Subscription {
  final int? id;
  final int userId;
  final int babyProfileId;
  final DiaperType diaperType;
  final int quantityPerOrder;
  final DeliveryFrequency frequency;
  final bool isActive;
  final DateTime createdAt;

  const Subscription({
    this.id,
    required this.userId,
    required this.babyProfileId,
    required this.diaperType,
    required this.quantityPerOrder,
    required this.frequency,
    this.isActive = true,
    required this.createdAt,
  });

  double get estimatedMonthlyCost {
    return diaperType.pricePerUnit *
        quantityPerOrder *
        frequency.deliveriesPerMonth;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'baby_profile_id': babyProfileId,
        'diaper_type': diaperType.name,
        'quantity_per_order': quantityPerOrder,
        'frequency': frequency.name,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Subscription.fromMap(Map<String, dynamic> m) => Subscription(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        babyProfileId: m['baby_profile_id'] as int,
        diaperType: DiaperType.values.firstWhere(
          (e) => e.name == m['diaper_type'],
          orElse: () => DiaperType.size1,
        ),
        quantityPerOrder: m['quantity_per_order'] as int,
        frequency: DeliveryFrequency.values.firstWhere(
          (e) => e.name == m['frequency'],
          orElse: () => DeliveryFrequency.monthly,
        ),
        isActive: (m['is_active'] as int) == 1,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Subscription copyWith({
    int? id,
    int? userId,
    int? babyProfileId,
    DiaperType? diaperType,
    int? quantityPerOrder,
    DeliveryFrequency? frequency,
    bool? isActive,
    DateTime? createdAt,
  }) =>
      Subscription(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        babyProfileId: babyProfileId ?? this.babyProfileId,
        diaperType: diaperType ?? this.diaperType,
        quantityPerOrder: quantityPerOrder ?? this.quantityPerOrder,
        frequency: frequency ?? this.frequency,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
}