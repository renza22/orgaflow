import 'package:flutter/material.dart';

class OverloadWarningDialog extends StatelessWidget {
  final String memberName;
  final double currentLoad;
  final double maxCapacity;
  final double taskEstimatedHours;
  final double projectedLoad;
  final double overloadThreshold;

  const OverloadWarningDialog({
    super.key,
    required this.memberName,
    required this.currentLoad,
    required this.maxCapacity,
    required this.taskEstimatedHours,
    required this.projectedLoad,
    required this.overloadThreshold,
  });

  double get currentLoadPercentage => (currentLoad / maxCapacity) * 100;
  double get projectedLoadPercentage => (projectedLoad / maxCapacity) * 100;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Peringatan Overload!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Warning Message
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Member '),
                  TextSpan(
                    text: '"$memberName"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const TextSpan(text: ' akan mengalami '),
                  TextSpan(
                    text: 'overload (${projectedLoadPercentage.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const TextSpan(text: ' jika tugas ini diberikan.'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Load Comparison Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Current Load
                  _buildLoadRow(
                    'Beban Saat Ini',
                    currentLoad,
                    maxCapacity,
                    currentLoadPercentage,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  
                  // Task Hours
                  Row(
                    children: [
                      Icon(Icons.add_circle_outline, 
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Tugas Baru',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${taskEstimatedHours.toStringAsFixed(0)}h',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Divider(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  
                  // Projected Load
                  _buildLoadRow(
                    'Proyeksi Beban',
                    projectedLoad,
                    maxCapacity,
                    projectedLoadPercentage,
                    Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Threshold Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                      size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Threshold overload: ${overloadThreshold.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tetap Lanjutkan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pertimbangkan untuk memilih anggota lain',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadRow(
    String label,
    double hours,
    double maxHours,
    double percentage,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${hours.toStringAsFixed(0)}h / ${maxHours.toStringAsFixed(0)}h',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  color: color,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
