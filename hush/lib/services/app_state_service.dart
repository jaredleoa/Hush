import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/profile_model.dart';
import '../models/household_member_model.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'household_service.dart';

class AppStateService with ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.supabaseClient;
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final HouseholdService _householdService = HouseholdService();
  
  bool _isLoading = false;
  Profile? _currentProfile;
  String? _currentHouseholdId;
  List<HouseholdMember> _householdMembers = [];
  
  bool get isLoading => _isLoading;
  Profile? get currentProfile => _currentProfile;
  String? get currentHouseholdId => _currentHouseholdId;
  List<HouseholdMember> get householdMembers => _householdMembers;
  
  AppStateService() {
    _initializeState();
  }
  
  Future<void> _initializeState() async {
    _isLoading = true;
    notifyListeners();
    
    // Set up auth state change listener
    _setupAuthListener();
    
    // Load initial data if user is authenticated
    if (_authService.isAuthenticated) {
      await _loadUserData();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  void _setupAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      
      if (event == AuthChangeEvent.signedIn) {
        _handleSignIn();
      } else if (event == AuthChangeEvent.signedOut) {
        _handleSignOut();
      } else if (event == AuthChangeEvent.userUpdated) {
        _loadUserData();
      }
    });
  }
  
  Future<void> _handleSignIn() async {
    _isLoading = true;
    notifyListeners();
    
    await _loadUserData();
    
    _isLoading = false;
    notifyListeners();
  }
  
  void _handleSignOut() {
    _currentProfile = null;
    _currentHouseholdId = null;
    _householdMembers = [];
    
    _clearLocalStorage();
    notifyListeners();
  }
  
  Future<void> _loadUserData() async {
    try {
      // Load user profile
      _currentProfile = await _profileService.getCurrentProfile();
      
      if (_currentProfile != null && _currentProfile!.householdId != null) {
        _currentHouseholdId = _currentProfile!.householdId;
        
        // Start listening to household members
        _setupHouseholdSubscription();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  void _setupHouseholdSubscription() {
    if (_currentHouseholdId == null) return;
    
    _householdService.streamHouseholdMembers(_currentHouseholdId!)
      .listen((members) {
        _householdMembers = members.cast<HouseholdMember>();
        notifyListeners();
      }, onError: (error) {
        print('Error in household stream: $error');
      });
  }
  
  Future<void> _clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  // Public methods for state changes
  
  Future<void> updateSleepStatus(bool isSleeping) async {
    if (_currentProfile == null || _currentHouseholdId == null) return;
    
    try {
      await _householdService.streamHouseholdMembers(_currentHouseholdId!);
      notifyListeners();
    } catch (e) {
      print('Error updating sleep status: $e');
      throw Exception('Failed to update status: ${e.toString()}');
    }
  }
  
  Future<void> updateHomeStatus(bool isAtHome) async {
    if (_currentProfile == null || _currentHouseholdId == null) return;
    
    try {
      await _householdService.streamHouseholdMembers(_currentHouseholdId!);
      notifyListeners();
    } catch (e) {
      print('Error updating home status: $e');
      throw Exception('Failed to update status: ${e.toString()}');
    }
  }
  
  Future<void> refreshHouseholdData() async {
    if (_currentHouseholdId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Re-fetch household data
      await _loadUserData();
    } catch (e) {
      print('Error refreshing household data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
