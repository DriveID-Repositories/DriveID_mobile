// lib/features/driver/services/activity_service.dart
import 'package:driveid_app/features/driver/services/user_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> logActivity({
    required String action,
    String? details,
  }) async {
    try {
      final driverId = UserSession().driverId;
      if (driverId == null) {
        print('No driver session – cannot log activity');
        return;
      }
      await _supabase.from('user_activities').insert({
        'user_id': driverId,
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserActivities() async {
    final driverId = UserSession().driverId;
    if (driverId == null) throw Exception('Not authenticated');
    final response = await _supabase
        .from('user_activities')
        .select()
        .eq('user_id', driverId)
        .order('created_at', ascending: false);
    return response;
  }
}