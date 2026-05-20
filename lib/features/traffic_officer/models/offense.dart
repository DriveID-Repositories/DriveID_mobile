class Offense {
  final String id;
  final String name;
  final String licenseNumber;
  final String offenseType;
  final String location;
  final String status;
  final String fine;
  final DateTime createdAt;

  Offense({
    required this.id,
    required this.name,
    required this.licenseNumber,
    required this.offenseType,
    required this.location,
    required this.status,
    required this.fine,
    required this.createdAt,
  });

  factory Offense.fromJson(Map<String, dynamic> json) {
    return Offense(
      id: (json['id'] ?? 'pending-${DateTime.now().millisecondsSinceEpoch}').toString(),
      name: json['name'] as String,
      licenseNumber:
          (json['license_number'] ??
                  json['registration_number'] ??
                  json['register_number'])
              as String,
      offenseType: json['offense_type'] as String,
      location: json['location'] as String,
      status: json['status'] as String,
      fine:
          (json['fine'] ??
                  json['amount'] ??
                  json['penalty_amount'] ??
                  json['penalty'] ??
                  'TBD')
              .toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'license_number': licenseNumber,
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
    String? fineVal;

    // common column names first
    if (json.containsKey('fine') && json['fine'] != null) {
      fineVal = json['fine'].toString();
    } else if (json.containsKey('amount') && json['amount'] != null) {
      fineVal = json['amount'].toString();
    } else if (json.containsKey('penalty_amount') && json['penalty_amount'] != null) {
      fineVal = json['penalty_amount'].toString();
    } else if (json.containsKey('penalty') && json['penalty'] != null) {
      fineVal = json['penalty'].toString();
    }

    // fallback: pick any column that contains 'fine' (case-insensitive)
    if (fineVal == null) {
      for (final key in json.keys) {
        if (key.toLowerCase().contains('fine') && json[key] != null) {
          fineVal = json[key].toString();
          break;
        }
      }
    }

    fineVal ??= 'TBD';

    return OffenseType(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Unknown Offense',
      fine: fineVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'fine': fine};
  }
}
