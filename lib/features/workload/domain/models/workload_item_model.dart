class WorkloadItemModel {
  const WorkloadItemModel({
    required this.memberId,
    required this.organizationId,
    required this.profileId,
    required this.fullName,
    this.positionCode,
    this.positionLabel,
    this.divisionCode,
    this.divisionLabel,
    required this.weeklyCapacityHours,
    required this.assignedHours,
    required this.loadRatio,
    required this.workloadStatus,
  });

  final String memberId;
  final String organizationId;
  final String profileId;
  final String fullName;
  final String? positionCode;
  final String? positionLabel;
  final String? divisionCode;
  final String? divisionLabel;
  final int weeklyCapacityHours;
  final int assignedHours;
  final double loadRatio;
  final String workloadStatus;

  factory WorkloadItemModel.fromJson(Map<String, dynamic> json) {
    return WorkloadItemModel(
      memberId: json['member_id'] as String,
      organizationId: json['organization_id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Tanpa Nama',
      positionCode: json['position_code'] as String?,
      positionLabel: json['position_label'] as String?,
      divisionCode: json['division_code'] as String?,
      divisionLabel: json['division_label'] as String?,
      weeklyCapacityHours:
          (json['weekly_capacity_hours'] as num?)?.toInt() ?? 0,
      assignedHours: (json['assigned_hours'] as num?)?.toInt() ?? 0,
      loadRatio: (json['load_ratio'] as num?)?.toDouble() ?? 0,
      workloadStatus: json['workload_status'] as String? ?? 'safe',
    );
  }
}
