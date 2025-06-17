import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/privacy_settings.dart';
import '../widgets/privacy_option_tile.dart';

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
                    PrivacyOptionTile(
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

                    PrivacyOptionTile(
                      title: 'General Activity',
                      subtitle:
                          'Share vague status like "resting", "active", or "away"',
                      icon: Icons.timeline,
                      value: _settings.shareActiveHours,
                      onChanged:
                          (val) =>
                              setState(() => _settings.shareActiveHours = val),
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
}
