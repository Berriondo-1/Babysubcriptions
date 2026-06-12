class DiaperConsumption {
  final int? id;
  final int babyProfileId;
  final DateTime date;
  final int diaperCount;

  const DiaperConsumption({
    this.id,
    required this.babyProfileId,
    required this.date,
    required this.diaperCount,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'baby_profile_id': babyProfileId,
    'date': date.toIso8601String(),
    'diaper_count': diaperCount,
  };

  factory DiaperConsumption.fromMap(Map<String, dynamic> m) =>
      DiaperConsumption(
        id: m['id'] as int?,
        babyProfileId: m['baby_profile_id'] as int,
        date: DateTime.parse(m['date'] as String),
        diaperCount: m['diaper_count'] as int,
      );

  DiaperConsumption copyWith({
    int? id,
    int? babyProfileId,
    DateTime? date,
    int? diaperCount,
  }) => DiaperConsumption(
    id: id ?? this.id,
    babyProfileId: babyProfileId ?? this.babyProfileId,
    date: date ?? this.date,
    diaperCount: diaperCount ?? this.diaperCount,
  );
}
