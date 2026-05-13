import 'package:flutter/material.dart';

class OverloadBadge extends StatelessWidget {
  final double loadPercentage;
  final double size;

  const OverloadBadge({
    super.key,
    required this.loadPercentage,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade600.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.warning_rounded,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}

class OverloadIndicator extends StatelessWidget {
  final double loadPercentage;
  final bool showPercentage;

  const OverloadIndicator({
    super.key,
    required this.loadPercentage,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade600.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_rounded,
            color: Colors.white,
            size: 14,
          ),
          if (showPercentage) ...[
            const SizedBox(width: 4),
            Text(
              '${loadPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
