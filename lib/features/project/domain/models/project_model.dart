class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    required this.status,
    this.startDate,
    this.endDate,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.memberCount = 0,
  });

  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int totalTasks;
  final int completedTasks;
  final int memberCount;

  int get progress {
    if (totalTasks == 0) {
      return 0;
    }

    return ((completedTasks / totalTasks) * 100).round();
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'draft',
      startDate: _parseDateTime(json['start_date']),
      endDate: _parseDateTime(json['end_date']),
      createdBy: json['created_by'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    );
  }

  ProjectModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalTasks,
    int? completedTasks,
    int? memberCount,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
