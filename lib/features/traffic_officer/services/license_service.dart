import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_license.dart';   // YOUR model, not mobile_scanner's

class LicenseService {
  final SupabaseClient _supabase;

  LicenseService([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  Future<DriverLicense> fetchLicenseByRegisterNumber(String registerNumber) async {
    try {
      final response = await _supabase
          .from('licenses')
          .select()
          .eq('register_number', registerNumber)
          .maybeSingle();
      if (response == null) throw Exception('No license found');
      return DriverLicense.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch license: $e');
    }
  }

  Future<DriverLicense> fetchLicenseForDriver(String driverId) async {
    try {
      final response = await _supabase
          .from('licenses')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();
      if (response == null) throw Exception('No license found');
      return DriverLicense.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch license: $e');
    }
  }

  Future<DriverLicense> fetchLicenseByOwnerEmail(String email) async {
    try {
      final response = await _supabase
          .from('licenses')
          .select()
          .eq('owner_email', email)
          .maybeSingle();
      if (response == null) throw Exception('No license found');
      return DriverLicense.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch license: $e');
    }
  }
}