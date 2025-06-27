// lib/services/auth_service.dart (Fixed version)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

class AuthService extends ChangeNotifier {
  SupabaseClient? _supabase;

  // Initialize Supabase client safely
  SupabaseClient get supabase {
    try {
      _supabase ??= SupabaseConfig.supabaseClient;
      return _supabase!;
    } catch (e) {
      debugPrint('Supabase not initialized: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser {
    try {
      return supabase.auth.currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Check if user is logged in
  bool get isAuthenticated {
    try {
      return currentUser != null;
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  // Stream of auth changes
  Stream<AuthState> get authStateChanges {
    try {
      return supabase.auth.onAuthStateChange;
    } catch (e) {
      debugPrint('Error getting auth state changes: $e');
      return Stream.empty();
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: username != null ? {'username': username} : null,
      );
      notifyListeners();
      return res;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return res;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Reset password error: $e');
      rethrow;
    }
  }

  // Update user password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Update password error: $e');
      rethrow;
    }
  }

  // Get user profile data from the profiles table
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    try {
      final response =
          await supabase
              .from('profiles')
              .select()
              .eq('id', currentUser!.id)
              .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }
}
