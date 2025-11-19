import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton manager for Supabase client initialization.
class SupabaseClientManager {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://xnxwevgupugearxnraqt.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhueHdldmd1cHVnZWFyeG5yYXF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0ODY5NzcsImV4cCI6MjA3NzA2Mjk3N30.cwCCsM9v7NyoPKt79mcqpCqjvptM9FgYPglgtASg8Yw',
      
      debug: true, // optional: logs Supabase network requests in debug mode
    );
  }

  /// Access Supabase client anywhere in the app
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut for authentication
  static GoTrueClient get auth => client.auth;

  /// Currently logged-in user
  static User? get currentUser => auth.currentUser;
}
