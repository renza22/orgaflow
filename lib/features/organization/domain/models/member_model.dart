class MemberModel {
  const MemberModel({
    required this.id,
    required this.profileId,
    required this.organizationId,
    required this.role,
    this.positionCode,
    this.divisionCode,
    required this.weeklyCapacityHours,
    required this.capacityUsedHours,
    required this.availabilityStatus,
    required this.status,
    this.joinedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String profileId;
  final String organizationId;
  final String role;
  final String? positionCode;
  final String? divisionCode;
  final int weeklyCapacityHours;
  final int capacityUsedHours;
  final String availabilityStatus;
  final String status;
  final DateTime? joinedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOwner => role == 'owner' || positionCode == 'ketua_umum';

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String? ?? '',
      organizationId: json['organization_id'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      positionCode: json['position_code'] as String?,
      divisionCode: json['division_code'] as String?,
      weeklyCapacityHours:
          (json['weekly_capacity_hours'] as num?)?.toInt() ?? 0,
      capacityUsedHours: (json['capacity_used_hours'] as num?)?.toInt() ?? 0,
      availabilityStatus: json['availability_status'] as String? ?? 'available',
      status: json['status'] as String? ?? 'active',
      joinedAt: _parseDateTime(json['joined_at']),
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
