import 'dart:math';

import 'package:flutter/material.dart';

import '../../../workload/domain/models/workload_item_model.dart';
import '../../models/task_model.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.tasks,
    this.dueDate,
    required this.projectDescription,
    this.workloads = const [],
    this.isLoadingWorkloads = false,
    this.workloadError,
    this.onRetryWorkloads,
  });

  final List<Task> tasks;
  final DateTime? dueDate;
  final String projectDescription;
  final List<WorkloadItemModel> workloads;
  final bool isLoadingWorkloads;
  final String? workloadError;
  final VoidCallback? onRetryWorkloads;

  int get _completedTasks =>
      tasks.where((task) => task.databaseStatus == 'done').length;

  int get _totalTasks => tasks.length;

  double get _progressPercent =>
      _totalTasks == 0 ? 0 : (_completedTasks / _totalTasks * 100);

  String get _deadlineText {
    if (dueDate == null) {
      return 'Tanpa deadline';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final days = target.difference(today).inDays;

    if (days == 0) {
      return 'Hari ini';
    }
    if (days > 0) {
      return '$days hari lagi';
    }
    return 'Terlambat ${days.abs()} hari';
  }

  List<Task> get _milestoneTasks {
    final sortedTasks = [...tasks];
    sortedTasks.sort((left, right) {
      final leftDue = left.dueDate;
      final rightDue = right.dueDate;

      if (leftDue != null && rightDue != null) {
        final dueCompare = leftDue.compareTo(rightDue);
        if (dueCompare != 0) {
          return dueCompare;
        }
      } else if (leftDue != null) {
        return -1;
      } else if (rightDue != null) {
        return 1;
      }

      final statusCompare = _statusRank(left).compareTo(_statusRank(right));
      if (statusCompare != 0) {
        return statusCompare;
      }

      final priorityCompare =
          _priorityRank(left.priority).compareTo(_priorityRank(right.priority));
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return left.title.toLowerCase().compareTo(right.title.toLowerCase());
    });

    return sortedTasks.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 900;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: isSmall
          ? Column(
              children: [
                _buildProgressCard(),
                const SizedBox(height: 20),
                _buildWorkloadCard(),
              ],
            )
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Timeline & Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            projectDescription,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    progress:
                        (_progressPercent / 100).clamp(0.0, 1.0).toDouble(),
                    bgColor: Colors.grey.shade200,
                    progressColor: const Color(0xFF6C5CE7),
                    secondaryColor: const Color(0xFF00CEC9),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_progressPercent.round()}%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
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
                    _buildInfoRow(
                      Icons.access_time,
                      const Color(0xFF6C5CE7),
                      'Time Remaining',
                      _deadlineText,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.track_changes,
                      const Color(0xFF00CEC9),
                      'Tasks Progress',
                      '$_completedTasks/$_totalTasks',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Key Milestones',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          _buildMilestoneList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneList() {
    final milestoneTasks = _milestoneTasks;

    if (milestoneTasks.isEmpty) {
      return Text(
        'Belum ada task pada proyek ini.',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      );
    }

    return Column(
      children: milestoneTasks.map(_buildMilestone).toList(),
    );
  }

  Widget _buildMilestone(Task task) {
    final color = _taskStatusColor(task);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(_taskStatusIcon(task), size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _taskStatusLabel(task),
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          Text(
            task.dueDate == null
                ? 'Tanpa deadline'
                : _formatDate(task.dueDate!),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadCard() {
    final attentionCount = workloads
        .where(
          (member) =>
              member.workloadStatus == 'critical' ||
              member.workloadStatus == 'overload',
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Member Workload Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.show_chart, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'View All',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildWorkloadContent(),
          if (!isLoadingWorkloads &&
              workloadError == null &&
              workloads.isNotEmpty &&
              attentionCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$attentionCount anggota perlu perhatian',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        Text(
                          'Pertimbangkan untuk redistribute tasks',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkloadContent() {
    if (isLoadingWorkloads) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (workloadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workloadError!,
            style: TextStyle(fontSize: 13, color: Colors.red.shade700),
          ),
          if (onRetryWorkloads != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onRetryWorkloads,
              child: const Text('Coba Lagi'),
            ),
          ],
        ],
      );
    }

    if (workloads.isEmpty) {
      return Text(
        'Belum ada anggota atau assignee pada proyek ini.',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      );
    }

    return Column(
      children: workloads.map(_buildMemberRow).toList(),
    );
  }

  Widget _buildMemberRow(WorkloadItemModel member) {
    final percentage = _displayPercent(member);
    final color = _workloadStatusColor(member.workloadStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(member.fullName),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _workloadStatusLabel(member.workloadStatus),
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${member.assignedHours} / ${member.weeklyCapacityHours} jam '
                  '- ${member.activeTaskCount} task aktif',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressValue(member.loadRatio),
                    backgroundColor: Colors.grey.shade200,
                    minHeight: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  int _statusRank(Task task) {
    switch (task.databaseStatus) {
      case 'in_progress':
        return 0;
      case 'todo':
        return 1;
      case 'in_review':
        return 2;
      case 'blocked':
        return 3;
      case 'backlog':
        return 4;
      case 'done':
        return 5;
      default:
        return 6;
    }
  }

  int _priorityRank(String priority) {
    switch (priority.trim().toLowerCase()) {
      case 'urgent':
      case 'high':
        return 0;
      case 'medium':
        return 1;
      case 'low':
      default:
        return 2;
    }
  }

  IconData _taskStatusIcon(Task task) {
    switch (task.databaseStatus) {
      case 'done':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.flash_on;
      case 'in_review':
        return Icons.rate_review;
      case 'blocked':
        return Icons.block;
      case 'todo':
        return Icons.radio_button_unchecked;
      case 'backlog':
      default:
        return Icons.error_outline;
    }
  }

  Color _taskStatusColor(Task task) {
    switch (task.databaseStatus) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'in_review':
        return const Color(0xFF6C5CE7);
      case 'blocked':
        return Colors.red.shade600;
      case 'todo':
        return const Color(0xFF00CEC9);
      case 'backlog':
      default:
        return Colors.grey;
    }
  }

  String _taskStatusLabel(Task task) {
    switch (task.databaseStatus) {
      case 'done':
        return 'Done';
      case 'in_progress':
        return 'In Progress';
      case 'in_review':
        return 'In Review';
      case 'blocked':
        return 'Blocked';
      case 'todo':
        return 'Todo';
      case 'backlog':
        return 'Backlog';
      default:
        return task.databaseStatus;
    }
  }

  double _displayPercent(WorkloadItemModel member) {
    return member.loadPercentage ?? member.loadRatio * 100;
  }

  double _progressValue(double loadRatio) {
    return loadRatio.clamp(0.0, 1.0).toDouble();
  }

  Color _workloadStatusColor(String status) {
    switch (status) {
      case 'overload':
        return Colors.red.shade900;
      case 'critical':
        return Colors.red.shade600;
      case 'warning':
        return Colors.orange.shade700;
      case 'safe':
        return Colors.green.shade700;
      case 'no_capacity':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
  }

  String _workloadStatusLabel(String status) {
    switch (status) {
      case 'overload':
        return 'Overload';
      case 'critical':
        return 'Critical';
      case 'warning':
        return 'Warning';
      case 'safe':
        return 'Aman';
      case 'no_capacity':
        return 'No Capacity';
      default:
        return status;
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    return parts.map((part) => part[0].toUpperCase()).join();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.bgColor,
    required this.progressColor,
    required this.secondaryColor,
  });

  final double progress;
  final Color bgColor;
  final Color progressColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

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
