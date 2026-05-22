import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularGradientProgress extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const CircularGradientProgress({
    super.key,
    required this.percentage,
    this.size = 120,
    this.strokeWidth = 12,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularGradientProgressPainter(
          percentage: percentage,
          strokeWidth: strokeWidth,
        ),
        child: child != null
            ? Center(child: child)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: size * 0.25,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: size * 0.12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CircularGradientProgressPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;

  _CircularGradientProgressPainter({
    required this.percentage,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background circle (gray)
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Gradient progress arc
    if (percentage > 0) {
      final sweepAngle = (percentage / 100) * 2 * math.pi;
      
      // Create gradient colors based on percentage
      final gradientColors = _getGradientColors(percentage);
      
      final gradientPaint = Paint()
        ..shader = SweepGradient(
          colors: gradientColors,
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweepAngle,
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweepAngle,
        false,
        gradientPaint,
      );
    }
  }

  List<Color> _getGradientColors(double percentage) {
    if (percentage <= 25) {
      // Low progress: Purple to Blue
      return [
        const Color(0xFF6C5CE7), // Purple
        const Color(0xFF5B8DEF), // Blue
      ];
    } else if (percentage <= 50) {
      // Medium-low: Blue to Cyan
      return [
        const Color(0xFF5B8DEF), // Blue
        const Color(0xFF00CEC9), // Cyan
      ];
    } else if (percentage <= 75) {
      // Medium-high: Cyan to Green
      return [
        const Color(0xFF00CEC9), // Cyan
        const Color(0xFF10B981), // Green
      ];
    } else {
      // High progress: Green to Yellow-Green
      return [
        const Color(0xFF10B981), // Green
        const Color(0xFF34D399), // Light Green
      ];
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
