import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/license.dart';
import '../../../core/config/supabase_config.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  final SupabaseClient _client = SupabaseConfig.client;
  static const Duration _requestTimeout = Duration(seconds: 4);
  static const List<String> _licenseIdentifierColumns = [
    'license_number',
    'register_number',
    'registration_number',
  ];

  Future<Map<String, String>> _getDriverNamesById(
    Iterable<dynamic> driverIds,
  ) async {
    final ids = driverIds
        .map((id) => id?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    if (ids.isEmpty) return {};

    final response = await _client
        .from('drivers')
        .select('id, full_name')
        .inFilter('id', ids)
        .timeout(_requestTimeout, onTimeout: () => []);

    final rows = (response as List<dynamic>?) ?? [];
    return {
      for (final row in rows)
        (row['id']?.toString() ?? ''): row['full_name']?.toString() ?? '',
    };
  }

  Future<License?> _buildLicenseFromRow(Map<String, dynamic> row) async {
    final driverNames = await _getDriverNamesById([row['driver_id']]);
    final enrichedRow = Map<String, dynamic>.from(row);
    enrichedRow['owner_name'] = driverNames[row['driver_id']?.toString()] ?? '';
    return License.fromJson(enrichedRow);
  }

  bool _isMissingColumnError(Object error, String expectedColumn) {
    return error is PostgrestException &&
        error.code == '42703' &&
        error.message.contains(expectedColumn);
  }

  Future<Map<String, dynamic>?> _getLicenseRow(String licenseNumber) async {
    for (final column in _licenseIdentifierColumns) {
      try {
        final response = await _client
            .from('licenses')
            .select()
            .eq(column, licenseNumber)
            .maybeSingle()
            .timeout(_requestTimeout);

        if (response != null) {
          return Map<String, dynamic>.from(response);
        }
      } catch (error) {
        if (_isMissingColumnError(error, column)) {
          continue;
        }
        rethrow;
      }
    }

    return null;
  }

  Future<DashboardStats> getDashboardStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final futureVerificationsResponse = _client
          .from('verifications')
          .select()
          .gte('verified_at', startOfDay.toIso8601String())
          .lt('verified_at', endOfDay.toIso8601String())
          .timeout(_requestTimeout, onTimeout: () => []);

      final futureTotalVerificationsResponse = _client
          .from('verifications')
          .select()
          .timeout(_requestTimeout, onTimeout: () => []);

      final futureOffensesResponse = _client
          .from('offenses')
          .select()
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .timeout(_requestTimeout, onTimeout: () => []);

      final futurePendingOffensesResponse = _client
          .from('offenses')
          .select()
          .eq('status', 'Pending')
          .timeout(_requestTimeout, onTimeout: () => []);

      final responses = await Future.wait([
        futureVerificationsResponse,
        futureTotalVerificationsResponse,
        futureOffensesResponse,
        futurePendingOffensesResponse,
      ]);

      final verificationsList = (responses[0] as List<dynamic>?) ?? [];
      final totalVerificationsList = (responses[1] as List<dynamic>?) ?? [];
      final offensesList = (responses[2] as List<dynamic>?) ?? [];
      final pendingOffensesList = (responses[3] as List<dynamic>?) ?? [];

      return DashboardStats(
        verificationsToday: verificationsList.length,
        offensesRecorded: offensesList.length,
        totalVerifications: totalVerificationsList.length,
        pendingOffenses: pendingOffensesList.length,
      );
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  Future<void> recordVerification(String licenseNumber) async {
    final payloads = [
      {
        'license_number': licenseNumber,
        'verified_at': DateTime.now().toIso8601String(),
      },
      {
        'register_number': licenseNumber,
        'verified_at': DateTime.now().toIso8601String(),
      },
      {
        'registration_number': licenseNumber,
        'verified_at': DateTime.now().toIso8601String(),
      },
    ];

    Object? lastError;
    for (final payload in payloads) {
      try {
        await _client.from('verifications').insert(payload);
        return;
      } catch (error) {
        if (error is PostgrestException && error.code == '42703') {
          lastError = error;
          continue;
        }
        throw Exception('Failed to record verification: $error');
      }
    }

    throw Exception('Failed to record verification: $lastError');
  }

  Future<Map<String, dynamic>?> getLatestVerificationForLicense({
    required String licenseNumber,
    DateTime? verifiedAfter,
  }) async {
    for (final column in _licenseIdentifierColumns) {
      try {
        var query = _client.from('verifications').select().eq(column, licenseNumber);
        if (verifiedAfter != null) {
          query = query.gte('verified_at', verifiedAfter.toIso8601String());
        }

        final response = await query
            .order('verified_at', ascending: false)
            .limit(1)
            .maybeSingle()
            .timeout(_requestTimeout);

        if (response != null) {
          return Map<String, dynamic>.from(response);
        }
      } catch (error) {
        if (_isMissingColumnError(error, column)) {
          continue;
        }
        rethrow;
      }
    }

    return null;
  }

  Future<bool> isValidLicense(String licenseNumber) async {
    try {
      final row = await _getLicenseRow(licenseNumber);
      if (row == null) return false;

      final status = row['status']?.toString().toLowerCase() ?? '';
      if (status != 'active') return false;

      final expiryDate = DateTime.tryParse(row['expiry_date']?.toString() ?? '');
      if (expiryDate == null) return false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return !expiryDate.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  Future<License?> getLicenseDetails(String licenseNumber) async {
    try {
      final response = await _getLicenseRow(licenseNumber);
      if (response != null) {
        return _buildLicenseFromRow(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<License>> getAllLicenses() async {
    try {
      final response = await _client
          .from('licenses')
          .select()
          .timeout(_requestTimeout, onTimeout: () => []);
      final licenses = (response as List<dynamic>?) ?? [];
      final driverNames = await _getDriverNamesById(
        licenses.map((license) => license['driver_id']),
      );

      return licenses.map((json) {
        final enriched = Map<String, dynamic>.from(json as Map<String, dynamic>);
        enriched['owner_name'] = driverNames[enriched['driver_id']?.toString()] ?? '';
        return License.fromJson(enriched);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch licenses: $e');
    }
  }

  Future<bool> verifyAndRecordLicense(String licenseNumber) async {
    try {
      final isValid = await isValidLicense(licenseNumber);
      if (!isValid) {
        return false;
      }

      await recordVerification(licenseNumber);
      return true;
    } catch (e) {
      throw Exception('Failed to verify license: $e');
    }
  }
}
