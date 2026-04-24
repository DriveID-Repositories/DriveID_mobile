class DriverLicense {
  final String id;
  final String registerNumber;
  final String ownerName;        // maps to 'owner_name' in DB
  final String licenseType;      // 'license_type'
  final DateTime issueDate;      // 'issue_date'
  final DateTime? expiryDate;    // 'expiry_date'
  final String status;           // 'active', 'expired', etc.
  final String? photoUrl;
  final String? driverId;

  DriverLicense({
    required this.id,
    required this.registerNumber,
    required this.ownerName,
    required this.licenseType,
    required this.issueDate,
    this.expiryDate,
    required this.status,
    this.photoUrl,
    this.driverId,
  });

  factory DriverLicense.fromJson(Map<String, dynamic> json) {
    return DriverLicense(
      id: json['id'].toString(),
      registerNumber: json['register_number'] ?? '',
      ownerName: json['owner_name'] ?? json['full_name'] ?? '',
      licenseType: json['license_type'] ?? '',
      issueDate: DateTime.parse(json['issue_date']),
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      status: json['status'] ?? 'active',
      photoUrl: json['photo_url'],
      driverId: json['driver_id']?.toString(),
    );
  }
}