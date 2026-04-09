class Offense {
  final String id;
  final String name;
  final String registrationNumber;
  final String offenseType;
  final String location;
  final String status;
  final String fine;
  final DateTime createdAt;

  Offense({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.offenseType,
    required this.location,
    required this.status,
    required this.fine,
    required this.createdAt,
  });

  factory Offense.fromJson(Map<String, dynamic> json) {
    return Offense(
      id: json['id'] as String,
      name: json['name'] as String,
      registrationNumber: json['registration_number'] as String,
      offenseType: json['offense_type'] as String,
      location: json['location'] as String,
      status: json['status'] as String,
      fine: json['fine'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'registration_number': registrationNumber,
      'offense_type': offenseType,
      'location': location,
      'status': status,
      'fine': fine,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class OffenseType {
  final String id;
  final String label;
  final String fine;

  const OffenseType({
    required this.id,
    required this.label,
    required this.fine,
  });

  factory OffenseType.fromJson(Map<String, dynamic> json) {
    return OffenseType(
      id: json['id'] as String,
      label: json['label'] as String,
      fine: json['fine'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'fine': fine};
  }
}
