import 'dart:convert';

import '../../features/traffic_officer/models/license.dart';

class LicenseQrPayload {
  static const String type = 'driveid_license';
  static const int version = 1;
  static const Duration maxAge = Duration(minutes: 10);

  final String licenseId;
  final String registerNumber;
  final DateTime issuedAt;
  final DateTime expiryDate;

  const LicenseQrPayload({
    required this.licenseId,
    required this.registerNumber,
    required this.issuedAt,
    required this.expiryDate,
  });

  factory LicenseQrPayload.fromLicense(License license, DateTime issuedAt) {
    return LicenseQrPayload(
      licenseId: license.id,
      registerNumber: license.registerNumber,
      issuedAt: issuedAt.toUtc(),
      expiryDate: license.expiryDate.toUtc(),
    );
  }

  factory LicenseQrPayload.fromJsonMap(Map<String, dynamic> json) {
    return LicenseQrPayload(
      licenseId: json['licenseId']?.toString() ?? '',
      registerNumber: json['registerNumber']?.toString() ?? '',
      issuedAt: DateTime.parse(json['issuedAt'].toString()).toUtc(),
      expiryDate: DateTime.parse(json['expiryDate'].toString()).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'version': version,
      'licenseId': licenseId,
      'registerNumber': registerNumber,
      'issuedAt': issuedAt.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());

  static LicenseQrParseResult parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return const LicenseQrParseResult.invalid('QR code is empty.');
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        return const LicenseQrParseResult.invalid('QR code format is invalid.');
      }
      if (decoded['type']?.toString() != type) {
        return const LicenseQrParseResult.invalid('QR code type is not supported.');
      }
      if (decoded['version'] != version) {
        return const LicenseQrParseResult.invalid('QR code version is not supported.');
      }

      final registerNumber = decoded['registerNumber']?.toString() ?? '';
      final licenseId = decoded['licenseId']?.toString() ?? '';
      final issuedAtRaw = decoded['issuedAt']?.toString();
      final expiryRaw = decoded['expiryDate']?.toString();

      final issuedAt = issuedAtRaw == null ? null : DateTime.tryParse(issuedAtRaw);
      final expiryDate = expiryRaw == null ? null : DateTime.tryParse(expiryRaw);

      if (registerNumber.isEmpty || licenseId.isEmpty || issuedAt == null || expiryDate == null) {
        return const LicenseQrParseResult.invalid('QR code is missing required fields.');
      }

      return LicenseQrParseResult.valid(
        LicenseQrPayload(
          licenseId: licenseId,
          registerNumber: registerNumber,
          issuedAt: issuedAt.toUtc(),
          expiryDate: expiryDate.toUtc(),
        ),
      );
    } catch (_) {
      // Check for Driver App format: "REGISTER_NUMBER|TIMESTAMP"
      if (value.contains('|')) {
        final parts = value.split('|');
        if (parts.isNotEmpty && _isLegacyRegisterNumber(parts[0])) {
          return LicenseQrParseResult.legacy(parts[0]);
        }
      }
      
      if (_isLegacyRegisterNumber(value)) {
        return LicenseQrParseResult.legacy(value);
      }
      return const LicenseQrParseResult.invalid('QR code could not be read.');
    }
  }

  bool get isFresh => DateTime.now().toUtc().difference(issuedAt) <= maxAge;

  static bool _isLegacyRegisterNumber(String value) {
    final normalized = value.trim().toUpperCase();
    // Matches DLV followed by a 4-digit year and 5-digit sequence (9 digits total)
    final pattern = RegExp(r'^DLV\d{9}$');
    return pattern.hasMatch(normalized);
  }
}

class LicenseQrParseResult {
  final LicenseQrPayload? payload;
  final String? legacyRegisterNumber;
  final String? error;

  const LicenseQrParseResult._({
    this.payload,
    this.legacyRegisterNumber,
    this.error,
  });

  const LicenseQrParseResult.valid(LicenseQrPayload payload)
      : this._(payload: payload);

  const LicenseQrParseResult.legacy(String registerNumber)
      : this._(legacyRegisterNumber: registerNumber);

  const LicenseQrParseResult.invalid(String error)
      : this._(error: error);

  bool get isValid => payload != null || legacyRegisterNumber != null;
  bool get isStructured => payload != null;
  String get registerNumber => payload?.registerNumber ?? legacyRegisterNumber ?? '';
}
