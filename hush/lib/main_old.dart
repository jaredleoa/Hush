import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GentleNotificationService.initialize();
  runApp(HushApp());
}

class HushApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[50],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}

// Privacy Settings Model
class PrivacySettings {
  bool shareDetailedStatus;
  bool shareLocation;
  bool shareActiveHours;
  bool allowQuietHours;

  PrivacySettings({
    this.shareDetailedStatus = false, // Default to private
    this.shareLocation = false,
    this.shareActiveHours = true, // This is core to the app's purpose
    this.allowQuietHours = true,
  });

  Map<String, dynamic> toJson() => {
    'shareDetailedStatus': shareDetailedStatus,
    'shareLocation': shareLocation,
    'shareActiveHours': shareActiveHours,
    'allowQuietHours': allowQuietHours,
  };

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      PrivacySettings(
        shareDetailedStatus: json['shareDetailedStatus'] ?? false,
        shareLocation: json['shareLocation'] ?? false,
        shareActiveHours: json['shareActiveHours'] ?? true,
        allowQuietHours: json['allowQuietHours'] ?? true,
      );
}

// User Status Model - Minimal info focused on noise consideration
class UserStatus {
  final String name;
  final bool isQuietTime; // Core feature: do they need quiet?
  final bool isHome; // Only if user chose to share location
  final String? generalActivity; // Vague: "resting", "active", "away"
  final bool shareDetails; // Whether they're sharing any details at all

  UserStatus({
    required this.name,
    required this.isQuietTime,
    this.isHome = true,
    this.generalActivity,
    this.shareDetails = true,
  });
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasHousehold = prefs.getBool('hasHousehold') ?? false;

    await Future.delayed(Duration(seconds: 1));

    if (hasHousehold) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HushHomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HouseholdSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6366F1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volume_off_rounded, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Hush',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Respectful living',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class HouseholdSetupScreen extends StatefulWidget {
  @override
  _HouseholdSetupScreenState createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen> {
  final _joinCodeController = TextEditingController();
  final _householdNameController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    _householdNameController.dispose();
    super.dispose();
  }

  void _joinHousehold() async {
    if (_joinCodeController.text.length != 6) {
      _showError('Please enter a 6-character code');
      return;
    }

    setState(() => _isJoining = true);
    await Future.delayed(Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasHousehold', true);
    await prefs.setString('householdName', 'The Apartment');
    await prefs.setString('householdId', 'generated-id');
    await prefs.setString('inviteCode', _joinCodeController.text);

    setState(() => _isJoining = false);

    // Show privacy onboarding before entering main app
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PrivacyOnboardingScreen()),
    );
  }

  void _createHousehold() async {
    if (_householdNameController.text.isEmpty) {
      _showError('Please enter a household name');
      return;
    }

    setState(() => _isCreating = true);
    await Future.delayed(Duration(seconds: 2));

    final inviteCode = _generateInviteCode();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasHousehold', true);
    await prefs.setString('householdName', _householdNameController.text);
    await prefs.setString('householdId', 'generated-id');
    await prefs.setString('inviteCode', inviteCode);
    await prefs.setBool('isHouseholdCreator', true);

    setState(() => _isCreating = false);
    _showInviteCode(inviteCode);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 6; i++) {
      final index = (random * (i + 1)) % chars.length;
      code += chars[index.toInt()];
    }
    return code;
  }

  void _showInviteCode(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Household Created!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Share this code with your housemates:'),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                      letterSpacing: 8,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Code copied to clipboard'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: Icon(Icons.copy),
                  label: Text('Copy Code'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrivacyOnboardingScreen(),
                    ),
                  );
                },
                child: Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text(
                  'Set Up Your\nHousehold',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Create a household focused on respectful living',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 40),

                // Join Household Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.people,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Join Household',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Enter the 6-character invite code',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _joinCodeController,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 6,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'XXXXXX',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: EdgeInsets.all(16),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Z0-9]'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isJoining ? null : _joinHousehold,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF6366F1),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isJoining
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF6366F1),
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Join Household',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 30),

                // OR divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                SizedBox(height: 30),

                // Create Household Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFA574), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF6B9D).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.add_home,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Create New',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Start your own household',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _householdNameController,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                            decoration: InputDecoration(
                              hintText: 'e.g., The Apartment',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 18,
                              ),
                              prefixIcon: Icon(
                                Icons.home,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : _createHousehold,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFFFF6B9D),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isCreating
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFFFF6B9D),
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Create Household',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Privacy note
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Privacy-first design. You control what you share.',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// NEW: Privacy onboarding screen
class PrivacyOnboardingScreen extends StatefulWidget {
  @override
  _PrivacyOnboardingScreenState createState() =>
      _PrivacyOnboardingScreenState();
}

