import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'services/driver_portal_service.dart';
import 'tabs/overview_tab.dart';
import 'tabs/license_tab.dart';
import 'tabs/history_tab.dart';
import 'widgets/driver_dashboard_shared.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final DriverPortalService _service = DriverPortalService();
  DriverPortalSnapshot? _snapshot;
  bool _isLoading = true;
  final ValueNotifier<String> _qrData = ValueNotifier<String>('');

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

  Future<void> _loadSnapshot() async {
    try {
      final snapshot = await _service.getSnapshot();
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_snapshot == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load data')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: DriverTopBar(
            driverName: _snapshot!.user.displayName,
            onLogout: () async {
              // TODO: Implement logout
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'License'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverviewTab(snapshot: _snapshot!),
            LicenseTab(snapshot: _snapshot!, qrData: _qrData),
            HistoryTab(snapshot: _snapshot!),
          ],
        ),
      ),
    );
  }
}