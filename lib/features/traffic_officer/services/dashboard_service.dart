import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/dashboard_stats.dart';
import '../models/license.dart'; 
class DashboardService {
  final SupabaseClient _client = SupabaseConfig.client;
  static const Duration _requestTimeout = Duration(seconds: 4);

  Future<Map<String, String>> _getDriverNamesById(
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

  // Get dashboard statistics
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

  // Record a verification
  Future<void> recordVerification(String registrationNumber) async {
    try {
      await _client.from('verifications').insert({
        'registration_number': registrationNumber,
        'verified_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to record verification: $e');
    }
  }

  // Check if license is valid
  Future<bool> isValidLicense(String registrationNumber) async {
    try {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final response =
          await _client
              .from('licenses')
              .select('id, register_number, status, expiry_date')
              .eq('register_number', registrationNumber)
              .eq('status', 'active')
              .gte('expiry_date', today)
              .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get full license details
  Future<License?> getLicenseDetails(String registrationNumber) async {
    try {
      final response = await _client
          .from('licenses')
          .select()
          .eq('register_number', registrationNumber)
          .maybeSingle()
          .timeout(_requestTimeout);

      if (response != null) {
        return _buildLicenseFromRow(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all licenses for search
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

      return licenses
          .map((json) {
            final enriched = Map<String, dynamic>.from(json as Map<String, dynamic>);
            enriched['owner_name'] =
                driverNames[enriched['driver_id']?.toString()] ?? '';
            return License.fromJson(enriched);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch licenses: $e');
    }
  }

  // Verify and record license (with validation)
  Future<bool> verifyAndRecordLicense(String registrationNumber) async {
    try {
      // Check if license is valid
      final isValid = await isValidLicense(registrationNumber);
      if (!isValid) {
        return false; // License not found or inactive
      }

      // Record the verification
      await recordVerification(registrationNumber);
      return true; // Success
    } catch (e) {
      throw Exception('Failed to verify license: $e');
    }
  }
}
