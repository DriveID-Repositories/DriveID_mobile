class DashboardStats {
  final int verificationsToday;
  final int offensesRecorded;
  final int totalVerifications;
  final int pendingOffenses;

  DashboardStats({
    required this.verificationsToday,
    required this.offensesRecorded,
    required this.totalVerifications,
    required this.pendingOffenses,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      verificationsToday: json['verifications_today'] as int,
      offensesRecorded: json['offenses_recorded'] as int,
      totalVerifications: json['total_verifications'] as int,
      pendingOffenses: json['pending_offenses'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verifications_today': verificationsToday,
      'offenses_recorded': offensesRecorded,
      'total_verifications': totalVerifications,
      'pending_offenses': pendingOffenses,
    };
  }
}
