import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/TrafficOfficerModels/license.dart';
import '../../config/supabase_config.dart';
import '../../models/TrafficOfficerModels/dashboard_stats.dart';

class DashboardService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Get verifications today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final verificationsResponse = await _client
          .from('verifications')
          .select()
          .gte('verified_at', startOfDay.toIso8601String())
          .lt('verified_at', endOfDay.toIso8601String());
      final verificationsList = (verificationsResponse as List<dynamic>?) ?? [];
      final verificationsToday = verificationsList.length;

      // Get total verifications
      final totalVerificationsResponse =
          await _client.from('verifications').select();
      final totalVerificationsList =
          (totalVerificationsResponse as List<dynamic>?) ?? [];
      final totalVerifications = totalVerificationsList.length;

      // Get offenses recorded today
      final offensesResponse = await _client
          .from('offenses')
          .select()
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());
      final offensesList = (offensesResponse as List<dynamic>?) ?? [];
      final offensesRecorded = offensesList.length;

      // Get pending offenses
      final pendingOffensesResponse = await _client
          .from('offenses')
          .select()
          .eq('status', 'Pending');
      final pendingOffensesList =
          (pendingOffensesResponse as List<dynamic>?) ?? [];
      final pendingOffenses = pendingOffensesList.length;

      return DashboardStats(
        verificationsToday: verificationsToday,
        offensesRecorded: offensesRecorded,
        totalVerifications: totalVerifications,
        pendingOffenses: pendingOffenses,
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
      final response =
          await _client
              .from('licenses')
              .select()
              .eq('register_number', registrationNumber)
              .maybeSingle();

      if (response != null) {
        return License.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all licenses for search
  Future<List<License>> getAllLicenses() async {
    try {
      final response = await _client.from('licenses').select();
      final licenses = (response as List<dynamic>?) ?? [];
      return licenses
          .map((json) => License.fromJson(json as Map<String, dynamic>))
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
