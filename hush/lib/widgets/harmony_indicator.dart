import 'package:flutter/material.dart';
import '../models/household_harmony.dart';

class HarmonyIndicator extends StatefulWidget {
  final HouseholdHarmony harmony;

  const HarmonyIndicator({Key? key, required this.harmony}) : super(key: key);

  @override
  State<HarmonyIndicator> createState() => _HarmonyIndicatorState();
}

class _HarmonyIndicatorState extends State<HarmonyIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.harmony.score / 100.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(HarmonyIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.harmony.score != widget.harmony.score) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.harmony.score / 100.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getHarmonyColor(double score) {
    if (score >= 80) return Colors.green.shade400;
    if (score >= 60) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  String _getHarmonyEmoji(double score) {
    if (score >= 90) return '😊';
    if (score >= 80) return '🙂';
    if (score >= 70) return '😐';
    if (score >= 60) return '😕';
    return '😟';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Household Harmony',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                _getHarmonyEmoji(widget.harmony.score),
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
          SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getHarmonyColor(widget.harmony.score),
                    ),
                    minHeight: 8,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(widget.harmony.score).round()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getHarmonyColor(widget.harmony.score),
                        ),
                      ),
                      Text(
                        widget.harmony.statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
