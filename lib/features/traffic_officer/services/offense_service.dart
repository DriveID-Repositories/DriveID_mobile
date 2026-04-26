import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../models/license.dart';
import '../models/offense.dart';
import 'dashboard_service.dart';
import 'sync_service.dart';
import 'auth_service.dart';
import '../../../core/services/local_database_service.dart';

class OffenseService {
  final SupabaseClient _client = SupabaseConfig.client;
  final DashboardService _dashboardService = DashboardService();
  static const Duration _requestTimeout = Duration(seconds: 4);
  static const List<String> _identifierColumns = [
    'license_number',
    'registration_number',
    'register_number',
  ];

  bool _isMissingColumnError(Object error, String expectedColumn) {
    return error is PostgrestException &&
        (error.code == '42703' || error.code == 'PGRST204') &&
        error.message.toLowerCase().contains(expectedColumn.toLowerCase());
  }

  String _mapIdentifierKey(Map<String, dynamic> payload) {
    if (payload.containsKey('license_number')) return 'license_number';
    if (payload.containsKey('register_number')) return 'register_number';
    return 'registration_number';
  }

  Future<Map<String, dynamic>> _insertPayloadWithCompatibility(
    Map<String, dynamic> payload,
  ) async {
    final attempts = <Map<String, dynamic>>[
      Map<String, dynamic>.from(payload),
    ];

    if (payload.containsKey('license_number')) {
      attempts.add(
        Map<String, dynamic>.from(payload)
          ..remove('license_number')
          ..['register_number'] = payload['license_number'],
      );
      attempts.add(
        Map<String, dynamic>.from(payload)
          ..remove('license_number')
          ..['registration_number'] = payload['license_number'],
      );
    }

    for (final attempt in attempts) {
      var current = Map<String, dynamic>.from(attempt);

      while (true) {
        try {
          final response = await _client
              .from('offenses')
              .insert(current)
              .select()
              .single()
              .timeout(_requestTimeout);
          return Map<String, dynamic>.from(response);
        } catch (error) {
          if (error is! PostgrestException ||
              (error.code != '42703' && error.code != 'PGRST204')) {
            rethrow;
          }

          const removableColumns = ['fine', 'status', 'location', 'name', 'latitude', 'longitude'];
          final missingColumn = removableColumns.cast<String?>().firstWhere(
            (column) => column != null &&
                error.message.toLowerCase().contains(column.toLowerCase()),
            orElse: () => null,
          );

          if (missingColumn != null && current.containsKey(missingColumn)) {
            current.remove(missingColumn);
            continue;
          }

          final identifierKey = _mapIdentifierKey(current);
          if (error.message.toLowerCase().contains(identifierKey.toLowerCase())) {
            break;
          }

          rethrow;
        }
      }
    }

    throw Exception('Failed to insert offense with available schema');
  }

