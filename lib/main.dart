import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'core/config/supabase_config.dart';
import 'core/models/app_user.dart';
import 'core/theme/app_theme.dart';
import 'features/driver/driver_dashboard.dart';
import 'features/traffic_officer/screens/dashboard_screen.dart';
import 'features/traffic_officer/screens/login_screen.dart';
import 'features/traffic_officer/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  late StreamSubscription<Uri> _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLink();
  }

  @override
  void dispose() {
    _linkSubscription.cancel();
    super.dispose();
  }

  void _initDeepLink() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      await _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'myapp' && uri.host == 'callback') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        try {
          final tokenData = await AuthService.exchangeCodeForToken(code);
          if (tokenData != null) {
            final accessToken = tokenData['access_token'];
            final idToken = tokenData['id_token'];
            if (accessToken != null && idToken != null) {
              await AuthService.storeTokens(accessToken, idToken);
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              }
            } else {
              _showError('Invalid token response');
            }
          } else {
            _showError('Failed to exchange code for token');
          }
        } catch (e) {
          _showError('Error during authentication: $e');
        }
      } else {
        _showError('Authorization code not found');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/traffic-dashboard': (context) => const DashboardScreen(),
        '/driver-dashboard': (context) => DriverDashboard(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AppUser? _user;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final user = await AuthService.currentUser;
      if (user != null && !user.canAccessMobile) {
        await AuthService.logout();
        if (!mounted) return;
        setState(() {
          _user = null;
          _isChecking = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _isChecking = false;
      });
    } catch (_) {
      await AuthService.logout();
      if (!mounted) return;
      setState(() {
        _user = null;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user?.isDriver == true) {
      return DriverDashboard();
    }
    if (_user?.isTrafficOfficer == true) {
      return const DashboardScreen();
    }
    return const LoginScreen();
  }
}
