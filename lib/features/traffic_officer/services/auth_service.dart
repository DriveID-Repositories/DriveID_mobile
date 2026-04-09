import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/app_user.dart';


class AuthService {
  static const String baseUrl = "http://localhost:8088";
  static const String clientId =
      "IIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs0vuF";
  static const String redirectUri = "myapp://callback";
  static const String scope = "openid profile";
  static const String state = "eree2311";
  static const String nonce = "973eieljzng";

  static const String authorizationEndpoint = "http://localhost:8088/authorize";
  static const String tokenEndpoint =
      "http://localhost:8088/v1/esignet/oauth/v2/token";

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Supabase client
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== SUPABASE AUTH (EMAIL/PASSWORD) ====================
  
  // Sign in with email and password (for Drivers and Traffic Officers)
  static Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in with Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Invalid email or password');
      }
      
      // 2. Get user role and profile from your tables
      final appUser = await _getUserWithRole(response.user!);
      
      if (appUser == null) {
        await _supabase.auth.signOut();
        throw Exception('User role not found. Please contact your administrator.');
      }
      
      // 3. Store user info locally
      await _storeUserInfo(appUser);
      
      return appUser;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  // NO SIGN UP FOR DRIVERS - Removed intentionally
  // Drivers must be created by Licensing Officers in the Desktop App

  // ==================== ESIGNET AUTH ====================
  
  static String getAuthorizationUrl() {
    return '$authorizationEndpoint?client_id=$clientId&redirect_uri=$redirectUri&response_type=code&scope=$scope&state=$state&nonce=$nonce';
  }

  static Future<Map<String, dynamic>?> exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'redirect_uri': redirectUri,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store tokens
        await storeTokens(data['access_token'], data['id_token']);
        
        // Get user info from ID token
        final userInfo = JwtDecoder.decode(data['id_token']);
        
        // Sync with Supabase
        await _syncESignetUser(userInfo);
        
        return data;
      } else {
        throw Exception('Failed to exchange code for token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<AppUser?> _syncESignetUser(Map<String, dynamic> userInfo) async {
    try {
      final email = userInfo['email'];
      
      // Check if user exists in drivers table
      final existingDriver = await _supabase
          .from('drivers')
          .select()
          .eq('email', email)
          .maybeSingle();
      
      if (existingDriver != null) {
        // Link auth_user_id if not already linked
        if (existingDriver['auth_user_id'] == null) {
          await _supabase.from('drivers').update({
            'auth_user_id': _supabase.auth.currentUser!.id
          }).eq('id', existingDriver['id']);
        }
        
        return await _getUserWithRole(_supabase.auth.currentUser!);
      }
      
      // Check if user exists in officers table
      final existingOfficer = await _supabase
          .from('officers')
          .select()
          .eq('email', email)
          .maybeSingle();
      
      if (existingOfficer != null) {
        if (existingOfficer['auth_user_id'] == null) {
          await _supabase.from('officers').update({
            'auth_user_id': _supabase.auth.currentUser!.id
          }).eq('id', existingOfficer['id']);
        }
        
        return await _getUserWithRole(_supabase.auth.currentUser!);
      }
      
      throw Exception('User not found in system. Please contact administrator.');
    } catch (e) {
      throw Exception('Failed to sync eSignet user: $e');
    }
  }

  // ==================== USER ROLE & PROFILE ====================
  
  static Future<AppUser?> _getUserWithRole(User authUser) async {
    // Check if user is a driver
    final driver = await _supabase
        .from('drivers')
        .select()
        .eq('auth_user_id', authUser.id)
        .maybeSingle();
    
    if (driver != null) {
      // Get license for this driver
      final license = await _supabase
          .from('licenses')
          .select()
          .eq('driver_id', driver['id'])
          .maybeSingle();
      
      return AppUser(
        id: authUser.id,
        email: authUser.email!,
        role: 'driver',
        userData: driver,
        license: license,
      );
    }
    
    // Check if user is an officer
    final officer = await _supabase
        .from('officers')
        .select()
        .eq('auth_user_id', authUser.id)
        .maybeSingle();
    
    if (officer != null) {
      return AppUser(
        id: authUser.id,
        email: authUser.email!,
        role: officer['role'] ?? 'licensing_officer',
        userData: officer,
      );
    }
    
    return null;
  }
  
  static Future<void> _storeUserInfo(AppUser user) async {
    await _storage.write(key: 'user_id', value: user.id);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.write(key: 'user_role', value: user.role);
    if (user.userData != null) {
      await _storage.write(key: 'user_data', value: json.encode(user.userData));
    }
    if (user.license != null) {
      await _storage.write(key: 'user_license', value: json.encode(user.license));
    }
  }
  
  static Future<AppUser?> getStoredUser() async {
    final userId = await _storage.read(key: 'user_id');
    final userEmail = await _storage.read(key: 'user_email');
    final userRole = await _storage.read(key: 'user_role');
    final userDataStr = await _storage.read(key: 'user_data');
    final userLicenseStr = await _storage.read(key: 'user_license');
    
    if (userId != null && userEmail != null && userRole != null) {
      return AppUser(
        id: userId,
        email: userEmail,
        role: userRole,
        userData: userDataStr != null ? json.decode(userDataStr) : null,
        license: userLicenseStr != null ? json.decode(userLicenseStr) : null,
      );
    }
    return null;
  }
  
  // Get current user (from Supabase session)
  static Future<AppUser?> get currentUser async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      return await _getUserWithRole(session.user);
    }
    return await getStoredUser();
  }
  
  // Stream of auth changes
  static Stream<AppUser?> get userStream {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session != null) {
        return await _getUserWithRole(session.user);
      }
      return null;
    });
  }

  // ==================== TOKEN MANAGEMENT ====================
  
  static Future<void> storeTokens(String accessToken, String idToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'id_token', value: idToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<String?> getIdToken() async {
    return await _storage.read(key: 'id_token');
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final idToken = await getIdToken();
    if (idToken != null) {
      return JwtDecoder.decode(idToken);
    }
    return null;
  }

  // ==================== LOGOUT ====================
  
  static Future<void> logout() async {
    // Sign out from Supabase
    await _supabase.auth.signOut();
    
    // Clear secure storage
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'id_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_data');
    await _storage.delete(key: 'user_license');
  }

  static Future<bool> isLoggedIn() async {
    // Check Supabase session first
    final session = _supabase.auth.currentSession;
    if (session != null) return true;
    
    // Fallback to token check
    final token = await getAccessToken();
    return token != null && !JwtDecoder.isExpired(token);
  }
  
  // ==================== ROLE HELPERS ====================
  
  static Future<String?> getUserRole() async {
    final user = await currentUser;
    return user?.role;
  }
  
  static Future<bool> isDriver() async {
    final role = await getUserRole();
    return role == 'driver';
  }
  
  static Future<bool> isTrafficOfficer() async {
    final role = await getUserRole();
    return role == 'traffic_officer';
  }
  
  static Future<bool> isLicensingOfficer() async {
    final role = await getUserRole();
    return role == 'licensing_officer';
  }
}