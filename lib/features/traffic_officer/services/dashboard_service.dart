import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/license.dart';
import '../../../core/config/supabase_config.dart';
import '../models/dashboard_stats.dart';
import 'sync_service.dart';
import '../../../core/services/local_database_service.dart';

class DashboardService {
  final SupabaseClient _client = SupabaseConfig.client;
  static const Duration _requestTimeout = Duration(seconds: 4);
  static const List<String> _licenseIdentifierColumns = [
    'license_number',
    'register_number',
    'registration_number',
  ];
  static const List<String> _verificationIdentifierColumns = [
    'license_number',
    'registration_number',
    'register_number',
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
    if (error is PostgrestException) {
      return (error.code == '42703' || error.code == 'PGRST204' || error.message.contains('Could not find the'));
    }
    return false;
  }

  Future<Map<String, dynamic>?> _getLicenseRow(String licenseNumber) async {
    log('Searching for license: $licenseNumber');
    for (final column in _licenseIdentifierColumns) {
      try {
        log('Trying column: $column');
        final response = await _client
            .from('licenses')
            .select()
            .eq(column, licenseNumber)
            .maybeSingle()
            .timeout(_requestTimeout);

        if (response != null) {
          log('Found license using column $column: ${response['id']}');
          return Map<String, dynamic>.from(response);
        } else {
          log('No result for column $column');
        }
      } catch (error) {
        log('Error with column $column: $error');
        if (_isMissingColumnError(error, column)) {
          continue;
        }
        rethrow;
      }
    }
    log('License not found: $licenseNumber');
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
          .gte('verified_at', startOfDay.toUtc().toIso8601String())
          .lt('verified_at', endOfDay.toUtc().toIso8601String())
          .timeout(_requestTimeout, onTimeout: () => []);

      final futureTotalVerificationsResponse = _client
          .from('verifications')
          .select()
          .timeout(_requestTimeout, onTimeout: () => []);

      final futureOffensesResponse = _client
          .from('offenses')
          .select()
          .gte('created_at', startOfDay.toUtc().toIso8601String())
          .lt('created_at', endOfDay.toUtc().toIso8601String())
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
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    if (!await SyncService().isOnline()) {
      await LocalDatabaseService.savePendingVerification({
        'license_number': licenseNumber,
        'verified_at': nowUtc,
      });
      return;
    }

    final payloads = [
      {
        'registration_number': licenseNumber,
        'verified_at': nowUtc,
      },
      {
        'register_number': licenseNumber,
        'verified_at': nowUtc,
      },
      {
        'license_number': licenseNumber,
        'verified_at': nowUtc,
      },
    ];

    Object? lastError;
    for (final payload in payloads) {
      try {
        await _client.from('verifications').insert(payload);
        return;
      } catch (error) {
        if (error is PostgrestException && (error.code == '42703' || error.code == 'PGRST204' || error.message.contains('Could not find the'))) {
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
    for (final column in _verificationIdentifierColumns) {
      try {
        var query = _client.from('verifications').select().eq(column, licenseNumber);
        if (verifiedAfter != null) {
          query = query.gte('verified_at', verifiedAfter.toUtc().toIso8601String());
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

  bool _isValidStatus(String status) {
    final lower = status.trim().toLowerCase();
    return lower == 'active' || lower == 'valid';
  }

  Future<bool> isValidLicense(String licenseNumber) async {
    try {
      final row = await SyncService().isOnline() 
          ? await _getLicenseRow(licenseNumber)
          : LocalDatabaseService.getLicense(licenseNumber);
          
      if (row == null) return false;

      final status = (row['license_status'] ?? row['status'])?.toString() ?? '';
      if (!_isValidStatus(status)) return false;

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
      final row = await SyncService().isOnline() 
          ? await _getLicenseRow(licenseNumber)
          : LocalDatabaseService.getLicense(licenseNumber);
          
      if (row != null) {
        if (!await SyncService().isOnline()) {
           return License.fromJson(row); // Offline licenses already have owner_name included from cache
        }
        return _buildLicenseFromRow(row);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllLicensesRaw() async {
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
        return enriched;
      }).toList();
    } catch (e) {
      log('Error fetching all licenses raw: $e');
      throw Exception('Failed to fetch licenses: $e');
    }
  }

  Future<List<License>> getAllLicenses() async {
    try {
      final raw = await getAllLicensesRaw();
      return raw.map((json) => License.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching all licenses: $e');
      throw Exception('Failed to fetch licenses: $e');
    }
  }

  Future<bool> verifyAndRecordLicense(String licenseNumber) async {
    try {
      final isValid = await isValidLicense(licenseNumber);
      
      // We still want to record the verification attempt regardless of whether the license is valid or not
      // This ensures the dashboard stats reflect all activity accurately
      try {
        await recordVerification(licenseNumber);
      } catch (e) {
        // We log it but don't fail the verification process if recording fails
        // due to missing license rows (foreign key constraint)
        log('Could not record verification: $e');
      }

      return isValid;
    } catch (e) {
      throw Exception('Failed to verify license: $e');
    }
  }
}
