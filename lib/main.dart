import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'config/supabase_config.dart';
import 'Screens/dashboard_screen.dart';
import 'Screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

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
              // Navigate to home
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (_) => false);
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
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isLoggedIn! ? const DashboardScreen() : const LoginScreen();
  }
}
