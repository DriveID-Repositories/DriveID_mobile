class License {
  final String id;
  final String registerNumber;
  final String ownerName;
  final String licenseType;
  final DateTime expiryDate;
  final String status;
  final String? profilePictureUrl;

  License({
    required this.id,
    required this.registerNumber,
    required this.ownerName,
    required this.licenseType,
    required this.expiryDate,
    required this.status,
    this.profilePictureUrl,
  });

  static String _str(dynamic value) => value?.toString() ?? '';

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  factory License.fromJson(Map<String, dynamic> json) {
    final driver = _map(json['drivers']);
    final ownerName = _str(json['owner_name']).isNotEmpty
        ? _str(json['owner_name'])
        : _str(driver?['full_name']);
    final licenseType = _str(json['license_type']).isNotEmpty
        ? _str(json['license_type'])
        : _str(json['license_class']);

    return License(
      id: _str(json['id']),
      registerNumber: _str(
        json['license_number'] ??
            json['register_number'] ??
            json['registration_number'],
      ),
      ownerName: ownerName,
      licenseType: licenseType,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'].toString())
          : DateTime.now(),
      status: _str(json['license_status'] ?? json['status']),
      profilePictureUrl:
          (json['profile_picture_url'] ?? json['photo_url']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'license_number': registerNumber,
      'owner_name': ownerName,
      'license_class': licenseType,
      'expiry_date': expiryDate.toIso8601String(),
      'license_status': status,
      'profile_picture_url': profilePictureUrl,
    };
  }

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isRevoked => status.toLowerCase() == 'revoked';

  String get daysUntilExpiry {
    final today = DateTime.now();
    final difference = expiryDate.difference(today).inDays;

    if (difference < 0) {
      return 'Expired ${difference.abs()} days ago';
    } else if (difference == 0) {
      return 'Expires today';
    } else {
      return 'Expires in $difference days';
    }
  }

  String get statusDisplay {
    if (isRevoked) return 'Revoked';
    if (isExpired) return 'Expired';
    return 'Valid';
  }
}
