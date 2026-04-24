import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/license_qr.dart';
import '../traffic_officer/screens/login_screen.dart';
import '../traffic_officer/services/auth_service.dart';
import 'services/driver_portal_service.dart';
import 'tabs/history_tab.dart';
import 'tabs/license_tab.dart';
import 'tabs/overview_tab.dart';
import 'widgets/driver_dashboard_shared.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final DriverPortalService _service = const DriverPortalService();
  final ValueNotifier<String> _qrData = ValueNotifier<String>('loading');

  DriverPortalSnapshot? _snapshot;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  @override
  void dispose() {
    _qrData.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _loadSnapshot() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _service.getSnapshot();
      _snapshot = snapshot;
      _refreshQr(snapshot);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  void _refreshQr(DriverPortalSnapshot snapshot) {
    final license = snapshot.license;
    if (license == null) {
      _qrData.value = 'driver-license|${DateTime.now().millisecondsSinceEpoch}';
      return;
    }

    _qrData.value = LicenseQrPayload.fromLicense(
      license,
      DateTime.now().toUtc(),
    ).encode();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_snapshot == null) {
      return const Center(child: Text('Failed to load data'));
    }

    switch (_selectedIndex) {
      case 0:
        return OverviewTab(snapshot: _snapshot!);
      case 1:
        return LicenseTab(snapshot: _snapshot!, qrData: _qrData);
      case 2:
        return HistoryTab(snapshot: _snapshot!);
      default:
        return OverviewTab(snapshot: _snapshot!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        color: AppTheme.background,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              DriverTopBar(
                driverName: _snapshot?.user.displayName ?? 'Driver',
                onLogout: _logout,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.gold,
                  onRefresh: _loadSnapshot,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DriverBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}
