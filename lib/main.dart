import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'core/config/supabase_config.dart';
import 'core/models/app_user.dart';
import 'core/utils/browser_location_stub.dart'
    if (dart.library.html) 'core/utils/browser_location.dart' as browser_location;
import 'core/theme/app_theme.dart';

import 'features/driver/driver_dashboard.dart';
import 'features/traffic_officer/screens/dashboard_screen.dart';
import 'features/traffic_officer/screens/login_screen.dart';
import 'features/traffic_officer/services/auth_service.dart';

import 'core/services/local_database_service.dart';
import 'features/traffic_officer/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabaseService.initialize();
  await SupabaseConfig.initialize();
  await SyncService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
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

  void _initDeepLink() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    if (kIsWeb) {
      final uri = Uri.parse(browser_location.getBrowserLocationHref());
      if (uri.queryParameters.containsKey('token')) {
        _handleDeepLink(uri);
      }
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final token = uri.queryParameters['token'];

    try {
      if (token == null || token.isEmpty) return;
      final user = await AuthService.processBackendSessionToken(token);

      if (user == null) return;

      if (mounted) {
        String route;
        if (user.isDriver) {
          route = '/driver-dashboard';
        } else if (user.isTrafficOfficer) {
          route = '/traffic-dashboard';
        } else {
          // Fallback to auth wrapper for other roles
          route = '/';
        }
        navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
      }
    } catch (e) {
      debugPrint("Auth error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'DriveID',
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/traffic-dashboard': (context) => const DashboardScreen(),
        '/driver-dashboard': (context) => const DriverDashboard(),
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.currentUser;

    setState(() {
      _user = user;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user?.isDriver == true) {
      return const DriverDashboard();
    }

    if (_user?.isTrafficOfficer == true) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}