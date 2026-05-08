// lib/features/driver/screens/settings_tab.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import 'profile_screen.dart';
import 'change_password_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, ValueChanged<Locale>? onLocaleChanged});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() => _notificationsEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Account'),
        _buildMenuItem(
          icon: Icons.person_outline,
          title: 'View Profile',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
        ),
        _buildMenuItem(
          icon: Icons.lock_outline,
          title: 'Change Password',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
        ),
        const Divider(color: Colors.white24, height: 32),

        _buildSectionHeader('Preferences'),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_none, color: AppTheme.gold),
          title: const Text('Notifications', style: TextStyle(color: Colors.white)),
          value: _notificationsEnabled,
          onChanged: _saveNotifications,
          activeColor: AppTheme.gold,
        ),
        _buildMenuItem(
          icon: Icons.language,
          title: 'Language',
          trailing: const Text('English', style: TextStyle(color: AppTheme.textSecondary)),
          onTap: () => _showLanguageDialog(),
        ),
        const Divider(color: Colors.white24, height: 32),

        _buildSectionHeader('About'),
        _buildMenuItem(
          icon: Icons.info_outline,
          title: 'App Version',
          trailing: const Text('1.0.0', style: TextStyle(color: AppTheme.textSecondary)),
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => _showInfoDialog('Privacy Policy', 'Your data is managed by the government registry.'),
        ),
        _buildMenuItem(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          onTap: () => _showInfoDialog('Terms of Service', 'Use of this app is subject to government regulations.'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Color color = AppTheme.gold}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.gold),
      title: Text(title, style: TextStyle(color: color, fontSize: 15)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Select Language', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('Chichewa', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppTheme.gold)),
          ),
        ],
      ),
    );
  }
}