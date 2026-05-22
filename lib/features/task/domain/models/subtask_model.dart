class SubtaskModel {
  const SubtaskModel({
    required this.id,
    required this.parentTaskId,
    required this.title,
    required this.description,
    required this.assignedToEmail,
    required this.assignedToName,
    required this.status,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String parentTaskId;
  final String title;
  final String description;
  final String assignedToEmail;
  final String assignedToName;
  final String status; // 'todo', 'in_progress', 'done'
  final String createdBy; // Email of the member who created it
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  factory SubtaskModel.fromJson(Map<String, dynamic> json) {
    return SubtaskModel(
      id: json['id'] as String,
      parentTaskId: json['parent_task_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      assignedToEmail: json['assigned_to_email'] as String,
      assignedToName: json['assigned_to_name'] as String? ?? '',
      status: json['status'] as String? ?? 'todo',
      createdBy: json['created_by'] as String,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      completedAt: _parseDateTime(json['completed_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_task_id': parentTaskId,
      'title': title,
      'description': description,
      'assigned_to_email': assignedToEmail,
      'assigned_to_name': assignedToName,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  SubtaskModel copyWith({
    String? id,
    String? parentTaskId,
    String? title,
    String? description,
    String? assignedToEmail,
    String? assignedToName,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return SubtaskModel(
      id: id ?? this.id,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      assignedToName: assignedToName ?? this.assignedToName,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
