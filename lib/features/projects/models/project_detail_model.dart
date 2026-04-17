import 'package:flutter/material.dart';

import '../../project/domain/models/project_model.dart';

enum ProjectStatus { draft, active, onHold, completed, cancelled }

class ProjectDetail {
  ProjectDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.progress,
    required this.status,
    required this.members,
    required this.tasks,
    this.dueDate,
    required this.color,
  });

  factory ProjectDetail.fromProjectModel(ProjectModel project) {
    return ProjectDetail(
      id: project.id,
      name: project.name,
      description: _buildDescription(project.description),
      progress: project.progress,
      status: ProjectStatusMapper.fromDatabase(project.status),
      members: project.memberCount,
      tasks: TaskCount(
        total: project.totalTasks,
        completed: project.completedTasks,
      ),
      dueDate: project.endDate,
      color: _projectColors[_colorIndex(project.id)],
    );
  }

  final String id;
  final String name;
  final String description;
  final int progress;
  final ProjectStatus status;
  final int members;
  final TaskCount tasks;
  final DateTime? dueDate;
  final Color color;

  String get initial => name.trim().isNotEmpty ? name.trim()[0] : '';
  String get dueDateLabel =>
      dueDate == null ? 'Belum diatur' : _formatDate(dueDate!);

  StatusBadgeConfig get statusBadgeConfig {
    switch (status) {
      case ProjectStatus.draft:
        return StatusBadgeConfig(
          label: 'Draft',
          backgroundColor: Colors.grey.shade200,
          textColor: Colors.grey.shade700,
        );
      case ProjectStatus.active:
        return StatusBadgeConfig(
          label: 'Active',
          backgroundColor: const Color(0xFF6C5CE7),
          textColor: Colors.white,
        );
      case ProjectStatus.onHold:
        return StatusBadgeConfig(
          label: 'On Hold',
          backgroundColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFB26A00),
        );
      case ProjectStatus.completed:
        return StatusBadgeConfig(
          label: 'Completed',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      case ProjectStatus.cancelled:
        return StatusBadgeConfig(
          label: 'Cancelled',
          backgroundColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
        );
    }
  }

  static const List<Color> _projectColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00CEC9),
    Color(0xFF00B894),
    Color(0xFFFFCB6E),
    Color(0xFFFF7675),
  ];

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

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class TaskCount {
  final int total;
  final int completed;

  TaskCount({
    required this.total,
    required this.completed,
  });
}

class StatusBadgeConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  StatusBadgeConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

class ProjectStatusMapper {
  static ProjectStatus fromDatabase(String? value) {
    switch (value) {
      case 'active':
        return ProjectStatus.active;
      case 'on_hold':
        return ProjectStatus.onHold;
      case 'completed':
        return ProjectStatus.completed;
      case 'cancelled':
        return ProjectStatus.cancelled;
      case 'draft':
      default:
        return ProjectStatus.draft;
    }
  }
}
