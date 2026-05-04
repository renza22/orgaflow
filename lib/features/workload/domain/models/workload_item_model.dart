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
    this.activeTaskCount = 0,
    required this.loadRatio,
    this.loadPercentage,
    this.warningThreshold,
    this.criticalThreshold,
    this.overloadThreshold,
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
  final int activeTaskCount;
  final double loadRatio;
  final double? loadPercentage;
  final double? warningThreshold;
  final double? criticalThreshold;
  final double? overloadThreshold;
  final String workloadStatus;

  factory WorkloadItemModel.fromJson(Map<String, dynamic> json) {
    return WorkloadItemModel(
      memberId: json['member_id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      profileId: json['profile_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Tanpa Nama',
      positionCode: json['position_code'] as String?,
      positionLabel: json['position_label'] as String?,
      divisionCode: json['division_code'] as String?,
      divisionLabel: json['division_label'] as String?,
      weeklyCapacityHours: _readInt(json['weekly_capacity_hours']),
      assignedHours: _readInt(json['assigned_hours']),
      activeTaskCount: _readInt(json['active_task_count']),
      loadRatio: _readDouble(json['load_ratio']),
      loadPercentage: _readNullableDouble(json['load_percentage']),
      warningThreshold: _readNullableDouble(json['warning_threshold']),
      criticalThreshold: _readNullableDouble(json['critical_threshold']),
      overloadThreshold: _readNullableDouble(json['overload_threshold']),
      workloadStatus: _normalizeStatus(json['workload_status']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return num.tryParse(value?.toString() ?? '')?.toInt() ?? 0;
  }

  static double _readDouble(dynamic value) {
    return _readNullableDouble(value) ?? 0;
  }

  static double? _readNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static String _normalizeStatus(dynamic value) {
    final status = value?.toString().trim().toLowerCase();
    return status == null || status.isEmpty ? 'safe' : status;
  }
}
