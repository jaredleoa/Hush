// lib/widgets/home_away_toggle_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeAwayToggleButton extends StatefulWidget {
  final bool isAtHome;
  final Function(bool) onToggle;
  final VoidCallback? onSettingsPressed;

  const HomeAwayToggleButton({
    Key? key,
    required this.isAtHome,
    required this.onToggle,
    this.onSettingsPressed,
  }) : super(key: key);

  @override
  State<HomeAwayToggleButton> createState() => _HomeAwayToggleButtonState();
}

class _HomeAwayToggleButtonState extends State<HomeAwayToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onToggle(!widget.isAtHome);
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onSettingsPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.isAtHome
                      ? Icons.home_rounded
                      : Icons.directions_walk_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Location settings dialog
class LocationSettingsDialog extends StatefulWidget {
  final bool isAutoLocationEnabled;
  final String? homeWifiName;
  final Function(bool) onAutoLocationToggle;
  final VoidCallback? onSetHomeWifi;

  const LocationSettingsDialog({
    Key? key,
    required this.isAutoLocationEnabled,
    this.homeWifiName,
    required this.onAutoLocationToggle,
    this.onSetHomeWifi,
  }) : super(key: key);

  @override
  State<LocationSettingsDialog> createState() => _LocationSettingsDialogState();
}

class _LocationSettingsDialogState extends State<LocationSettingsDialog> {
  late bool _autoLocationEnabled;

  @override
  void initState() {
    super.initState();
    _autoLocationEnabled = widget.isAutoLocationEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, color: Color(0xFF6366F1), size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Location Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how you want to manage your home/away status:',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          SizedBox(height: 20),

          // Manual Option
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  !_autoLocationEnabled
                      ? Color(0xFF6366F1).withOpacity(0.1)
                      : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    !_autoLocationEnabled
                        ? Color(0xFF6366F1).withOpacity(0.3)
                        : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: _autoLocationEnabled,
                  onChanged: (value) {
                    setState(() => _autoLocationEnabled = false);
                    widget.onAutoLocationToggle(false);
                  },
                  activeColor: Color(0xFF6366F1),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Control',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap the button to toggle between home and away',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Automatic Option
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  _autoLocationEnabled
                      ? Color(0xFF10B981).withOpacity(0.1)
                      : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _autoLocationEnabled
                        ? Color(0xFF10B981).withOpacity(0.3)
                        : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _autoLocationEnabled,
                  onChanged: (value) {
                    setState(() => _autoLocationEnabled = true);
                    widget.onAutoLocationToggle(true);
                  },
                  activeColor: Color(0xFF10B981),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WiFi-Based Auto Detection',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Automatically detect when you\'re home based on WiFi network',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (_autoLocationEnabled) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.homeWifiName != null
                                    ? Color(0xFF10B981).withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.homeWifiName != null
                                ? 'Home WiFi: ${widget.homeWifiName}'
                                : 'No home WiFi set',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color:
                                  widget.homeWifiName != null
                                      ? Color(0xFF10B981)
                                      : Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_autoLocationEnabled) ...[
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onSetHomeWifi,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF10B981),
                  side: BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.wifi, size: 18),
                label: Text(
                  widget.homeWifiName != null
                      ? 'Change Home WiFi'
                      : 'Set Home WiFi',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],

          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your location data is private and only used to show home/away status to your housemates.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Done'),
        ),
      ],
    );
  }
}
