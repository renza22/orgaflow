import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/task_model.dart';

class OverviewTab extends StatelessWidget {
  final List<Task> tasks;
  final DateTime? dueDate;
  final String projectDescription;

  const OverviewTab({
    super.key,
    required this.tasks,
    this.dueDate,
    required this.projectDescription,
  });

  int get _completedTasks => tasks.where((t) => t.status == TaskStatus.done).length;
  int get _totalTasks => tasks.length;
  double get _progressPercent => _totalTasks == 0 ? 0 : (_completedTasks / _totalTasks * 100);
  int get _daysRemaining {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 900;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: isSmall
          ? Column(children: [_buildProgressCard(), const SizedBox(height: 20), _buildWorkloadCard()])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProgressCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildWorkloadCard()),
              ],
            ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Project Timeline & Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
          const SizedBox(height: 28),
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: _progressPercent / 100,
                    bgColor: Colors.grey.shade200,
                    progressColor: const Color(0xFF6C5CE7),
                    secondaryColor: const Color(0xFF00CEC9),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_progressPercent.round()}%',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                        Text('Complete',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.access_time, const Color(0xFF6C5CE7), 'Time Remaining',
                        '$_daysRemaining Days'),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.track_changes, const Color(0xFF00CEC9), 'Tasks Progress',
                        '$_completedTasks/$_totalTasks'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Key Milestones',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          _buildMilestone(Icons.check_circle, Colors.green, 'Planning', 'Mar 15'),
          _buildMilestone(Icons.check_circle, Colors.green, 'Venue Booking', 'Apr 10'),
          _buildMilestone(Icons.flash_on, Colors.orange, 'Marketing', 'Apr 28'),
          _buildMilestone(Icons.error_outline, Colors.grey, 'Final Prep', 'May 12'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      ],
    );
  }

  Widget _buildMilestone(IconData icon, Color color, String title, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          Text(date, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildWorkloadCard() {
    final members = _getMemberWorkloads();
    final overloadCount = members.where((m) => m['percent'] as int >= 90).length;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Member Workload Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              Row(children: [
                Icon(Icons.show_chart, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('View All', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          ...members.map((m) => _buildMemberRow(m)),
          if (overloadCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$overloadCount members mendekati overload',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
                    Text('Pertimbangkan untuk redistribute tasks',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                  ]),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member) {
    final percent = member['percent'] as int;
    final color = _getWorkloadColor(percent);
    final secondaryColor = _getWorkloadSecondaryColor(percent);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: Text(member['initials'] as String,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(member['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(member['hours'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: Colors.grey.shade200,
                  minHeight: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Text('$percent%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: secondaryColor)),
        ],
      ),
    );
  }

  Color _getWorkloadColor(int percent) {
    if (percent >= 90) return Colors.red;
    if (percent >= 70) return Colors.orange;
    if (percent >= 50) return const Color(0xFF00CEC9);
    return const Color(0xFF6C5CE7);
  }

  Color _getWorkloadSecondaryColor(int percent) {
    if (percent >= 90) return Colors.red.shade700;
    if (percent >= 70) return Colors.orange.shade700;
    return Colors.grey.shade700;
  }

  List<Map<String, dynamic>> _getMemberWorkloads() {
    // Build from task assignees
    final Map<String, double> assigneeHours = {};
    for (final task in tasks) {
      if (task.assignee.isNotEmpty) {
        assigneeHours[task.assignee] = (assigneeHours[task.assignee] ?? 0) + task.estimatedHours;
      }
    }

    // Add demo data for richer display
    final defaults = [
      {'name': 'Sarah Chen', 'hours': '18h / 20h weekly', 'percent': 90, 'initials': 'SC'},
      {'name': 'Ahmad Rizki', 'hours': '15h / 20h weekly', 'percent': 75, 'initials': 'AR'},
      {'name': 'Maya Putri', 'hours': '19h / 20h weekly', 'percent': 95, 'initials': 'MP'},
      {'name': 'David Lee', 'hours': '12h / 20h weekly', 'percent': 60, 'initials': 'DL'},
      {'name': 'Siti Nurhaliza', 'hours': '16h / 20h weekly', 'percent': 80, 'initials': 'SN'},
    ];

    return defaults;
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color progressColor;
  final Color secondaryColor;

  _CircularProgressPainter({
    required this.progress,
    required this.bgColor,
    required this.progressColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = 12.0;

    // Background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Gradient-like: first part purple, second part teal
    final sweepAngle = 2 * pi * progress;
    final purpleAngle = sweepAngle * 0.7;
    final tealAngle = sweepAngle * 0.3;

    progressPaint.color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      purpleAngle,
      false,
      progressPaint,
    );

    if (tealAngle > 0) {
      progressPaint.color = secondaryColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2 + purpleAngle,
        tealAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
