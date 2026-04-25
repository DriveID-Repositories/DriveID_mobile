class AppUser {
  final String id;
  final String email;
  final String role; // 'driver', 'traffic_officer', 'licensing_officer', 'admin'
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? license;
  
  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.userData,
    this.license,
  });
  
  bool get isDriver => role == 'driver';
  bool get isTrafficOfficer => role == 'traffic_officer';
  bool get isLicensingOfficer => role == 'licensing_officer';
  bool get isAdmin => role == 'admin';
  
  bool get canAccessMobile => isDriver || isTrafficOfficer;
  bool get canAccessDesktop => isLicensingOfficer || isAdmin;
  
  String get displayName {
    if (isDriver && userData != null) {
      return userData!['full_name'] ?? userData!['user_name'] ?? email;
    }
    if ((isTrafficOfficer || isLicensingOfficer) && userData != null) {
      final fullName = userData!['full_name']?.toString().trim();
      if (fullName != null && fullName.isNotEmpty) {
        return fullName;
      }

      final firstName = userData!['first_name']?.toString().trim() ?? '';
      final lastName = userData!['last_name']?.toString().trim() ?? '';
      final combined = '$firstName $lastName'.trim();
      if (combined.isNotEmpty) {
        return combined;
      }

      return userData!['email'] ?? email;
    }
    return email;
  }
  
  String get badgeNumber {
    if (isTrafficOfficer && userData != null) {
      return userData!['employment_number'] ?? 'N/A';
    }
    return 'N/A';
  }
  
  String get station {
    if (isTrafficOfficer && userData != null) {
      return userData!['station'] ?? 'N/A';
    }
    return 'N/A';
  }
  
  String get licenseNumber {
    if (isDriver && license != null) {
      return license!['license_number'] ??
          license!['register_number'] ??
          'Not issued';
    }
    return 'N/A';
  }
  
  String get licenseType {
    if (isDriver && license != null) {
      return license!['license_type'] ??
          license!['license_class'] ??
          'N/A';
    }
    return 'N/A';
  }
  
  DateTime? get licenseExpiryDate {
    if (isDriver && license != null && license!['expiry_date'] != null) {
      return DateTime.tryParse(license!['expiry_date']);
    }
    return null;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'userData': userData,
      'license': license,
    };
  }
}
