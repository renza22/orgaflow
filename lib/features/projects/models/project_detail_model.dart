import 'package:flutter/material.dart';

enum ProjectStatus { active, planning, completed }

class ProjectDetail {
  final int id;
  final String name;
  final String description;
  final int progress;
  final ProjectStatus status;
  final int members;
  final TaskCount tasks;
  final String dueDate;
  final Color color;

  ProjectDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.progress,
    required this.status,
    required this.members,
    required this.tasks,
    required this.dueDate,
    required this.color,
  });

  String get initial => name.isNotEmpty ? name[0] : '';

  StatusBadgeConfig get statusBadgeConfig {
    switch (status) {
      case ProjectStatus.active:
        return StatusBadgeConfig(
          label: 'Active',
          backgroundColor: const Color(0xFF6C5CE7),
          textColor: Colors.white,
        );
      case ProjectStatus.planning:
        return StatusBadgeConfig(
          label: 'Planning',
          backgroundColor: Colors.grey.shade200,
          textColor: Colors.grey.shade700,
        );
      case ProjectStatus.completed:
        return StatusBadgeConfig(
          label: 'Completed',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
    }
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
