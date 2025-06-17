import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/privacy_settings.dart';
import '../widgets/privacy_option_tile.dart';
import 'home_screen.dart';

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
                      PrivacyOptionTile(
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

                      PrivacyOptionTile(
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

                      PrivacyOptionTile(
                        title: 'Location Status',
                        subtitle: 'Share whether you\'re home or away',
                        icon: Icons.location_on,
                        value: _settings.shareLocation,
                        onChanged:
                            (val) =>
                                setState(() => _settings.shareLocation = val),
                      ),

                      PrivacyOptionTile(
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
}
