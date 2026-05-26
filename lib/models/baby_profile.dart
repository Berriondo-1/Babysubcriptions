class BabyProfile {
  final int? id;
  final String name;
  final DateTime birthDate;
  final double weightKg;
  final String? photoPath;

  const BabyProfile({
    this.id,
    required this.name,
    required this.birthDate,
    required this.weightKg,
    this.photoPath,
  });

  String get recommendedDiaperSize {
    if (weightKg < 3.0) return 'Newborn (< 3 kg)';
    if (weightKg < 5.0) return 'Size 1 (3–5 kg)';
    if (weightKg < 8.0) return 'Size 2 (5–8 kg)';
    if (weightKg < 11.0) return 'Size 3 (8–11 kg)';
    if (weightKg < 14.0) return 'Size 4 (11–14 kg)';
    if (weightKg < 17.0) return 'Size 5 (14–17 kg)';
    return 'Size 6 (> 17 kg)';
  }

  String get sizeShort {
    if (weightKg < 3.0) return 'NB';
    if (weightKg < 5.0) return 'S1';
    if (weightKg < 8.0) return 'S2';
    if (weightKg < 11.0) return 'S3';
    if (weightKg < 14.0) return 'S4';
    if (weightKg < 17.0) return 'S5';
    return 'S6';
  }

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
  }

  String get ageLabel {
    final months = ageInMonths;
    if (months < 1) return 'Recién nacido';
    if (months < 12) return '$months ${months == 1 ? 'mes' : 'meses'}';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years ${years == 1 ? 'año' : 'años'}';
    return '$years ${years == 1 ? 'año' : 'años'} y $rem ${rem == 1 ? 'mes' : 'meses'}';
  }

  BabyProfile copyWith({
    int? id,
    String? name,
    DateTime? birthDate,
    double? weightKg,
    String? photoPath,
  }) {
    return BabyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      weightKg: weightKg ?? this.weightKg,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate.toIso8601String(),
      'weight_kg': weightKg,
      'photo_path': photoPath,
    };
  }

  factory BabyProfile.fromMap(Map<String, dynamic> map) {
    return BabyProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      weightKg: (map['weight_kg'] as num).toDouble(),
      photoPath: map['photo_path'] as String?,
    );
  }
}