class _PrivacyOnboardingScreenState extends State<PrivacyOnboardingScreen> {
  PrivacySettings _settings = PrivacySettings();

  Future<void> _saveSettingsAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    // Save privacy settings
    final settingsJson = _settings.toJson();
    for (String key in settingsJson.keys) {
      await prefs.setBool(key, settingsJson[key]);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HushHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Icon(Icons.privacy_tip, size: 60, color: Color(0xFF6366F1)),
              SizedBox(height: 20),
              Text(
                'Your Privacy\nMatters',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                  height: 1.2,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Choose what you\'re comfortable sharing with your housemates.',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 40),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPrivacyOption(
                        title: 'Quiet Time Status',
                        subtitle:
                            'Let others know when you need quiet (core feature)',
                        icon: Icons.volume_off,
                        value: _settings.allowQuietHours,
                        onChanged:
                            (val) =>
                                setState(() => _settings.allowQuietHours = val),
                        required: true,
                      ),

                      _buildPrivacyOption(
                        title: 'General Activity',
                        subtitle:
                            'Share if you\'re "resting", "active", or "away" (no details)',
                        icon: Icons.timeline,
                        value: _settings.shareActiveHours,
                        onChanged:
                            (val) => setState(
                              () => _settings.shareActiveHours = val,
                            ),
                      ),

                      _buildPrivacyOption(
                        title: 'Location Status',
                        subtitle: 'Share whether you\'re home or away',
                        icon: Icons.location_on,
                        value: _settings.shareLocation,
                        onChanged:
                            (val) =>
                                setState(() => _settings.shareLocation = val),
                      ),

                      _buildPrivacyOption(
                        title: 'Detailed Status',
                        subtitle: 'Share specific activities and timing',
                        icon: Icons.info_outline,
                        value: _settings.shareDetailedStatus,
                        onChanged:
                            (val) => setState(
                              () => _settings.shareDetailedStatus = val,
                            ),
                      ),

                      SizedBox(height: 20),

                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shield,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Privacy Promise',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• You can change these settings anytime\n'
                              '• Data is only shared within your household\n'
                              '• No tracking when you go "invisible"\n'
                              '• You can pause sharing temporarily',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettingsAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save & Continue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool required = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF6366F1), size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (required) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CORE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged:
                required ? null : onChanged, // Core feature can't be disabled
            activeColor: Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}

class HushHomePage extends StatefulWidget {
  @override
  _HushHomePageState createState() => _HushHomePageState();
}

class _HushHomePageState extends State<HushHomePage> {
  bool _isQuietTime = false;
  bool _isInvisible = false;
  String _householdName = 'Loading...';
  PrivacySettings _privacySettings = PrivacySettings();

