import 'package:flutter/material.dart';

class Project {
  final int id;
  final String name;
  final String description;
  final DateTime deadline;
  final int progress;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final Color color;
  final IconData? icon;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.deadline,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.color,
    this.icon,
  });

  int getDaysUntilDeadline() {
    final today = DateTime(2026, 4, 7);
    final difference = deadline.difference(today);
    return difference.inDays;
  }

  bool get isUrgent {
    final days = getDaysUntilDeadline();
    return days <= 14 && days > 0;
  }

  bool get isOverdue => getDaysUntilDeadline() < 0;
}
