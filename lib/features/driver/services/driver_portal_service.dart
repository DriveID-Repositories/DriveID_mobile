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
    this.license,
    this.offenses = const [],
  });

  int get pendingOffenses => offenses.where((o) => o.status == 'pending').length;
  int get resolvedOffenses => offenses.where((o) => o.status != 'pending').length;

  double get outstandingFines {
    return offenses
        .where((o) => o.status == 'pending')
        .map((o) => double.tryParse(o.fine) ?? 0)
        .fold(0, (sum, fine) => sum + fine);
  }

  double get totalFines {
    return offenses
        .map((o) => double.tryParse(o.fine) ?? 0)
        .fold(0, (sum, fine) => sum + fine);
  }
}

class DriverPortalService {
  Future<DriverPortalSnapshot> getSnapshot() async {
    // TODO: Implement fetching driver data
    final user = await AuthService.currentUser;
    if (user == null) throw Exception('Not logged in');

    // For now, return snapshot without license
    return DriverPortalSnapshot(user: user);
  }
}