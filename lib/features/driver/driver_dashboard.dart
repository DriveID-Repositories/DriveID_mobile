// lib/screens/driver_dashboard.dart
import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/traffic_officer/services/auth_service.dart';
import '../../../features/traffic_officer/screens/login_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.currentUser;
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  String get _welcomeName => _user?.displayName ?? 'Driver';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: AppTheme.cardDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.drive_eta,
              size: 80,
              color: AppTheme.gold,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, $_welcomeName!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your driver portal is under construction',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
