import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_stats.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/services/local_database_service.dart';
import '../services/sync_service.dart';
import 'verify_screen.dart';
import 'offenses_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int index = 0;
  final DashboardService _dashboardService = DashboardService();
  DashboardStats? _stats;
  bool _isLoading = true;
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final isOnline = await SyncService().isOnline();
      if (!isOnline) {
        if (!mounted) return;
        setState(() {
          _stats = DashboardStats(
            verificationsToday: LocalDatabaseService.getPendingVerifications().length,
            offensesRecorded: LocalDatabaseService.getPendingOffenses().length,
            totalVerifications: 0,
            pendingOffenses: LocalDatabaseService.getPendingOffenses().length,
          );
          _isLoading = false;
          _lastRefresh = DateTime.now();
        });
        return;
      }

      // We are online, refresh cache in background
      SyncService().downloadAndCacheData();

      final stats = await _dashboardService.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoading = false;
        _lastRefresh = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) return;
          if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VerifyScreen()),
            );
          } else if (i == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OffensesScreen()),
            );
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Traffic Dashboard",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Verify licenses & manage offenses",
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<List<ConnectivityResult>>(
                    stream: Connectivity().onConnectivityChanged,
                    builder: (context, snapshot) {
                      final isOffline = snapshot.hasData && 
                          snapshot.data!.isNotEmpty && 
                          snapshot.data!.first == ConnectivityResult.none;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOffline ? AppTheme.error.withAlpha(30) : AppTheme.success.withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOffline ? AppTheme.error.withAlpha(100) : AppTheme.success.withAlpha(100),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOffline ? Icons.wifi_off : Icons.wifi,
                              size: 14,
                              color: isOffline ? AppTheme.error : AppTheme.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOffline ? "Offline Mode" : "Online",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOffline ? AppTheme.error : AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Row 1: Verifications Today & Offenses Recorded
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: "Verifications Today",
                      value: _isLoading ? "..." : (_stats?.verificationsToday.toString() ?? "0"),
                      icon: Icons.check_circle_outline,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildStatCard(
                      title: "Offenses Recorded",
                      value: _isLoading ? "..." : (_stats?.offensesRecorded.toString() ?? "0"),
                      icon: Icons.warning_amber_outlined,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Row 2: Fines Pending & Total Checks
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: "Fines Pending",
                      value: _isLoading ? "..." : (_stats?.pendingOffenses.toString() ?? "0"),
                      icon: Icons.attach_money,
                      color: AppTheme.error,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildStatCard(
                      title: "Total Checks",
                      value: _isLoading ? "..." : (_stats?.totalVerifications.toString() ?? "0"),
                      icon: Icons.search_outlined,
                      color: AppTheme.gold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Activity Section
              const Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              // Recent Activity Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.gold.withAlpha(77),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withAlpha(38),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withAlpha(38),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.gold.withAlpha(77),
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: AppTheme.gold,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Ready to verify?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Scan a license QR code or search manually",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VerifyScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Verify",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withAlpha(102),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(38),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(31),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}