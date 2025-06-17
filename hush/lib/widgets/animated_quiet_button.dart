import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quiet_reason.dart';

class AnimatedQuietButton extends StatefulWidget {
  final bool isQuietTime;
  final QuietReason? quietReason;
  final VoidCallback onToggle;
  final VoidCallback onReasonSelect;

  const AnimatedQuietButton({
    Key? key,
    required this.isQuietTime,
    this.quietReason,
    required this.onToggle,
    required this.onReasonSelect,
  }) : super(key: key);

  @override
  State<AnimatedQuietButton> createState() => _AnimatedQuietButtonState();
}

class _AnimatedQuietButtonState extends State<AnimatedQuietButton>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _rippleController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Breathing animation for quiet mode
    _breathingController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    // Ripple animation for tap feedback
    _rippleController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    if (widget.isQuietTime) {
      _breathingController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedQuietButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isQuietTime != oldWidget.isQuietTime) {
      if (widget.isQuietTime) {
        _breathingController.repeat(reverse: true);
      } else {
        _breathingController.stop();
        _breathingController.reset();
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onReasonSelect,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathingAnimation, _rippleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isQuietTime ? _breathingAnimation.value : 1.0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isQuietTime
                      ? [Colors.indigo.shade300, Colors.indigo.shade600]
                      : [Colors.grey.shade300, Colors.grey.shade500],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isQuietTime
                        ? Colors.indigo.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple effect
                  if (_rippleAnimation.value > 0)
                    Container(
                      width: 120 * _rippleAnimation.value,
                      height: 120 * _rippleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  // Main icon
                  Icon(
                    widget.isQuietTime ? Icons.bedtime : Icons.wb_sunny,
                    size: 50,
                    color: Colors.white,
                  ),
                  // Reason indicator
                  if (widget.isQuietTime && widget.quietReason != null)
                    Positioned(
                      bottom: 15,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.quietReason!.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
