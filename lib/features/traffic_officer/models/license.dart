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

  // ================= SAFE STRING HELPER =================
  static String _str(dynamic value) {
    return value?.toString() ?? '';
  }

  // ================= FROM JSON =================
  factory License.fromJson(Map<String, dynamic> json) {
    return License(
      id: _str(json['id']),
      registerNumber: _str(json['register_number']),
      ownerName: _str(json['owner_name']),
      licenseType: _str(json['license_type']),
      expiryDate:
          json['expiry_date'] != null
              ? DateTime.parse(json['expiry_date'].toString())
              : DateTime.now(),
      status: _str(json['status']),
      profilePictureUrl: json['profile_picture_url'] as String?,
    );
  }

  // ================= TO JSON (OPTIONAL BUT IMPORTANT) =================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'register_number': registerNumber,
      'owner_name': ownerName,
      'license_type': licenseType,
      'expiry_date': expiryDate.toIso8601String(),
      'status': status,
      'profile_picture_url': profilePictureUrl,
    };
  }

  // ================= BUSINESS LOGIC =================
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
