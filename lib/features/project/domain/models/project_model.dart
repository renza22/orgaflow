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
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