  Future<List<Offense>> _fetchOffensesByIdentifier(String identifier) async {
    for (final column in _identifierColumns) {
      try {
        final response = await _client
            .from('offenses')
            .select()
            .eq(column, identifier)
            .order('created_at', ascending: false)
            .timeout(_requestTimeout, onTimeout: () => []);

        final offenses = (response as List<dynamic>?) ?? [];
        return offenses
            .map((json) => Offense.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (error) {
        if (_isMissingColumnError(error, column)) {
          continue;
        }
        rethrow;
      }
    }

    return [];
  }

  Future<Offense> _insertOffenseWithSchemaFallback(
    Map<String, dynamic> payload,
  ) async {
    final response = await _insertPayloadWithCompatibility(payload);
    return Offense.fromJson(response);
  }

  Future<void> _insertOffenseRecordWithSchemaFallback(
    Map<String, dynamic> payload,
  ) async {
    await _insertPayloadWithCompatibility(payload);
  }

  Future<License?> validateLicense(String licenseNumber) async {
    try {
      return await _dashboardService.getLicenseDetails(licenseNumber);
    } catch (_) {
      return null;
    }
  }

  Future<List<Offense>> getOffenses() async {
    try {
      if (!await SyncService().isOnline()) {
        final pending = LocalDatabaseService.getPendingOffenses();
        return pending.map((json) => Offense.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      
      final user = await AuthService.currentUser;
      final officerId = user?.id;

      var query = _client
          .from('offenses')
          .select();
      
      if (officerId != null) {
        query = query.eq('officer_id', officerId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .timeout(_requestTimeout, onTimeout: () => []);
      final offenses = (response as List<dynamic>?) ?? [];
      return offenses
          .map((json) => Offense.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch offenses: $e');
    }
  }

  Future<List<Offense>> getOffensesByLicenseNumber(String licenseNumber) async {
    try {
      if (!await SyncService().isOnline()) {
        final pending = LocalDatabaseService.getPendingOffenses();
        final filtered = pending.where((o) => 
            o['license_number'] == licenseNumber ||
            o['registration_number'] == licenseNumber ||
            o['register_number'] == licenseNumber
        ).toList();
        return filtered.map((json) => Offense.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      
      return await _fetchOffensesByIdentifier(licenseNumber);
    } catch (e) {
      throw Exception('Failed to fetch driver offenses: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOffenseTypesRaw() async {
    try {
      final response = await _client
          .from('offense_types')
          .select()
          .order('label')
          .timeout(_requestTimeout, onTimeout: () => []);

      return (response as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<OffenseType>> getOffenseTypes() async {
    if (!await SyncService().isOnline()) {
      final cached = LocalDatabaseService.getCachedOffenseTypes();
      return cached.map((json) => OffenseType.fromJson(json)).toList();
    }
    
    final raw = await getOffenseTypesRaw();
    await LocalDatabaseService.cacheOffenseTypes(raw);
    return raw.map((json) => OffenseType.fromJson(json)).toList();
  }

  Future<Offense> createOffense({
    required String name,
    required String licenseNumber,
    required String offenseTypeId,
    required String offenseType,
    required String location,
    required String fine,
  }) async {
    try {
      final license = await _dashboardService.getLicenseDetails(licenseNumber);
      if (license == null) {
        throw Exception('License not found - license number is invalid');
      }

      final user = await AuthService.currentUser;
      final officerId = user?.id;

      final payload = {
        'name': name,
        'license_number': licenseNumber,
        'offense_type_id': offenseTypeId,
        'offense_type': offenseType,
        'location': location,
        'status': 'Pending',
        'fine': fine,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        if (officerId != null) 'officer_id': officerId,
      };

      if (!await SyncService().isOnline()) {
        await LocalDatabaseService.savePendingOffense(payload);
        return Offense.fromJson(payload);
      }

      return _insertOffenseWithSchemaFallback(payload);
    } catch (e) {
      throw Exception('Failed to create offense: $e');
    }
  }

  Future<void> recordOffenseForLicense({
    required String licenseId,
    required String licenseOwnerName,
    required String licenseNumber,
    required String offenseType,
    required String location,
    required String fine,
  }) async {
    try {
      if (licenseNumber.isEmpty) {
        throw Exception('License number is required');
      }

      final license = await _dashboardService.getLicenseDetails(licenseNumber);
      if (license == null) {
        throw Exception('License not found - cannot record offense');
      }

      final user = await AuthService.currentUser;
      final officerId = user?.id;

      final payload = {
        'name': licenseOwnerName,
        'license_number': licenseNumber,
        'offense_type': offenseType,
        'location': location,
        'status': 'Pending',
        'fine': fine,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        if (officerId != null) 'officer_id': officerId,
      };

      if (!await SyncService().isOnline()) {
        await LocalDatabaseService.savePendingOffense(payload);
        return;
      }

      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final verificationCheck = await _dashboardService
          .getLatestVerificationForLicense(
            licenseNumber: licenseNumber,
            verifiedAfter: oneHourAgo,
          );

      if (verificationCheck == null) {
        throw Exception('License must be verified before recording an offense');
      }

      await _insertOffenseRecordWithSchemaFallback(payload).timeout(_requestTimeout);
    } catch (e) {
      throw Exception('Failed to record offense: $e');
    }
  }

  Future<void> recordOffenseRecordDirectly(Map<String, dynamic> payload) async {
    await _insertOffenseRecordWithSchemaFallback(payload);
  }

  Future<void> updateOffenseStatus(String offenseId, String status) async {
    try {
      await _client.from('offenses').update({'status': status}).eq('id', offenseId);
    } catch (e) {
      throw Exception('Failed to update offense status: $e');
    }
  }
}
