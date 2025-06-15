import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase = SupabaseConfig.supabaseClient;

  // Get the current user's profile
  Future<Profile?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    final response = await _supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
    
    if (response == null) return null;
    return Profile.fromJson(response);
  }

  // Get profile by user ID
  Future<Profile?> getProfileById(String userId) async {
    final response = await _supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();
    
    if (response == null) return null;
    return Profile.fromJson(response);
  }

  // Create or update profile
  Future<Profile> upsertProfile({
    required String userId,
    String? username,
    String? householdId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Check if profile already exists
    final existingProfile = await _supabase
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();
    
    final Map<String, dynamic> profileData = {
      'id': userId,
      'email': user.email!,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (username != null) profileData['username'] = username;
    if (householdId != null) profileData['household_id'] = householdId;
    
    if (existingProfile == null) {
      // Create new profile
      profileData['created_at'] = DateTime.now().toIso8601String();
      final response = await _supabase
        .from('profiles')
        .insert(profileData)
        .select()
        .single();
      
      return Profile.fromJson(response);
    } else {
      // Update existing profile
      final response = await _supabase
        .from('profiles')
        .update(profileData)
        .eq('id', userId)
        .select()
        .single();
      
      return Profile.fromJson(response);
    }
  }

  // Update user's sleep status
  Future<void> updateSleepStatus(String userId, bool isSleeping) async {
    await _supabase
      .from('profiles')
      .update({
        'is_sleeping': isSleeping,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', userId);
  }

  // Update user's home status
  Future<void> updateHomeStatus(String userId, bool isHome) async {
    await _supabase
      .from('profiles')
      .update({
        'is_home': isHome,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', userId);
  }
}
