class BabyProfile {
  final int? id;
  final String name;
  final DateTime birthDate;
  final String stage;

  const BabyProfile({
    this.id,
    required this.name,
    required this.birthDate,
    required this.stage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate.toIso8601String(),
      'stage': stage,
    };
  }

  factory BabyProfile.fromMap(Map<String, dynamic> map) {
    return BabyProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      birthDate: DateTime.parse(map['birth_date'] as String),
      stage: map['stage'] as String,
    );
  }
}
