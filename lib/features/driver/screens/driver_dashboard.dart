// lib/screens/driver_dashboard.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/traffic_officer/services/auth_service.dart';
import '../../../features/traffic_officer/screens/login_screen.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

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
            const Text(
              'Welcome Driver!',
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