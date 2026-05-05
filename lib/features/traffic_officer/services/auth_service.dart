import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_user.dart';

class AuthService {
  // =========================
  // CONFIG
  // =========================
  static String get localHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get authorizationEndpoint =>
      'http://$localHost:3000/authorize';

  static String get backendVerifyUrl =>
      'http://10.0.2.2:54321/functions/v1/esignet-login';

  static String get redirectUri =>
      kIsWeb ? 'http://localhost:8080/callback' : 'myapp://callback';

  // ✅ FIXED CLIENT ID (YOUR REGISTERED ONE)
  static const String clientId =
      "IIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhNWtJ";

  // =========================
  // STORAGE + SUPABASE
  // =========================
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final SupabaseClient _supabase = Supabase.instance.client;

  // =========================
  // RANDOM HELPERS
  // =========================
  static String _random(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static String generateState() => _random(16);
  static String generateNonce() => _random(16);
  static String generateVerifier() => _random(64);

  static String generateChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // =========================
  // AUTH URL
  // =========================
  static Future<Map<String, String>> getAuthorizationUrlWithParams() async {
    final state = generateState();
    final nonce = generateNonce();
    final verifier = generateVerifier();
    final challenge = generateChallenge(verifier);

    await _storage.write(key: 'state', value: state);
    await _storage.write(key: 'verifier', value: verifier);

    final url = Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        // ✅ FIX APPLIED HERE
        'client_id': clientId,

        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid',
        'state': state,
        'nonce': nonce,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    ).toString();

    return {'url': url, 'state': state};
  }

  // =========================
  // CALLBACK LOGIN
  // =========================
  static Future<AppUser?> processEsignetCallback({
    required String code,
    required String state,
    required String redirectUri,
  }) async {
    final res = await http.post(
      Uri.parse(backendVerifyUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'code': code,
        'state': state,
        'redirect_uri': redirectUri,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Login failed');
    }

    final data = json.decode(res.body);
    final userJson = data['user'];

    if (userJson == null) {
      throw Exception('Invalid backend response');
    }

    final user = AppUser.fromJson(userJson);
    await _store(user);

    return user;
  }

  // =========================
  // UIN LOGIN
  // =========================
  static Future<AppUser?> verifyUin(String uin) async {
    final res = await http.post(
      Uri.parse(backendVerifyUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'uin': uin}),
    );

    if (res.statusCode != 200) {
      throw Exception('UIN failed');
    }

    final data = json.decode(res.body);

    final user = AppUser.fromJson(data['user']);
    await _store(user);

    return user;
  }

  // =========================
  // EMAIL LOGIN
  // =========================
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

  // =========================
  // CURRENT USER
  // =========================
  static Future<AppUser?> get currentUser async {
    final session = _supabase.auth.currentSession;

    if (session != null) {
      return _getUser(session.user);
    }

    return getStoredUser();
  }

  // =========================
  // STREAM (FIXED)
  // =========================
  static Stream<AppUser?> get userStream {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return await _getUser(user);
    });
  }

  // =========================
  // ROLE MAPPING
  // =========================
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

    return null;
  }

  // =========================
  // STORAGE
  // =========================
  static Future<void> _store(AppUser user) async {
    await _storage.write(key: 'user_id', value: user.id);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.write(key: 'user_role', value: user.role);
  }

  static Future<AppUser?> getStoredUser() async {
    final id = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'user_email');
    final role = await _storage.read(key: 'user_role');

    if (id == null) return null;

    return AppUser(id: id, email: email ?? '', role: role ?? '');
  }

  // =========================
  // LOGOUT
  // =========================
  static Future<void> logout() async {
    await _supabase.auth.signOut();
    await _storage.deleteAll();
  }
}