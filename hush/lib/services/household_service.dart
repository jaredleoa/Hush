import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/household_model.dart';
import '../models/profile_model.dart';
import '../services/household_member_service.dart';
import 'dart:math' as math;

class HouseholdService {
  final SupabaseClient _supabase = SupabaseConfig.supabaseClient;
  final HouseholdMemberService _memberService = HouseholdMemberService();

  // Create a new household
  Future<Household> createHousehold({required String name, required String userId}) async {
    try {
      // Generate a unique invite code
      final inviteCode = _generateInviteCode();
      
      // Create the household
      final response = await _supabase
        .from('households')
        .insert({
          'name': name,
          'invite_code': inviteCode,
          'created_by': userId,
        })
        .select()
        .single();
      
      final household = Household.fromJson(response);
      
      // Update the user's profile with the household ID
      await _supabase
        .from('profiles')
        .update({'household_id': household.id})
        .eq('id', userId);
      
      // Add user as a household member
      await _memberService.addMemberToHousehold(
        householdId: household.id,
        userId: userId
      );
      
      return household;
    } catch (error) {
      print('Error creating household: $error');
      throw Exception('Failed to create household: ${error.toString()}');
    }
  }

  // Join an existing household using an invite code
  Future<Household> joinHousehold({required String inviteCode, required String userId}) async {
    try {
      // Find the household with the given invite code
      final response = await _supabase
        .from('households')
        .select()
        .eq('invite_code', inviteCode)
        .single();
      
      final household = Household.fromJson(response);
      
      // Update the user's profile with the household ID
      await _supabase
        .from('profiles')
        .update({'household_id': household.id})
        .eq('id', userId);
      
      // Add user as a household member
      await _memberService.addMemberToHousehold(
        householdId: household.id,
        userId: userId
      );
      
      return household;
    } catch (error) {
      print('Error joining household: $error');
      throw Exception('Failed to join household: ${error.toString()}');
    }
  }

  // Get household by ID
  Future<Household> getHouseholdById(String id) async {
    final response = await _supabase
      .from('households')
      .select()
      .eq('id', id)
      .single();
    
    return Household.fromJson(response);
  }

  // Get all members of a household with their status
  Future<List<Map<String, dynamic>>> getHouseholdMembersWithStatus(String householdId) async {
    try {
      return await _memberService.getHouseholdMembersWithProfiles(householdId);
    } catch (error) {
      print('Error getting household members: $error');
      throw Exception('Failed to get household members: ${error.toString()}');
    }
  }
  
  // Get all profiles in a household
  Future<List<Profile>> getHouseholdProfiles(String householdId) async {
    try {
      final response = await _supabase
        .from('profiles')
        .select()
        .eq('household_id', householdId);
      
      return (response as List)
        .map((json) => Profile.fromJson(json))
        .toList();
    } catch (error) {
      print('Error getting household profiles: $error');
      throw Exception('Failed to get household profiles: ${error.toString()}');
    }
  }

  // Leave a household
  Future<void> leaveHousehold(String userId) async {
    try {
      // Get user profile to find their household
      final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
      
      final householdId = profile['household_id'];
      
      if (householdId != null) {
        // Remove from household_members table
        await _memberService.removeMemberFromHousehold(householdId, userId);
      }
      
      // Update profile
      await _supabase
        .from('profiles')
        .update({'household_id': null})
        .eq('id', userId);
    } catch (error) {
      print('Error leaving household: $error');
      throw Exception('Failed to leave household: ${error.toString()}');
    }
  }

  // Generate a random invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random.secure();
    String code = '';
    for (int i = 0; i < 6; i++) {
      final index = random.nextInt(chars.length);
      code += chars[index];
    }
    return code;
  }
  
  // Stream household members for real-time updates
  Stream<List<dynamic>> streamHouseholdMembers(String householdId) {
    return _memberService.streamHouseholdMembers(householdId);
  }
}
