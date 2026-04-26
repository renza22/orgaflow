import 'package:flutter/foundation.dart';

import 'task_skill_requirement_model.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.projectId,
    this.parentTaskId,
    required this.title,
    this.description,
    required this.estimatedHours,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.sortOrder,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.skillRequirements = const [],
  });

  final String id;
  final String projectId;
  final String? parentTaskId;
  final String title;
  final String? description;
  final int estimatedHours;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final int sortOrder;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TaskSkillRequirementModel> skillRequirements;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final title = _readString(json, const ['title']).trim();
    if (title.isEmpty) {
      debugPrint('TaskModel.fromJson blank title raw json: $json');
    }

    return TaskModel(
      id: _readString(json, const ['id']),
      projectId: _readString(json, const ['project_id', 'projectId']),
      parentTaskId: _readNullableString(
        json,
        const ['parent_task_id', 'parentTaskId'],
      ),
      title: title.isNotEmpty ? title : 'Untitled Task',
      description: _readNullableString(json, const ['description']),
      estimatedHours: _readInt(
        json,
        const ['estimated_hours', 'estimatedHours'],
      ),
      priority: _readString(json, const ['priority'], fallback: 'medium'),
      status: _readString(json, const ['status'], fallback: 'backlog'),
      dueDate: _parseDateTimeFrom(json, const ['due_date', 'dueDate']),
      sortOrder: _readInt(json, const ['sort_order', 'sortOrder']),
      createdBy: _readString(json, const ['created_by', 'createdBy']),
      createdAt: _parseDateTimeFrom(json, const ['created_at', 'createdAt']),
      updatedAt: _parseDateTimeFrom(json, const ['updated_at', 'updatedAt']),
      skillRequirements: _parseSkillRequirements(
        json['skill_requirements'] ?? json['task_skill_requirements'],
      ),
    );
  }

  TaskModel copyWith({
    List<TaskSkillRequirementModel>? skillRequirements,
  }) {
    return TaskModel(
      id: id,
      projectId: projectId,
      parentTaskId: parentTaskId,
      title: title,
      description: description,
      estimatedHours: estimatedHours,
      priority: priority,
      status: status,
      dueDate: dueDate,
      sortOrder: sortOrder,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      skillRequirements: skillRequirements ?? this.skillRequirements,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDateTimeFrom(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final parsed = _parseDateTime(json[key]);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    return _readNullableString(json, keys) ?? fallback;
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  static int _readInt(
    Map<String, dynamic> json,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return fallback;
  }

  static List<TaskSkillRequirementModel> _parseSkillRequirements(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (json) => TaskSkillRequirementModel.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }
}
