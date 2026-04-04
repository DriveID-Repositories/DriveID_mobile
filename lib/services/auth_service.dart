import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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
        return data;
      } else {
        throw Exception(
          'Failed to exchange code for token: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

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

  static Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'id_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && !JwtDecoder.isExpired(token);
  }
}
