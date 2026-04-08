import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../models/TrafficOfficerModels/license.dart';
import 'dashboard_service.dart';
import '../../models/TrafficOfficerModels/offense.dart';

class OffenseService {
  final SupabaseClient _client = SupabaseConfig.client;
  final DashboardService _dashboardService = DashboardService();

  // Validate license exists
  Future<License?> validateLicense(String registrationNumber) async {
    try {
      return await _dashboardService.getLicenseDetails(registrationNumber);
    } catch (e) {
      return null;
    }
  }

  // Get all offenses
  Future<List<Offense>> getOffenses() async {
    try {
      final response = await _client
          .from('offenses')
          .select()
          .order('created_at', ascending: false);
      final offenses = (response as List<dynamic>?) ?? [];
      return offenses
          .map((json) => Offense.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch offenses: $e');
    }
  }

  // Get offense types
  Future<List<OffenseType>> getOffenseTypes() async {
    try {
      final response = await _client
          .from('offense_types')
          .select()
          .order('label');

      final offenseTypes = (response as List<dynamic>?) ?? [];

      if (offenseTypes.isEmpty) {
        return [];
      }

      final mapped =
          offenseTypes.map((json) {
            return OffenseType.fromJson(json as Map<String, dynamic>);
          }).toList();

      return mapped;
    } catch (e) {
      return []; // Return empty list instead of throwing
    }
  }

  // Create a new offense
  Future<Offense> createOffense({
    required String name,
    required String registrationNumber,
    required String offenseTypeId,
    required String offenseType,
    required String location,
    required String fine,
  }) async {
    try {
      // Validate: Check if license exists in licenses table
      final license = await _dashboardService.getLicenseDetails(
        registrationNumber,
      );
      if (license == null) {
        throw Exception('License not found - registration number is invalid');
      }

      final response =
          await _client
              .from('offenses')
              .insert({
                'name': name,
                'registration_number': registrationNumber,
                'offense_type_id': offenseTypeId,
                'offense_type': offenseType,
                'location': location,
                'status': 'Pending',
                'fine': fine,
              })
              .select()
              .single();

      return Offense.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create offense: $e');
    }
  }

  // Record offense for a verified license (with validation)
  Future<void> recordOffenseForLicense({
    required String licenseId,
    required String licenseOwnerName,
    required String registrationNumber,
    required String offenseType,
    required String location,
    required String fine,
  }) async {
    try {
      if (registrationNumber.isEmpty) {
        throw Exception('Registration number is required');
      }

      // Validate: Check if license exists and was verified
      final license = await _dashboardService.getLicenseDetails(
        registrationNumber,
      );
      if (license == null) {
        throw Exception('License not found - cannot record offense');
      }

      // Check if this license was recently verified
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final verificationCheck =
          await _client
              .from('verifications')
              .select()
              .eq('registration_number', registrationNumber)
              .gte('verified_at', oneHourAgo.toIso8601String())
              .order('verified_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (verificationCheck == null) {
        throw Exception('License must be verified before recording an offense');
      }

      // Record the offense with only valid Supabase columns
      await _client.from('offenses').insert({
        'name': licenseOwnerName,
        'registration_number': registrationNumber,
        'offense_type': offenseType,
        'location': location,
        'status': 'Pending',
        'fine': fine,
      });
    } catch (e) {
      throw Exception('Failed to record offense: $e');
    }
  }

  // Update offense status
  Future<void> updateOffenseStatus(String offenseId, String status) async {
    try {
      await _client
          .from('offenses')
          .update({'status': status})
          .eq('id', offenseId);
    } catch (e) {
      throw Exception('Failed to update offense status: $e');
    }
  }
}
