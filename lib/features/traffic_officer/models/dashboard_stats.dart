// ignore: unused_import
import 'package:driveid_app/features/traffic_officer/models/dashboard_stats.dart';
class DashboardStats {
  final int verificationsToday;
  final int offensesRecorded;
  final int totalVerifications;
  final int pendingOffenses;
  final num pendingFinesTotal;

  DashboardStats({
    required this.verificationsToday,
    required this.offensesRecorded,
    required this.totalVerifications,
    required this.pendingOffenses,
    required this.pendingFinesTotal,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      verificationsToday: json['verifications_today'] as int,
      offensesRecorded: json['offenses_recorded'] as int,
      totalVerifications: json['total_verifications'] as int,
      pendingOffenses: json['pending_offenses'] as int,
      pendingFinesTotal: (json['pending_fines_total'] as num?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verifications_today': verificationsToday,
      'offenses_recorded': offensesRecorded,
      'total_verifications': totalVerifications,
      'pending_offenses': pendingOffenses,
      'pending_fines_total': pendingFinesTotal,
    };
  }
}
