import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer';
import '../../../core/services/local_database_service.dart';
import 'dashboard_service.dart';
import 'offense_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _connectivity = Connectivity();
  final _dashboardService = DashboardService();
  final _offenseService = OffenseService();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  Future<void> initialize() async {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncPendingData();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    final hasPluginConnection = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    if (hasPluginConnection) {
      return true;
    }
    
    // Fallback if plugin says none but we actually have internet (Windows bug)
    try {
      final request = await HttpClient().getUrl(Uri.parse('https://gpdoptmvqafdfsmjublp.supabase.co'));
      final response = await request.close();
      if (response.statusCode > 0) return true;
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<void> downloadAndCacheData() async {
    if (!await isOnline()) return;
    
    try {
      log('Starting download of data for offline use...');
      // 1. Download all licenses
      final licensesResponse = await _dashboardService.getAllLicensesRaw();
      await LocalDatabaseService.cacheLicenses(licensesResponse);
      
      // 2. Download offense types
      final offenseTypesResponse = await _offenseService.getOffenseTypesRaw();
      await LocalDatabaseService.cacheOffenseTypes(offenseTypesResponse);

      // 3. Cache dashboard stats snapshot
      final stats = await _dashboardService.getDashboardStats();
      await LocalDatabaseService.cacheDashboardStats(stats.toJson());

      log('Successfully cached data for offline use.');
    } catch (e) {
      log('Failed to download cache data: $e');
    }
  }

  Future<void> syncPendingData() async {
    if (_isSyncing || !await isOnline()) return;
    
    _isSyncing = true;
    try {
      log('Starting sync of pending offline data...');
      
      // Sync Verifications
      final verifications = LocalDatabaseService.getPendingVerifications();
      for (int i = verifications.length - 1; i >= 0; i--) {
        final verification = verifications[i];
        try {
          await _dashboardService.recordVerificationDirectly(verification);
          await LocalDatabaseService.removePendingVerificationAt(i);
        } catch (e) {
          log('Failed to sync verification: $e');
        }
      }

      // Sync Offenses
      final offenses = LocalDatabaseService.getPendingOffenses();
      for (int i = offenses.length - 1; i >= 0; i--) {
        final offense = offenses[i];
        try {
          await _offenseService.recordOffenseRecordDirectly(offense);
          await LocalDatabaseService.removePendingOffenseAt(i);
        } catch (e) {
          log('Failed to sync offense: $e');
        }
      }
      log('Sync complete.');
    } finally {
      _isSyncing = false;
    }
  }
}
