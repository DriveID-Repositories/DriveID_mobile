import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabaseService {
  static const String licensesBox = 'licenses_cache';
  static const String offensesBox = 'pending_offenses';
  static const String verificationsBox = 'pending_verifications';
  static const String offenseTypesBox = 'offense_types_cache';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox(licensesBox);
    await Hive.openBox(offensesBox);
    await Hive.openBox(verificationsBox);
    await Hive.openBox(offenseTypesBox);
  }

  // --- Licenses Cache ---
  static Box get _licenses => Hive.box(licensesBox);
  
  static Future<void> cacheLicenses(List<Map<String, dynamic>> licenses) async {
    final Map<String, dynamic> data = {};
    for (var license in licenses) {
      // Store as JSON string to avoid Hive type adapter issues
      final jsonStr = jsonEncode(license);
      
      if (license['license_number'] != null) {
        data[license['license_number']] = jsonStr;
      }
      if (license['register_number'] != null) {
        data[license['register_number']] = jsonStr;
      }
      if (license['registration_number'] != null) {
        data[license['registration_number']] = jsonStr;
      }
    }
    await _licenses.putAll(data);
  }

  static Map<String, dynamic>? getLicense(String identifier) {
    final data = _licenses.get(identifier);
    if (data != null && data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  static List<Map<String, dynamic>> getAllCachedLicenses() {
    final Map<String, Map<String, dynamic>> uniqueLicenses = {};
    for (var value in _licenses.values) {
      if (value is String) {
        final decoded = jsonDecode(value) as Map<String, dynamic>;
        final id = decoded['id']?.toString();
        if (id != null) {
          uniqueLicenses[id] = decoded;
        }
      }
    }
    return uniqueLicenses.values.toList();
  }
  
  // --- Pending Offenses ---
  static Box get _offenses => Hive.box(offensesBox);

  static Future<void> savePendingOffense(Map<String, dynamic> offense) async {
    await _offenses.add(jsonEncode(offense));
  }

  static List<Map<String, dynamic>> getPendingOffenses() {
    return _offenses.values
        .map((e) => jsonDecode(e.toString()) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> removePendingOffenseAt(int index) async {
    await _offenses.deleteAt(index);
  }

  // --- Pending Verifications ---
  static Box get _verifications => Hive.box(verificationsBox);

  static Future<void> savePendingVerification(Map<String, dynamic> verification) async {
    await _verifications.add(jsonEncode(verification));
  }

  static List<Map<String, dynamic>> getPendingVerifications() {
    return _verifications.values
        .map((e) => jsonDecode(e.toString()) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> removePendingVerificationAt(int index) async {
    await _verifications.deleteAt(index);
  }

  // --- Offense Types Cache ---
  static Box get _offenseTypes => Hive.box(offenseTypesBox);
  
  static Future<void> cacheOffenseTypes(List<Map<String, dynamic>> types) async {
    await _offenseTypes.clear();
    final strings = types.map((t) => jsonEncode(t)).toList();
    await _offenseTypes.addAll(strings);
  }
  
  static List<Map<String, dynamic>> getCachedOffenseTypes() {
    return _offenseTypes.values
        .map((e) => jsonDecode(e.toString()) as Map<String, dynamic>)
        .toList();
  }
}
