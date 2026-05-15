class MemberFairnessBreakdownModel {
  const MemberFairnessBreakdownModel({
    required this.organizationId,
    required this.memberId,
    required this.profileId,
    required this.fullName,
    required this.positionCode,
    required this.divisionCode,
    required this.weeklyCapacityHours,
    required this.assignedHours,
    required this.activeTaskCount,
    required this.loadRatio,
    required this.loadPercentage,
    required this.workloadStatus,
    required this.averageLoadRatio,
    required this.deviationRatio,
    required this.deviationPercentage,
    required this.individualFairnessScore,
    required this.organizationFairnessScore,
  });

  final String organizationId;
  final String memberId;
  final String profileId;
  final String fullName;
  final String? positionCode;
  final String? divisionCode;
  final double weeklyCapacityHours;
  final double assignedHours;
  final int activeTaskCount;
  final double loadRatio;
  final double loadPercentage;
  final String workloadStatus;
  final double averageLoadRatio;
  final double deviationRatio;
  final double deviationPercentage;
  final double individualFairnessScore;
  final double organizationFairnessScore;

  factory MemberFairnessBreakdownModel.fromJson(Map<String, dynamic> json) {
    return MemberFairnessBreakdownModel(
      organizationId: json['organization_id']?.toString() ?? '',
      memberId: json['member_id']?.toString() ?? '',
      profileId: json['profile_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      positionCode: _emptyToNull(json['position_code']?.toString()),
      divisionCode: _emptyToNull(json['division_code']?.toString()),
      weeklyCapacityHours: _readDouble(json['weekly_capacity_hours']),
      assignedHours: _readDouble(json['assigned_hours']),
      activeTaskCount: _readInt(json['active_task_count']),
      loadRatio: _readDouble(json['load_ratio']),
      loadPercentage: _readDouble(json['load_percentage']),
      workloadStatus: json['workload_status']?.toString() ?? 'safe',
      averageLoadRatio: _readDouble(json['average_load_ratio']),
      deviationRatio: _readDouble(json['deviation_ratio']),
      deviationPercentage: _readDouble(json['deviation_percentage']),
      individualFairnessScore: _clampScore(
        _readDouble(json['individual_fairness_score']),
      ),
      organizationFairnessScore: _clampScore(
        _readDouble(json['organization_fairness_score']),
      ),
    );
  }

  String get displayName {
    final normalized = fullName.trim();
    return normalized.isEmpty ? 'Tanpa Nama' : normalized;
  }

  double get absoluteDeviationPercentage => deviationPercentage.abs();

  bool get hasCapacity => weeklyCapacityHours > 0;

  static String? _emptyToNull(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return num.tryParse(value?.toString() ?? '')?.toInt() ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _clampScore(double value) {
    return value.clamp(0.0, 100.0).toDouble();
  }
}
