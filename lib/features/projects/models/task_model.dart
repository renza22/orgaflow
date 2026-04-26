import '../../task/domain/models/task_model.dart' as task_domain;
import '../../task/domain/models/task_skill_requirement_model.dart';

enum TaskStatus { backlog, todo, inProgress, done }

extension TaskStatusDatabaseValue on TaskStatus {
  String get databaseValue {
    switch (this) {
      case TaskStatus.backlog:
        return 'backlog';
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }
}

class Task {
  final int id;
  final String? sourceTaskId;
  final String title;
  final String description;
  final String assignee;
  final TaskStatus status;
  final double estimatedHours;
  final String priority;
  final DateTime? dueDate;
  final List<String> skills;
  final List<TaskSkillRequirementModel> skillRequirements;
  final List<int> dependencies;

  Task({
    required this.id,
    this.sourceTaskId,
    required this.title,
    required this.description,
    required this.assignee,
    required this.status,
    required this.estimatedHours,
    this.priority = 'medium',
    this.dueDate,
    required this.skills,
    this.skillRequirements = const [],
    required this.dependencies,
  });

  factory Task.fromTaskModel(task_domain.TaskModel task) {
    final title = task.title.trim();
    final description = task.description?.trim() ?? '';
    final skills = task.skillRequirements
        .map((requirement) => requirement.skillName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    return Task(
      id: _intIdFromTaskId(task.id),
      sourceTaskId: task.id,
      title: title.isNotEmpty ? title : 'Untitled Task',
      description: description,
      assignee: '',
      status: _statusFromTaskModel(task.status),
      estimatedHours: task.estimatedHours.toDouble(),
      priority: task.priority,
      dueDate: task.dueDate,
      skills: skills,
      skillRequirements: task.skillRequirements,
      dependencies: const [],
    );
  }

  Task copyWith({
    int? id,
    String? sourceTaskId,
    String? title,
    String? description,
    String? assignee,
    TaskStatus? status,
    double? estimatedHours,
    String? priority,
    DateTime? dueDate,
    List<String>? skills,
    List<TaskSkillRequirementModel>? skillRequirements,
    List<int>? dependencies,
  }) {
    return Task(
      id: id ?? this.id,
      sourceTaskId: sourceTaskId ?? this.sourceTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      status: status ?? this.status,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      skills: skills ?? this.skills,
      skillRequirements: skillRequirements ?? this.skillRequirements,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  String get initials {
    if (assignee.isEmpty) return '';
    final names = assignee.split(' ');
    return names.map((n) => n[0]).join('');
  }

  static int _intIdFromTaskId(String taskId) {
    final normalized = taskId.replaceAll('-', '');
    final prefix =
        normalized.length >= 8 ? normalized.substring(0, 8) : normalized;

    return int.tryParse(prefix, radix: 16) ?? taskId.hashCode;
  }

  static TaskStatus _statusFromTaskModel(String status) {
    switch (status) {
      case 'todo':
        return TaskStatus.todo;
      case 'in_progress':
      case 'in_review':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'backlog':
      case 'blocked':
      default:
        return TaskStatus.backlog;
    }
  }
}

class KanbanColumn {
  final String id;
  final String title;
  final TaskStatus status;
  final int color;

  KanbanColumn({
    required this.id,
    required this.title,
    required this.status,
    required this.color,
  });
}