  // Sample data - in real app this would come from backend
  final List<UserStatus> _housemates = [
    UserStatus(name: 'You', isQuietTime: false),
    UserStatus(name: 'Alex', isQuietTime: true, generalActivity: 'resting'),
    UserStatus(
      name: 'Jordan',
      isQuietTime: false,
      isHome: false,
      generalActivity: 'away',
    ),
    UserStatus(
      name: 'Sam',
      isQuietTime: false,
      shareDetails: false,
    ), // This user is "invisible"
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _householdName = prefs.getString('householdName') ?? 'My Household';
      _privacySettings = PrivacySettings(
        shareDetailedStatus: prefs.getBool('shareDetailedStatus') ?? false,
        shareLocation: prefs.getBool('shareLocation') ?? false,
        shareActiveHours: prefs.getBool('shareActiveHours') ?? true,
        allowQuietHours: prefs.getBool('allowQuietHours') ?? true,
      );
    });
  }

  void _toggleQuietTime() {
    setState(() {
      _isQuietTime = !_isQuietTime;
      _housemates[0] = UserStatus(
        name: 'You',
        isQuietTime: _isQuietTime,
        isHome: _housemates[0].isHome,
        generalActivity: _isQuietTime ? 'resting' : 'active',
        shareDetails: !_isInvisible,
      );
    });
    HapticFeedback.lightImpact();
  }

  void _toggleInvisible() {
    setState(() {
      _isInvisible = !_isInvisible;
      _housemates[0] = UserStatus(
        name: 'You',
        isQuietTime: _isQuietTime,
        isHome: _housemates[0].isHome,
        generalActivity:
            _isInvisible ? null : (_isQuietTime ? 'resting' : 'active'),
        shareDetails: !_isInvisible,
      );
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(children: [_buildHeader(), _buildHousematesList()]),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              _isQuietTime
                  ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
                  : [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: (_isQuietTime ? Color(0xFF6366F1) : Color(0xFF10B981))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 50),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _householdName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white, size: 28),
                    onPressed: () => _showSettingsMenu(),
                  ),
                ],
              ),
              SizedBox(height: 30),

              if (_isInvisible) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Invisible Mode',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],

              Text(
                _isInvisible ? 'Private Mode' : 'Household Status',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 30),

              // Main status button
              GestureDetector(
                onTap: _toggleQuietTime,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          _isQuietTime
                              ? [Color(0xFF818CF8), Color(0xFF6366F1)]
                              : [Color(0xFF34D399), Color(0xFF10B981)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isQuietTime
                                ? Color(0xFF6366F1)
                                : Color(0xFF10B981))
                            .withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isQuietTime
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        _isQuietTime ? 'Quiet Time' : 'Available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isQuietTime ? 'Please be quiet' : 'Normal volume OK',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 25),

              // Privacy toggle
              GestureDetector(
                onTap: _toggleInvisible,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_isInvisible ? 0.3 : 0.2),
                    borderRadius: BorderRadius.circular(25),
                    border:
                        _isInvisible
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isInvisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _isInvisible ? 'Go Visible' : 'Go Invisible',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHousematesList() {
    // Only show housemates who are sharing details
    final visibleHousemates = _housemates.where((h) => h.shareDetails).toList();
    final hiddenCount = _housemates.length - visibleHousemates.length;

    return Expanded(
      child: Column(
        children: [
          if (hiddenCount > 0) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_off,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$hiddenCount housemate${hiddenCount > 1 ? 's' : ''} in private mode',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: visibleHousemates.length,
              itemBuilder: (context, index) {
                final person = visibleHousemates[index];
                return _buildHousemateTile(person);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHousemateTile(UserStatus person) {
    final needsQuiet = person.isQuietTime;
    final isAway = !person.isHome && _privacySettings.shareLocation;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors:
                    needsQuiet
                        ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
                        : [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              needsQuiet ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      person.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    if (isAway) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Away',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  needsQuiet
                      ? 'Needs quiet time'
                      : 'Available for normal activity',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (_privacySettings.shareActiveHours &&
                    person.generalActivity != null) ...[
                  SizedBox(height: 2),
                  Text(
                    'Currently: ${person.generalActivity}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  needsQuiet
                      ? Color(0xFF6366F1).withOpacity(0.1)
                      : Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              needsQuiet ? 'Quiet' : 'Available',
              style: TextStyle(
                color: needsQuiet ? Color(0xFF4F46E5) : Color(0xFF059669),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.privacy_tip),
                  title: Text('Privacy Settings'),
                  subtitle: Text('Control what you share'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivacySettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.vpn_key),
                  title: Text('Invite Code'),
                  subtitle: FutureBuilder<String>(
                    future: SharedPreferences.getInstance().then(
                      (prefs) => prefs.getString('inviteCode') ?? 'N/A',
                    ),
                    builder:
                        (context, snapshot) =>
                            Text(snapshot.data ?? 'Loading...'),
                  ),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final code = prefs.getString('inviteCode') ?? '';
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invite code copied!')),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About Hush'),
                  subtitle: Text('Privacy-first household coordination'),
                  onTap: () => _showAboutDialog(),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text(
                    'Leave Household',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: Text('Reset and return to setup'),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('Leave Household?'),
                            content: Text(
                              'This will clear all your data and return you to setup.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Leave',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );

                    if (confirmed == true) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HouseholdSetupScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.volume_off_rounded, color: Color(0xFF6366F1)),
                SizedBox(width: 8),
                Text('About Hush'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hush helps housemates coordinate quiet times respectfully.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Privacy Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• Minimal data sharing by default\n'
                  '• "Invisible mode" for complete privacy\n'
                  '• No tracking of specific activities\n'
                  '• You control all sharing settings\n'
                  '• Data stays within your household',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Got it'),
              ),
            ],
          ),
    );
  }
}

// NEW: Privacy settings screen
class PrivacySettingsScreen extends StatefulWidget {
  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  PrivacySettings _settings = PrivacySettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _settings = PrivacySettings(
        shareDetailedStatus: prefs.getBool('shareDetailedStatus') ?? false,
        shareLocation: prefs.getBool('shareLocation') ?? false,
        shareActiveHours: prefs.getBool('shareActiveHours') ?? true,
        allowQuietHours: prefs.getBool('allowQuietHours') ?? true,
      );
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = _settings.toJson();
    for (String key in settingsJson.keys) {
      await prefs.setBool(key, settingsJson[key]);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Privacy settings saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Privacy Settings'),
        backgroundColor: Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control Your Sharing',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Choose what information you\'re comfortable sharing with your housemates.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 30),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPrivacyOption(
                      title: 'Quiet Time Status',
                      subtitle:
                          'Core feature: Let others know when you need quiet',
                      icon: Icons.volume_off,
                      value: _settings.allowQuietHours,
                      onChanged:
                          (val) =>
                              setState(() => _settings.allowQuietHours = val),
                      required: true,
                    ),

                    _buildPrivacyOption(
                      title: 'General Activity',
                      subtitle:
                          'Share vague status like "resting", "active", or "away"',
                      icon: Icons.timeline,
                      value: _settings.shareActiveHours,
                      onChanged:
                          (val) =>
                              setState(() => _settings.shareActiveHours = val),
                    ),

                    _buildPrivacyOption(
                      title: 'Location Status',
                      subtitle: 'Share whether you\'re home or away',
                      icon: Icons.location_on,
                      value: _settings.shareLocation,
                      onChanged:
                          (val) =>
                              setState(() => _settings.shareLocation = val),
                    ),

                    _buildPrivacyOption(
                      title: 'Detailed Status',
                      subtitle:
                          'Share specific activities and timing information',
                      icon: Icons.info_outline,
                      value: _settings.shareDetailedStatus,
                      onChanged:
                          (val) => setState(
                            () => _settings.shareDetailedStatus = val,
                          ),
                    ),

                    SizedBox(height: 20),

                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber[700],
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Pro Tip',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Use "Invisible Mode" on the main screen to temporarily stop sharing any information at all.',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _saveSettings();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool required = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF6366F1), size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (required) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'REQUIRED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: required ? null : onChanged,
            activeColor: Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}
