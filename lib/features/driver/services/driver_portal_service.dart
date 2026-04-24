import '../../../core/config/supabase_config.dart';
import '../../../core/models/app_user.dart';
import '../../traffic_officer/models/license.dart';
import '../../traffic_officer/models/offense.dart';
import '../../traffic_officer/services/auth_service.dart';

class DriverPortalSnapshot {
  final AppUser user;
  final License? license;
  final List<Offense> offenses;

  const DriverPortalSnapshot({
    required this.user,
    required this.license,
    required this.offenses,
  });

  int get pendingOffenses =>
      offenses.where((offense) => !_isResolved(offense.status)).length;

  int get resolvedOffenses =>
      offenses.where((offense) => _isResolved(offense.status)).length;

  double get outstandingFines => offenses
      .where((offense) => !_isResolved(offense.status))
      .fold(0, (sum, offense) => sum + _parseCurrency(offense.fine));

  double get totalFines =>
      offenses.fold(0, (sum, offense) => sum + _parseCurrency(offense.fine));

  static bool _isResolved(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'paid' ||
        normalized == 'resolved' ||
        normalized == 'cleared';
  }

  static double _parseCurrency(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(sanitized) ?? 0;
  }
}

class DriverPortalService {
  const DriverPortalService();

  Future<DriverPortalSnapshot> getSnapshot() async {
    final user = await AuthService.currentUser;
    if (user == null || !user.isDriver) {
      throw Exception('Driver account not found.');
    }

    final client = SupabaseConfig.client;
    final driverId = user.userData?['id']?.toString();

    Map<String, dynamic>? licenseJson = user.license;

    if (licenseJson == null && driverId != null && driverId.isNotEmpty) {
      licenseJson = await client
          .from('licenses')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();
    }

    final license = licenseJson != null ? License.fromJson(licenseJson) : null;
    final licenseNumber = license?.registerNumber ?? user.licenseNumber;

    List<Offense> offenses = [];
    if (licenseNumber.isNotEmpty && licenseNumber != 'Not issued') {
      try {
        final response = await client
            .from('offenses')
            .select()
            .eq('license_number', licenseNumber)
            .order('created_at', ascending: false);

        offenses = (response as List<dynamic>)
            .map((json) => Offense.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final response = await client
            .from('offenses')
            .select()
            .eq('registration_number', licenseNumber)
            .order('created_at', ascending: false);

        offenses = (response as List<dynamic>)
            .map((json) => Offense.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    return DriverPortalSnapshot(
      user: user,
      license: license,
      offenses: offenses,
    );
  }
}
