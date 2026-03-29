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

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String? ?? '',
      parentTaskId: json['parent_task_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      estimatedHours: (json['estimated_hours'] as num?)?.toInt() ?? 0,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'backlog',
      dueDate: _parseDateTime(json['due_date']),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
