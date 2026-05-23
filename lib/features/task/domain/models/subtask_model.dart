class SubtaskModel {
  const SubtaskModel({
    required this.id,
    required this.parentTaskId,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedMemberId,
    required this.assignedToName,
    required this.assignedToEmail,
    required this.createdByMemberId,
    required this.createdByName,
    required this.createdByEmail,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String parentTaskId;
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'done'
  final String assignedMemberId;
  final String assignedToName;
  final String assignedToEmail;
  final String createdByMemberId;
  final String createdByName;
  final String createdByEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  String get createdBy => createdByEmail;

  factory SubtaskModel.fromJson(Map<String, dynamic> json) {
    return SubtaskModel(
      id: _readString(json['id']),
      parentTaskId: _readString(json['parent_task_id']),
      title: _readString(json['title']),
      description: _readString(json['description']),
      status: _readString(json['status'], fallback: 'todo'),
      assignedMemberId: _readString(json['assigned_member_id']),
      assignedToName: _readString(json['assigned_to_name']),
      assignedToEmail: _readString(json['assigned_to_email']),
      createdByMemberId: _readString(json['created_by_member_id']),
      createdByName: _readString(json['created_by_name']),
      createdByEmail: _readString(json['created_by_email']),
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
      'status': status,
      'assigned_member_id': assignedMemberId,
      'assigned_to_email': assignedToEmail,
      'assigned_to_name': assignedToName,
      'created_by_member_id': createdByMemberId,
      'created_by_name': createdByName,
      'created_by_email': createdByEmail,
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
    String? status,
    String? assignedMemberId,
    String? assignedToName,
    String? assignedToEmail,
    String? createdByMemberId,
    String? createdByName,
    String? createdByEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return SubtaskModel(
      id: id ?? this.id,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      createdByMemberId: createdByMemberId ?? this.createdByMemberId,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }
    return text;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
