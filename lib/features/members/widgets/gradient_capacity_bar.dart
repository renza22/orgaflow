import 'package:flutter/material.dart';
import 'dart:math' as math;

class GradientCapacityBar extends StatelessWidget {
  final double percentage;
  final double height;
  final double borderRadius;

  const GradientCapacityBar({
    super.key,
    required this.percentage,
    this.height = 8,
    this.borderRadius = 4,
  });

  List<Color> _getGradientColors() {
    final clampedPercentage = percentage.clamp(0.0, 150.0);

    if (clampedPercentage <= 50) {
      // Safe zone: Green gradient
      return [
        const Color(0xFF10B981), // Green-500
        const Color(0xFF34D399), // Green-400
      ];
    } else if (clampedPercentage <= 75) {
      // Transition to warning: Green to Yellow
      final t = (clampedPercentage - 50) / 25; // 0 to 1
      return [
        Color.lerp(const Color(0xFF10B981), const Color(0xFFF59E0B), t)!,
        Color.lerp(const Color(0xFF34D399), const Color(0xFFFBBF24), t)!,
      ];
    } else if (clampedPercentage <= 100) {
      // Warning zone: Yellow to Orange
      final t = (clampedPercentage - 75) / 25; // 0 to 1
      return [
        Color.lerp(const Color(0xFFF59E0B), const Color(0xFFF97316), t)!,
        Color.lerp(const Color(0xFFFBBF24), const Color(0xFFFB923C), t)!,
      ];
    } else {
      // Overload zone: Orange to Red
      final t = math.min((clampedPercentage - 100) / 50, 1.0); // 0 to 1
      return [
        Color.lerp(const Color(0xFFF97316), const Color(0xFFDC2626), t)!,
        Color.lerp(const Color(0xFFFB923C), const Color(0xFFEF4444), t)!,
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    final displayPercentage = (percentage / 100).clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Background gradient (full width, low opacity)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors
                      .map((c) => c.withValues(alpha: 0.2))
                      .toList(),
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Foreground gradient (actual progress)
            FractionallySizedBox(
              widthFactor: displayPercentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.last.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
