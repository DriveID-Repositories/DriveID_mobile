import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isPasswordLogin = false;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithESignet() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = AuthService.getAuthorizationUrl();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching browser: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _signInWithPassword() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 60,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'DriveID',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Traffic Enforcement System',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 48),

                // Toggle Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                        text: 'eSignet',
                        icon: Icons.security_outlined,
                        isActive: !_isPasswordLogin,
                        onTap: () => setState(() => _isPasswordLogin = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildToggleButton(
                        text: 'Password',
                        icon: Icons.lock_outline,
                        isActive: _isPasswordLogin,
                        onTap: () => setState(() => _isPasswordLogin = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Login Form
                if (!_isPasswordLogin)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithESignet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.security, size: 20, color: Colors.black),
                                SizedBox(width: 12),
                                Text(
                                  'Sign in with eSignet',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                                ),
                              ],
                            ),
                    ),
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter your username',
                          prefixIcon: Icon(Icons.person_outline),
                          labelStyle: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.lock_outline),
                          labelStyle: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Demo Note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Demo mode: Any username/password works',
                                style: TextStyle(fontSize: 12, color: AppTheme.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _signInWithPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, size: 20, color: Colors.black),
                              SizedBox(width: 12),
                              Text(
                                'Login',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.gold : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.gold : AppTheme.cardBorder,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.gold.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.black : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.black : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}