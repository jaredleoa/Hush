import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/household_setup_screen.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/auth': (context) => AuthScreen(),
        '/setup': (context) => HouseholdSetupScreen(),
        '/home': (context) => HushHomePage(),
      },
    );
  }
}

// Splash screen to check if user is logged in and has household
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndSetup();
  }

  Future<void> _checkAuthAndSetup() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check auth status
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final hasHousehold = prefs.getBool('hasHousehold') ?? false;
    
    // Short delay to show splash
    await Future.delayed(Duration(seconds: 1));
    
    if (!isLoggedIn) {
      // Not logged in - show auth screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen()),
      );
    } else if (!hasHousehold) {
      // Logged in but no household - show setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HouseholdSetupScreen()),
      );
    } else {
      // Logged in with household - go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HushHomePage()),
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
            Icon(
              Icons.nightlight_round,
              size: 80,
              color: Colors.white,
            ),
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

// Auth Screen (Login/Signup)
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      // TODO: Implement actual auth with Supabase
      await Future.delayed(Duration(seconds: 2)); // Simulate API call
      
      // Save auth status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', _emailController.text);
      if (!_isLogin) {
        await prefs.setString('userName', _nameController.text);
      }
      
      // Navigate to household setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HouseholdSetupScreen()),
      );
      
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isLogin 
              ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
              : [Color(0xFFFFA574), Color(0xFFFF6B9D)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40),
                    
                    // Logo and title
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.nightlight_round,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Hush',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Know when your housemates are sleeping',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 50),
                    
                    // Auth form
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? 'Welcome Back' : 'Create Account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            
                            // Name field (only for signup)
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF6B9D),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                            ],
                            
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _isLogin ? Color(0xFF6366F1) : Color(0xFFFF6B9D),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _isLogin ? Color(0xFF6366F1) : Color(0xFFFF6B9D),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
                            SizedBox(height: 24),
                            
                            // Submit button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isLogin ? Color(0xFF6366F1) : Color(0xFFFF6B9D),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Login' : 'Sign Up',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Toggle auth mode
                            TextButton(
                              onPressed: _toggleAuthMode,
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(color: Colors.grey[600]),
                                  children: [
                                    TextSpan(
                                      text: _isLogin 
                                        ? "Don't have an account? " 
                                        : 'Already have an account? ',
                                    ),
                                    TextSpan(
                                      text: _isLogin ? 'Sign up' : 'Login',
                                      style: TextStyle(
                                        color: _isLogin ? Color(0xFF6366F1) : Color(0xFFFF6B9D),
                                        fontWeight: FontWeight.bold,
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
                    
                    SizedBox(height: 20),
                  ],
                ),
              ),
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
    HousemateData(name: 'Jordan', status: 'awake', isHome: false, lastSeen: '2h ago', isMe: false),
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
      body: Column(
        children: [
          _buildHeader(),
          _buildHousematesList(),
        ],
      ),
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
          colors: _isSleeping 
            ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
            : [Color(0xFFFFA574), Color(0xFFFF6B9D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: (_isSleeping ? Color(0xFF6366F1) : Color(0xFFFF6B9D)).withOpacity(0.3),
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
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _householdName,
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white, size: 28),
                    onPressed: () {
                      // Simple settings menu for testing
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(Icons.exit_to_app),
                                title: Text('Leave Household'),
                                subtitle: Text('Reset and return to setup'),
                                onTap: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.clear();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => HouseholdSetupScreen()),
                                    (route) => false,
                                  );
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.person),
                                title: Text('Profile'),
                                subtitle: FutureBuilder<String>(
                                  future: SharedPreferences.getInstance()
                                      .then((prefs) => prefs.getString('userEmail') ?? 'user@example.com'),
                                  builder: (context, snapshot) => Text(snapshot.data ?? 'Loading...'),
                                ),
                              ),
                              Divider(),
                              ListTile(
                                leading: Icon(Icons.logout, color: Colors.red),
                                title: Text('Logout', style: TextStyle(color: Colors.red)),
                                subtitle: Text('Sign out of your account'),
                                onTap: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.clear();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => AuthScreen()),
                                    (route) => false,
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
                style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 20, fontWeight: FontWeight.w500),
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
                      colors: _isSleeping 
                        ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
                        : [Color(0xFFFFA574), Color(0xFFFF6B9D)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isSleeping ? Color(0xFF6366F1) : Color(0xFFFF6B9D)).withOpacity(0.4),
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
                      Icon(isHome ? Icons.home : Icons.directions_walk, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        isHome ? 'At Home' : 'Away',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
                  colors: sleeping 
                    ? [Color(0xFF6366F1), Color(0xFF4F46E5)]
                    : [Color(0xFFFFA574), Color(0xFFFF6B9D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (sleeping ? Color(0xFF6366F1) : Color(0xFFFF6B9D)).withOpacity(0.3),
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
                        fontWeight: person.isMe ? FontWeight.bold : FontWeight.w500,
                        fontSize: 20,
                        color: home ? Color(0xFF2D3142) : Color(0xFF9CA3AF),
                      ),
                    ),
                    if (!home) ...[
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(0xFF6B7280),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Away', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
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
              color: sleeping 
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