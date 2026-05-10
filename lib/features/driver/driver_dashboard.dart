// lib/features/driver/driver_dashboard.dart
import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import '../../core/theme/app_theme.dart';
import '../traffic_officer/services/auth_service.dart';
import '../traffic_officer/screens/login_screen.dart';
=======
import '../../../core/theme/app_theme.dart';
>>>>>>> Stashed changes
import 'my_license_tab.dart';
import 'history_screen.dart';
import 'settings_tab.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard();

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      MyLicenseTab(),
      HistoryScreen(),
      SettingsTab(),
    ];
  }

<<<<<<< Updated upstream
  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final userId = UserSession().userId;
    if (userId != null) {
      await ActivityService().logActivity(
        userId: userId,
        action: 'logout',
        details: 'User logged out',
      );
    }
    UserSession().clear();
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

=======
>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'My Digital License'
              : (_selectedIndex == 1 ? 'History' : 'Settings'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        foregroundColor: Colors.white,
        // No actions – logout is inside Settings
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.cardDark,
        selectedItemColor: AppTheme.gold,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'My License'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}