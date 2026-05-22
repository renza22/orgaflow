import 'package:flutter/material.dart';

class GradientSkillBar extends StatelessWidget {
  final double percentage;
  final double height;
  final double borderRadius;

  const GradientSkillBar({
    super.key,
    required this.percentage,
    this.height = 8,
    this.borderRadius = 4,
  });

  List<Color> _getGradientColors() {
    final clampedPercentage = percentage.clamp(0.0, 100.0);

    if (clampedPercentage <= 30) {
      // Beginner: Red to Orange
      return [
        const Color(0xFFEF4444), // Red-500
        const Color(0xFFF97316), // Orange-500
      ];
    } else if (clampedPercentage <= 60) {
      // Intermediate: Orange to Yellow
      return [
        const Color(0xFFF97316), // Orange-500
        const Color(0xFFFBBF24), // Yellow-400
      ];
    } else if (clampedPercentage <= 80) {
      // Advanced: Yellow to Cyan
      return [
        const Color(0xFFFBBF24), // Yellow-400
        const Color(0xFF06B6D4), // Cyan-500
      ];
    } else {
      // Expert: Cyan to Green
      return [
        const Color(0xFF06B6D4), // Cyan-500
        const Color(0xFF10B981), // Green-500
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
                      color: gradientColors.last.withValues(alpha: 0.3),
                      blurRadius: 3,
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
