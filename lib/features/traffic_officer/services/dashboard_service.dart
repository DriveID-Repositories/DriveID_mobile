import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/license.dart';
import '../../../core/config/supabase_config.dart';
import '../models/dashboard_stats.dart';
import 'sync_service.dart';
import 'auth_service.dart';
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
    'registration_number',
  ];

  bool _isMissingColumnError(Object error, String expectedColumn) {
    if (error is PostgrestException) {
      return (error.code == '42703' ||
          error.code == 'PGRST204' ||
          error.message.contains('Could not find the'));
    }
    return false;
  }

  Future<Map<String, Map<String, String>>> _getDriverInfoById(
    Iterable<dynamic> driverIds,
  ) async {
    final ids =
        driverIds
            .map((id) => id?.toString())
            .where((id) => id != null && id.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

    if (ids.isEmpty) return {};

    // Some deployments don't have all photo columns; try progressively smaller selects.
    // IMPORTANT: `driver_photo_url` is the canonical column in this project.
    const selectCandidates = <String>[
      'id, full_name, driver_photo_url, profile_picture_url, photo_url, avatar_url',
      'id, full_name, driver_photo_url, photo_url, avatar_url',
      'id, full_name, driver_photo_url, photo_url',
      'id, full_name, driver_photo_url',
      'id, full_name',
    ];

    for (final select in selectCandidates) {
      try {
        final response = await _client
            .from('drivers')
            .select(select)
            .inFilter('id', ids)
            .timeout(_requestTimeout, onTimeout: () => []);

        final rows = (response as List<dynamic>?) ?? [];
        final result = <String, Map<String, String>>{};
        for (final row in rows) {
          final id = row['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          final fullName = row['full_name']?.toString() ?? '';
          final photoUrl =
              (row['driver_photo_url'] ??
                      row['profile_picture_url'] ??
                      row['avatar_url'] ??
                      row['photo_url'])
                  ?.toString() ??
              '';
          result[id] = {
            'full_name': fullName,
            'photo_url': photoUrl,
          };
        }
        return result;
      } catch (e) {
        // If missing a selected column, retry with a simpler select.
        if (select.contains('driver_photo_url') &&
                _isMissingColumnError(e, 'driver_photo_url') ||
            select.contains('profile_picture_url') &&
                _isMissingColumnError(e, 'profile_picture_url') ||
            select.contains('avatar_url') &&
                _isMissingColumnError(e, 'avatar_url') ||
            select.contains('photo_url') && _isMissingColumnError(e, 'photo_url')) {
          continue;
        }
        // If RLS blocks `drivers`, we still want licenses to load.
        log('Could not fetch driver info (non-fatal): $e');
        return {};
      }
    }

    return {};
  }

  Future<License?> _buildLicenseFromRow(Map<String, dynamic> row) async {
    final driverInfo = await _getDriverInfoById([row['driver_id']]);
    final enrichedRow = Map<String, dynamic>.from(row);
    final driverId = row['driver_id']?.toString() ?? '';
    // Preserve any pre-enriched owner name when driver lookup isn't available.
    final existingOwner = (enrichedRow['owner_name'] ?? '').toString().trim();
    final resolvedOwner = (driverInfo[driverId]?['full_name'] ?? '').toString().trim();
    if (resolvedOwner.isNotEmpty) {
      enrichedRow['owner_name'] = resolvedOwner;
    } else if (existingOwner.isEmpty) {
      enrichedRow['owner_name'] = '';
    }

    // If backend/row already includes photo info, keep it; otherwise enrich from drivers table.
    final existingPhoto = (enrichedRow['profile_picture_url'] ??
            enrichedRow['photo_url'] ??
            enrichedRow['driver_photo_url'])
        ?.toString()
        .trim();
    final photoUrl = (existingPhoto?.isNotEmpty == true)
        ? existingPhoto
        : driverInfo[driverId]?['photo_url']?.toString().trim();
    if (photoUrl != null && photoUrl.isNotEmpty) {
      // `License.fromJson` understands `profile_picture_url` / `photo_url`
      enrichedRow['profile_picture_url'] = photoUrl;
    }
    return License.fromJson(enrichedRow);
  }

  Future<Map<String, dynamic>?> _getLicenseRow(String licenseNumber) async {
    final normalized = licenseNumber.trim();
    log('Searching for license: $normalized');

    final backendRow = await AuthService.fetchLicenseForVerification(
      normalized,
    );
    if (backendRow != null) {
      log('Found license via backend API: ${backendRow['id']}');
      return backendRow;
    }

    for (final column in _licenseIdentifierColumns) {
      try {
        log('Trying column: $column');
        final response = await _client
            .from('licenses')
            .select()
            .eq(column, normalized)
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
    log('License not found: $normalized');
    return null;
  }

  Future<DashboardStats> getDashboardStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      const pendingStatuses = ['pending', 'Pending'];

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
          .inFilter('status', pendingStatuses)
          .timeout(_requestTimeout, onTimeout: () => []);

      final futurePendingFinesResponse = _client
          .from('offenses')
          .select('fine')
          .inFilter('status', pendingStatuses)
          .timeout(_requestTimeout, onTimeout: () => []);

      final responses = await Future.wait([
        futureVerificationsResponse,
        futureTotalVerificationsResponse,
        futureOffensesResponse,
        futurePendingOffensesResponse,
        futurePendingFinesResponse,
      ]);

      final verificationsList = (responses[0] as List<dynamic>?) ?? [];
      final totalVerificationsList = (responses[1] as List<dynamic>?) ?? [];
      final offensesList = (responses[2] as List<dynamic>?) ?? [];
      final pendingOffensesList = (responses[3] as List<dynamic>?) ?? [];
      final pendingFineRows = (responses[4] as List<dynamic>?) ?? [];

      num pendingFinesTotal = 0;
      for (final row in pendingFineRows) {
        if (row is Map) {
          final fine = row['fine'];
          if (fine is num) {
            pendingFinesTotal += fine;
          } else {
            final fineStr = fine?.toString() ?? '';
            final cleaned = fineStr.replaceAll(RegExp(r'[^0-9.]'), '');
            pendingFinesTotal += num.tryParse(cleaned) ?? 0;
          }
        }
      }

      final stats = DashboardStats(
        verificationsToday: verificationsList.length,
        offensesRecorded: offensesList.length,
        totalVerifications: totalVerificationsList.length,
        pendingOffenses: pendingOffensesList.length,
        pendingFinesTotal: pendingFinesTotal,
      );
      await LocalDatabaseService.cacheDashboardStats(stats.toJson());
      return stats;
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  DashboardStats? getCachedDashboardStats() {
    final cached = LocalDatabaseService.getCachedDashboardStats();
    if (cached == null) return null;
    return DashboardStats.fromJson(cached);
  }

  Future<void> recordVerification(String licenseNumber) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    final payload = {'license_number': licenseNumber, 'verified_at': nowUtc};

    if (!await SyncService().isOnline()) {
      await LocalDatabaseService.savePendingVerification(payload);
      return;
    }

    await recordVerificationDirectly(payload);
  }

  Future<void> recordVerificationDirectly(
    Map<String, dynamic> basePayload,
  ) async {
    final licenseNumber =
        basePayload['license_number'] ??
        basePayload['registration_number'] ??
        basePayload['register_number'];
    if (licenseNumber == null || licenseNumber.toString().isEmpty) return;

    // Build clean payload with ONLY the columns that exist in verifications table
    final payload = {
      'registration_number': licenseNumber.toString().trim(),
      'verified_at':
          basePayload['verified_at'] ??
          DateTime.now().toUtc().toIso8601String(),
    };

    await _client.from('verifications').insert(payload);
  }

  Future<Map<String, dynamic>?> getLatestVerificationForLicense({
    required String licenseNumber,
    DateTime? verifiedAfter,
  }) async {
    for (final column in _verificationIdentifierColumns) {
      try {
        var query = _client
            .from('verifications')
            .select()
            .eq(column, licenseNumber);
        if (verifiedAfter != null) {
          query = query.gte(
            'verified_at',
            verifiedAfter.toUtc().toIso8601String(),
          );
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
      final row =
          await SyncService().isOnline()
              ? await _getLicenseRow(licenseNumber)
              : LocalDatabaseService.getLicense(licenseNumber);

      if (row == null) return false;

      final status = (row['license_status'] ?? row['status'])?.toString() ?? '';
      if (!_isValidStatus(status)) return false;

      final expiryDate = DateTime.tryParse(
        row['expiry_date']?.toString() ?? '',
      );
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
      final row =
          await SyncService().isOnline()
              ? await _getLicenseRow(licenseNumber)
              : LocalDatabaseService.getLicense(licenseNumber);

      if (row != null) {
        if (!await SyncService().isOnline()) {
          return License.fromJson(
            row,
          ); // Offline licenses already have owner_name included from cache
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
      log('getAllLicensesRaw: Starting to fetch licenses from database');
      final response = await _client
          .from('licenses')
          .select()
          .timeout(_requestTimeout, onTimeout: () => []);
      final licenses = (response as List<dynamic>?) ?? [];
      log('getAllLicensesRaw: Fetched ${licenses.length} licenses from server');

      final driverInfo = await _getDriverInfoById(
        licenses.map((license) => license['driver_id']),
      );
      log(
        'getAllLicensesRaw: Fetched driver info for ${driverInfo.length} drivers',
      );

      final result =
          licenses.map((json) {
            final enriched = Map<String, dynamic>.from(
              json as Map<String, dynamic>,
            );
            final driverId = enriched['driver_id']?.toString() ?? '';
            enriched['owner_name'] = driverInfo[driverId]?['full_name'] ?? '';
            final photoUrl = driverInfo[driverId]?['photo_url'];
            if (photoUrl != null && photoUrl.trim().isNotEmpty) {
              enriched['profile_picture_url'] = photoUrl.trim();
            }
            return enriched;
          }).toList();
      log('getAllLicensesRaw: Returning ${result.length} enriched licenses');
      return result;
    } catch (e) {
      log('Error fetching all licenses raw: $e');
      throw Exception('Failed to fetch licenses: $e');
    }
  }

  Future<List<License>> getAllLicenses() async {
    try {
      if (!await SyncService().isOnline()) {
        final cached = LocalDatabaseService.getAllCachedLicenses();
        log(
          'getAllLicenses: Offline mode - Returning ${cached.length} cached licenses',
        );
        return cached.map((json) => License.fromJson(json)).toList();
      }
      final raw = await getAllLicensesRaw();
      log(
        'getAllLicenses: Online mode - Converting ${raw.length} raw licenses to License objects',
      );
      final result = raw.map((json) => License.fromJson(json)).toList();
      log('getAllLicenses: Returning ${result.length} License objects');
      return result;
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
