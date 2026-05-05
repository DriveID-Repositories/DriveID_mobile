import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://gpdoptmvqafdfsmjublp.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwZG9wdG12cWFmZGZzbWp1YmxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NDkyMTgsImV4cCI6MjA4OTQyNTIxOH0.qUgZr9-t5Yfwmxy6uQvu1C3Jm6-LiEmLAuB2SDygkyA';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: false, // Disable automatic deep-link handling
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
