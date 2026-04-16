class OrganizationModel {
  const OrganizationModel({
    required this.id,
    required this.name,
    this.slug,
    required this.typeCode,
    required this.inviteCode,
    this.description,
    this.logoPath,
    this.createdBy,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? slug;
  final String typeCode;
  final String inviteCode;
  final String? description;
  final String? logoPath;
  final String? createdBy;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      typeCode: json['type_code'] as String? ?? '',
      inviteCode: json['invite_code'] as String? ?? '',
      description: json['description'] as String?,
      logoPath: _parseOptionalString(json['logo_path']),
      createdBy: json['created_by'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
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

  static String? _parseOptionalString(dynamic value) {
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }
}
