import 'package:flutter/material.dart';

import '../../project/domain/models/project_model.dart' as domain;

class Project {
  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.deadline,
    this.createdAt,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.color,
    required this.icon,
  });

  factory Project.fromProjectModel(domain.ProjectModel project) {
    final seed = _colorIndex(project.id);
    final pendingTasks = project.totalTasks - project.completedTasks;

    return Project(
      id: project.id,
      name: project.name,
      description: _buildDescription(project.description),
      status: project.status,
      deadline: project.endDate,
      createdAt: project.createdAt,
      progress: project.progress,
      totalTasks: project.totalTasks,
      completedTasks: project.completedTasks,
      pendingTasks: pendingTasks < 0 ? 0 : pendingTasks,
      color: _projectColors[seed],
      icon: _projectIcons[seed],
    );
  }

  static const List<Color> _projectColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
    Color(0xFF00B894),
    Color(0xFFFFCB6E),
    Color(0xFFFF7675),
  ];

  static const List<IconData> _projectIcons = [
    Icons.school,
    Icons.computer,
    Icons.campaign,
    Icons.groups_rounded,
    Icons.folder_special_outlined,
  ];

  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime? deadline;
  final DateTime? createdAt;
  final int progress;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final Color color;
  final IconData icon;

  int? getDaysUntilDeadline() {
    if (deadline == null) {
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      deadline!.year,
      deadline!.month,
      deadline!.day,
    );
    final difference = target.difference(today);
    return difference.inDays;
  }

  bool get isUrgent {
    final days = getDaysUntilDeadline();
    return !_isClosedStatus && days != null && days >= 0 && days <= 14;
  }

  bool get isOverdue {
    final days = getDaysUntilDeadline();
    return !_isClosedStatus && days != null && days < 0;
  }

  bool get hasUpcomingDeadline {
    final days = getDaysUntilDeadline();
    return !_isClosedStatus && days != null && days >= 0 && days <= 14;
  }

  String get deadlineLabel {
    if (deadline == null) {
      return 'Belum diatur';
    }

    final months = [
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

    return '${deadline!.day} ${months[deadline!.month - 1]} ${deadline!.year}';
  }

  String get deadlineStatusLabel {
    final days = getDaysUntilDeadline();
    if (days == null) {
      return 'Tanpa deadline';
    }
    if (days < 0) {
      return 'Terlambat';
    }
    if (days == 0) {
      return 'Hari ini';
    }
    return '$days hari lagi';
  }

  bool get _isClosedStatus => status == 'completed' || status == 'cancelled';

  static int _colorIndex(String seed) {
    final sum = seed.codeUnits.fold<int>(0, (total, unit) => total + unit);
    return sum % _projectColors.length;
  }

  static String _buildDescription(String? description) {
    final value = description?.trim();
    if (value == null || value.isEmpty) {
      return '-';
    }

    return value;
  }
}
