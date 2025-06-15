import 'package:supabase_flutter/supabase_flutter.dart';

// Constants for Supabase configuration
class SupabaseConfig {
  // Replace with your own Supabase URL and anon key
  // TODO: Replace with your Supabase project URL from https://supabase.com/dashboard
  static const String supabaseUrl = 'https://erqireuisnvtaotzkjqw.supabase.co';
  // TODO: Replace with your Supabase anon key from https://supabase.com/dashboard
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVycWlyZXVpc252dGFvdHpranF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MTQ0OTYsImV4cCI6MjA2NTM5MDQ5Nn0.RYMQAdLSjm1q0qGoEqn0tE8Pn-jbUGU8aVg6QqPyeN8';

  // Get the Supabase client instance
  static SupabaseClient get supabaseClient => Supabase.instance.client;
}
