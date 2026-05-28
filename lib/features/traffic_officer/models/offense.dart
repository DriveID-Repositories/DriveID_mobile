class Offense {
  final String id;
  final String name;
  final String registrationNumber;
  final String offenseType;
  final String location;
  final String status;
  final dynamic fine;
  final DateTime createdAt;
  final String? offenseTypeId;
  final String? recordedBy;
  final String? licenseClass;

  Offense({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.offenseType,
    required this.location,
    required this.status,
    required this.fine,
    required this.createdAt,
    this.offenseTypeId,
    this.recordedBy,
    this.licenseClass,
  });

  factory Offense.fromJson(Map<String, dynamic> json) {
    return Offense(
      id: (json['id'] ?? 'pending-${DateTime.now().millisecondsSinceEpoch}').toString(),
      name: json['name'] as String,
      registrationNumber:
          (json['registration_number'] ??
                  json['license_number'] ??
                  json['register_number'])
              as String,
      offenseType: json['offense_type'] as String,
      location: json['location'] as String,
      status: json['status'] as String? ?? 'Pending',
      fine: json['fine'] ?? 'TBD',
      createdAt: DateTime.parse(json['created_at'] as String),
      offenseTypeId: json['offense_type_id'] as String?,
      recordedBy: json['recorded_by'] as String?,
      licenseClass: json['license_class'] as String?,
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
      if (offenseTypeId != null) 'offense_type_id': offenseTypeId,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (licenseClass != null) 'license_class': licenseClass,
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
