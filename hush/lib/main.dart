import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(HushApp());

class HushApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: SplashScreen(), // Start with splash to check setup status
    );
  }
}

// Splash screen to check if user has joined a household
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
    final householdName = prefs.getString('householdName') ?? '';

    // Short delay to show splash
    await Future.delayed(Duration(seconds: 1));

    if (hasHousehold) {
      // User has already joined/created a household
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HushHomePage()),
      );
    } else {
      // First time user - show setup
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
            Icon(Icons.nightlight_round, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Hush',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
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

// Household Setup Screen
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

    // TODO: Implement actual join logic with Supabase
    await Future.delayed(Duration(seconds: 2)); // Simulate API call

    // Save household status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasHousehold', true);
    await prefs.setString(
      'householdName',
      'The Apartment',
    ); // This would come from API
    await prefs.setString(
      'householdId',
      'generated-id',
    ); // This would come from API
    await prefs.setString('inviteCode', _joinCodeController.text);

    setState(() => _isJoining = false);

    // Navigate to home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HushHomePage()),
    );
  }

  void _createHousehold() async {
    if (_householdNameController.text.isEmpty) {
      _showError('Please enter a household name');
      return;
    }

    setState(() => _isCreating = true);

    // TODO: Implement actual create logic with Supabase
    await Future.delayed(Duration(seconds: 2)); // Simulate API call

    // Generate a random invite code (in real app, this comes from backend)
    final inviteCode = _generateInviteCode();

    // Save household status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasHousehold', true);
    await prefs.setString('householdName', _householdNameController.text);
    await prefs.setString(
      'householdId',
      'generated-id',
    ); // This would come from API
    await prefs.setString('inviteCode', inviteCode);
    await prefs.setBool('isHouseholdCreator', true);

    setState(() => _isCreating = false);

    // Show the invite code to the user
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
                    MaterialPageRoute(builder: (_) => HushHomePage()),
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
                // Back button - removed since this is the first screen
                SizedBox(height: 40),

                // Title
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
                  'Create a new household or join an existing one',
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

                        // Invite code input
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

                        // Join button
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

                        // Household name input
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

                        // Create button
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

                // Info text
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Free households support up to 4 members',
                          style: TextStyle(
                            color: Colors.blue[700],
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

class HousemateData {
  final String name;
  String status;
  bool isHome;
  String? lastSeen;
  final bool isMe;

  HousemateData({
    required this.name,
    required this.status,
    required this.isHome,
    this.lastSeen,
    required this.isMe,
  });
}

class HushHomePage extends StatefulWidget {
  @override
  _HushHomePageState createState() => _HushHomePageState();
}

class _HushHomePageState extends State<HushHomePage> {
  bool _isSleeping = false;
  String _householdName = 'Loading...';

  final List<HousemateData> _housemates = [
    HousemateData(name: 'You', status: 'awake', isHome: true, isMe: true),
    HousemateData(name: 'Alex', status: 'sleeping', isHome: true, isMe: false),
    HousemateData(
      name: 'Jordan',
      status: 'awake',
      isHome: false,
      lastSeen: '2h ago',
      isMe: false,
    ),
    HousemateData(name: 'Sam', status: 'sleeping', isHome: true, isMe: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadHouseholdName();
  }

  Future<void> _loadHouseholdName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _householdName = prefs.getString('householdName') ?? 'My Household';
    });
  }

  void _toggleSleep() {
    setState(() {
      _isSleeping = !_isSleeping;
      _housemates[0].status = _isSleeping ? 'sleeping' : 'awake';
    });
    HapticFeedback.lightImpact();
  }

  void _toggleHome() {
    setState(() {
      _housemates[0].isHome = !_housemates[0].isHome;
      if (!_housemates[0].isHome) {
        _housemates[0].lastSeen = 'Just now';
      } else {
        _housemates[0].lastSeen = null;
      }
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
    final isHome = _housemates[0].isHome;

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              _isSleeping
                  ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
                  : [Color(0xFFFFA574), Color(0xFFFF6B9D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: (_isSleeping ? Color(0xFF6366F1) : Color(0xFFFF6B9D))
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
                    onPressed: () {
                      // Simple settings menu for testing
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder:
                            (context) => Container(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.exit_to_app),
                                    title: Text('Leave Household'),
                                    subtitle: Text('Reset and return to setup'),
                                    onTap: () async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.clear();
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => HouseholdSetupScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.vpn_key),
                                    title: Text('Invite Code'),
                                    subtitle: FutureBuilder<String>(
                                      future: SharedPreferences.getInstance()
                                          .then(
                                            (prefs) =>
                                                prefs.getString('inviteCode') ??
                                                'N/A',
                                          ),
                                      builder:
                                          (context, snapshot) => Text(
                                            snapshot.data ?? 'Loading...',
                                          ),
                                    ),
                                    onTap: () async {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final code =
                                          prefs.getString('inviteCode') ?? '';
                                      Clipboard.setData(
                                        ClipboardData(text: code),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Code copied!')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 40),
              Text(
                'Your Status',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 40),
              GestureDetector(
                onTap: _toggleSleep,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          _isSleeping
                              ? [Color(0xFF818CF8), Color(0xFF6366F1)]
                              : [Color(0xFFFFB088), Color(0xFFFF6B9D)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isSleeping
                                ? Color(0xFF6366F1)
                                : Color(0xFFFF6B9D))
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
                        _isSleeping ? Icons.nightlight_round : Icons.wb_sunny,
                        size: 70,
                        color: Colors.white,
                      ),
                      SizedBox(height: 15),
                      Text(
                        _isSleeping ? 'Sleeping' : 'Awake',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _toggleHome,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isHome ? Icons.home : Icons.directions_walk,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isHome ? 'At Home' : 'Away',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        itemCount: _housemates.length,
        itemBuilder: (context, index) {
          final person = _housemates[index];
          return _buildHousemateTile(person);
        },
      ),
    );
  }

  Widget _buildHousemateTile(HousemateData person) {
    final sleeping = person.status == 'sleeping';
    final home = person.isHome;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: home ? 1.0 : 0.5,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors:
                      sleeping
                          ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
                          : [Color(0xFFFFA574), Color(0xFFFF6B9D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (sleeping ? Color(0xFF6366F1) : Color(0xFFFF6B9D))
                        .withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                sleeping ? Icons.nightlight_round : Icons.wb_sunny,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      person.name,
                      style: TextStyle(
                        fontWeight:
                            person.isMe ? FontWeight.bold : FontWeight.w500,
                        fontSize: 20,
                        color: home ? Color(0xFF2D3142) : Color(0xFF9CA3AF),
                      ),
                    ),
                    if (!home) ...[
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF6B7280),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Away',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (!home && person.lastSeen != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Left ${person.lastSeen}',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color:
                  sleeping
                      ? Color(0xFF6366F1).withOpacity(0.1)
                      : Color(0xFFFF6B9D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              sleeping ? 'Sleeping' : 'Awake',
              style: TextStyle(
                color: sleeping ? Color(0xFF4F46E5) : Color(0xFFFF6B9D),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
