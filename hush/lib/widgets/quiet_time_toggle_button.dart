import 'package:flutter/material.dart';

class QuietTimeToggleButton extends StatefulWidget {
  final bool isQuietTime;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const QuietTimeToggleButton({
    Key? key,
    required this.isQuietTime,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  State<QuietTimeToggleButton> createState() => _QuietTimeToggleState();
}

class _QuietTimeToggleState extends State<QuietTimeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    if (widget.isQuietTime) {
      _breathingController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      shape: const CircleBorder(),
      child: widget.isQuietTime
          ? ScaleTransition(
              scale: _breathingAnimation,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                customBorder: const CircleBorder(),
                splashColor: const Color(0xFF4F46E5).withOpacity(0.3),
                highlightColor: const Color(0xFF6366F1).withOpacity(0.2),
                splashFactory: InkRipple.splashFactory,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 200,
                  height: 200,
                  child: const Center(
                    child: Icon(
                      Icons.nights_stay,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
              ),
            )
          : InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              customBorder: const CircleBorder(),
              splashColor: const Color(0xFF059669).withOpacity(0.3),
              highlightColor: const Color(0xFF10B981).withOpacity(0.2),
              splashFactory: InkRipple.splashFactory,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200,
                height: 200,
                child: const Center(
                  child: Icon(
                    Icons.volume_up,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            ),
    );
  }
}
