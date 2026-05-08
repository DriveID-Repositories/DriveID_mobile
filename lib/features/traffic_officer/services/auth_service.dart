import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_user.dart';

class AuthService {
  static String get localHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get backendBaseUrl => 'http://$localHost:4000';
  static String get authorizationEndpoint => '$backendBaseUrl/login';
  static String get meEndpoint => '$backendBaseUrl/me';

  static String get redirectUri => 'myapp://callback';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _appTokenKey = 'app_jwt_token';

  static Uri getLoginUri() => Uri.parse(authorizationEndpoint);

  static Future<AppUser?> processBackendSessionToken(String token) async {
    await _storage.write(key: _appTokenKey, value: token);
    return refreshProfileFromBackend();
  }

  static Future<AppUser?> refreshProfileFromBackend() async {
    final token = await _storage.read(key: _appTokenKey);
    if (token == null) return null;

    final res = await http.get(
      Uri.parse(meEndpoint),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      await _storage.delete(key: _appTokenKey);
      await _clearStoredUser();
      return null;
    }

    final data = json.decode(res.body) as Map<String, dynamic>;
    final user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    await _store(user);
    return user;
  }

  static Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user == null) return null;

    return await _getUser(res.user!);
  }

  static Future<AppUser?> get currentUser async {
    final session = _supabase.auth.currentSession;

    if (session != null) {
      return _getUser(session.user);
    }

    final stored = await getStoredUser();
    if (stored != null) {
      return stored;
    }

    return refreshProfileFromBackend();
  }

  static Future<String?> get appToken async {
    return _storage.read(key: _appTokenKey);
  }

  static Stream<AppUser?> get userStream {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return await _getUser(user);
    });
  }

  static Future<AppUser?> _getUser(User user) async {
    final driver = await _supabase
        .from('drivers')
        .select()
        .eq('auth_user_id', user.id)
        .maybeSingle();

    if (driver != null) {
      return AppUser(
        id: user.id,
        email: user.email ?? '',
        role: 'driver',
        userData: driver,
      );
    }

    final officer = await _supabase
        .from('officers')
        .select()
        .eq('auth_user_id', user.id)
        .maybeSingle();

    if (officer != null) {
      return AppUser(
        id: user.id,
        email: user.email ?? '',
        role: officer['role'] ?? 'traffic_officer',
        userData: officer,
      );
    }

    return getStoredUser();
  }

  static Future<void> _store(AppUser user) async {
    await _storage.write(key: 'user_id', value: user.id);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.write(key: 'user_role', value: user.role);
    await _storage.write(key: 'user_json', value: json.encode(user.toJson()));
  }

  static Future<AppUser?> getStoredUser() async {
    final userJson = await _storage.read(key: 'user_json');
    if (userJson != null) {
      final decoded = json.decode(userJson) as Map<String, dynamic>;
      return AppUser.fromJson(decoded);
    }

    final id = await _storage.read(key: 'user_id');
    if (id == null) return null;

    final email = await _storage.read(key: 'user_email');
    final role = await _storage.read(key: 'user_role');
    return AppUser(id: id, email: email ?? '', role: role ?? '');
  }

  static Future<void> _clearStoredUser() async {
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_json');
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
    await _clearStoredUser();
    await _storage.delete(key: _appTokenKey);
  }
}