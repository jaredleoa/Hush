import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/household_member_model.dart';

class HouseholdMemberService {
  final SupabaseClient _supabase = SupabaseConfig.supabaseClient;

  // Add a user to a household
  Future<HouseholdMember> addMemberToHousehold({
    required String householdId,
    required String userId,
  }) async {
    // Check if already a member
    final existingMember = await _supabase
      .from('household_members')
      .select()
      .eq('household_id', householdId)
      .eq('user_id', userId)
      .maybeSingle();
    
    if (existingMember != null) {
      return HouseholdMember.fromJson(existingMember);
    }
    
    // Add as new member
    final response = await _supabase
      .from('household_members')
      .insert({
        'household_id': householdId,
        'user_id': userId,
        'is_at_home': true,
        'is_sleeping': false,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .select()
      .single();
    
    return HouseholdMember.fromJson(response);
  }

  // Get a member's status
  Future<HouseholdMember?> getMemberStatus(String householdId, String userId) async {
    final response = await _supabase
      .from('household_members')
      .select()
      .eq('household_id', householdId)
      .eq('user_id', userId)
      .maybeSingle();
    
    if (response == null) return null;
    return HouseholdMember.fromJson(response);
  }

  // Update sleep status
  Future<void> updateSleepStatus(String householdId, String userId, bool isSleeping) async {
    try {
      await _supabase
        .from('household_members')
        .update({
          'is_sleeping': isSleeping,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('household_id', householdId)
        .eq('user_id', userId);
    } catch (error) {
      print('Error updating sleep status: $error');
      throw Exception('Failed to update sleep status: ${error.toString()}');
    }
  }

  // Update home status
  Future<void> updateHomeStatus(String householdId, String userId, bool isAtHome) async {
    try {
      await _supabase
        .from('household_members')
        .update({
          'is_at_home': isAtHome,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('household_id', householdId)
        .eq('user_id', userId);
    } catch (error) {
      print('Error updating home status: $error');
      throw Exception('Failed to update home status: ${error.toString()}');
    }
  }

  // Get all members of a household with their status
  Future<List<HouseholdMember>> getHouseholdMembers(String householdId) async {
    try {
      final response = await _supabase
        .from('household_members')
        .select()
        .eq('household_id', householdId);
      
      return (response as List)
        .map((json) => HouseholdMember.fromJson(json))
        .toList();
    } catch (error) {
      print('Error fetching household members: $error');
      throw Exception('Failed to fetch household members: ${error.toString()}');
    }
  }

  // Stream household members for real-time updates
  Stream<List<HouseholdMember>> streamHouseholdMembers(String householdId) {
    return _supabase
      .from('household_members')
      .stream(primaryKey: ['id'])
      .eq('household_id', householdId)
      .map((data) => data.map((json) => HouseholdMember.fromJson(json)).toList());
  }
  
  // Get member details with profile information (join)
  Future<List<Map<String, dynamic>>> getHouseholdMembersWithProfiles(String householdId) async {
    try {
      final response = await _supabase
        .from('household_members')
        .select('''
          *,
          profiles:user_id(id, username, email)
        ''')
        .eq('household_id', householdId);
      
      return response;
    } catch (error) {
      print('Error fetching household members with profiles: $error');
      throw Exception('Failed to fetch household member details: ${error.toString()}');
    }
  }
  
  // Remove a member from a household
  Future<void> removeMemberFromHousehold(String householdId, String userId) async {
    try {
      await _supabase
        .from('household_members')
        .delete()
        .eq('household_id', householdId)
        .eq('user_id', userId);
    } catch (error) {
      print('Error removing household member: $error');
      throw Exception('Failed to remove member from household: ${error.toString()}');
    }
  }
}
