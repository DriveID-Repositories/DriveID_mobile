import 'package:driveid_app/features/driver/services/activity_service.dart';
import 'package:driveid_app/features/driver/services/user_session.dart';
import 'package:flutter/material.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  bool _isProcessing = false;

  Future<void> _logout() async {
    setState(() => _isProcessing = true);
    final userId = UserSession().userId;
    if (userId != null) {
      await ActivityService().logActivity(
        action: 'logout',
        details: 'User logged out',
      );
    }
    UserSession().clear();
    // Optional: navigate to a login/splash screen
    // For now, just show a message and pop back
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out'), backgroundColor: Colors.green),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 80, color: Colors.redAccent),
            const SizedBox(height: 24),
            const Text(
              'Are you sure you want to log out?',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isProcessing ? null : _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC124),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: _isProcessing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirm Logout'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}