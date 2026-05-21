import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Log activity for the currently authenticated user.
  Future<void> logActivity({
    required String action,
    String? details,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('No authenticated user – cannot log activity');
        return;
      }
      await _supabase.from('user_activities').insert({
        'user_id': userId,
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }

  /// Fetch all activities for the currently authenticated user.
  Future<List<Map<String, dynamic>>> fetchUserActivities() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final response = await _supabase
        .from('user_activities')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response;
  }
}