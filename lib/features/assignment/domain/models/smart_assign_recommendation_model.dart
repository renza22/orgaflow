class SmartAssignRecommendationModel {
  const SmartAssignRecommendationModel({
    required this.taskId,
    required this.memberId,
    required this.profileId,
    required this.fullName,
    required this.positionCode,
    required this.positionLabel,
    required this.divisionCode,
    required this.divisionLabel,
    required this.weeklyCapacityHours,
    required this.currentAssignedHours,
    required this.taskEstimatedHours,
    required this.projectedAssignedHours,
    required this.currentLoadRatio,
    required this.projectedLoadRatio,
    required this.currentLoadPercentage,
    required this.projectedLoadPercentage,
    required this.workloadStatus,
    required this.activeTaskCount,
    required this.assignmentCount,
    required this.requiredSkillCount,
    required this.matchingSkillCount,
    required this.matchedSkills,
    required this.missingSkills,
    required this.skillScore,
    required this.capacityScore,
    required this.fairnessScore,
    required this.totalScore,
    required this.recommendationRank,
    required this.recommendationReason,
    required this.preemptiveAlertLevel,
    required this.preemptiveAlertMessage,
  });

  final String taskId;
  final String memberId;
  final String profileId;
  final String fullName;
  final String? positionCode;
  final String? positionLabel;
  final String? divisionCode;
  final String? divisionLabel;
  final int weeklyCapacityHours;
  final int currentAssignedHours;
  final int taskEstimatedHours;
  final int projectedAssignedHours;
  final double currentLoadRatio;
  final double projectedLoadRatio;
  final double currentLoadPercentage;
  final double projectedLoadPercentage;
  final String workloadStatus;
  final int activeTaskCount;
  final int assignmentCount;
  final int requiredSkillCount;
  final int matchingSkillCount;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final int skillScore;
  final int capacityScore;
  final int fairnessScore;
  final int totalScore;
  final int recommendationRank;
  final String recommendationReason;
  final String preemptiveAlertLevel;
  final String preemptiveAlertMessage;

  factory SmartAssignRecommendationModel.fromJson(Map<String, dynamic> json) {
    return SmartAssignRecommendationModel(
      taskId: _string(json['task_id']),
      memberId: _string(json['member_id']),
      profileId: _string(json['profile_id']),
      fullName: _string(json['full_name'], fallback: 'Tanpa Nama'),
      positionCode: _nullableString(json['position_code']),
      positionLabel: _nullableString(json['position_label']),
      divisionCode: _nullableString(json['division_code']),
      divisionLabel: _nullableString(json['division_label']),
      weeklyCapacityHours: _int(json['weekly_capacity_hours']),
      currentAssignedHours: _int(json['current_assigned_hours']),
      taskEstimatedHours: _int(json['task_estimated_hours']),
      projectedAssignedHours: _int(json['projected_assigned_hours']),
      currentLoadRatio: _double(json['current_load_ratio']),
      projectedLoadRatio: _double(json['projected_load_ratio']),
      currentLoadPercentage: _double(json['current_load_percentage']),
      projectedLoadPercentage: _double(json['projected_load_percentage']),
      workloadStatus: _string(json['workload_status'], fallback: 'safe'),
      activeTaskCount: _int(json['active_task_count']),
      assignmentCount: _int(json['assignment_count']),
      requiredSkillCount: _int(json['required_skill_count']),
      matchingSkillCount: _int(json['matching_skill_count']),
      matchedSkills: _stringList(json['matched_skills']),
      missingSkills: _stringList(json['missing_skills']),
      skillScore: _int(json['skill_score']),
      capacityScore: _int(json['capacity_score']),
      fairnessScore: _int(json['fairness_score']),
      totalScore: _int(json['total_score']),
      recommendationRank: _int(json['recommendation_rank']),
      recommendationReason: _string(
        json['recommendation_reason'],
        fallback: 'Rekomendasi backend tidak tersedia.',
      ),
      preemptiveAlertLevel: _string(
        json['preemptive_alert_level'],
        fallback: 'safe',
      ),
      preemptiveAlertMessage: _string(
        json['preemptive_alert_message'],
        fallback: 'Tidak ada alert beban kerja.',
      ),
    );
  }

  String get displayPosition {
    final label = positionLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }

    final code = positionCode?.trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }

    return '';
  }

  String get displayDivision {
    final label = divisionLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }

    final code = divisionCode?.trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }

    return '';
  }

  String get currentLoadLabel => '${_formatNumber(currentLoadPercentage)}%';

  String get projectedLoadLabel => '${_formatNumber(projectedLoadPercentage)}%';

  String get alertLabel {
    switch (preemptiveAlertLevel.toLowerCase()) {
      case 'safe':
        return 'Aman';
      case 'warning':
        return 'Warning';
      case 'critical':
        return 'Critical';
      case 'overload':
        return 'Overload';
      case 'no_capacity':
        return 'No Capacity';
      default:
        return preemptiveAlertLevel.trim().isEmpty
            ? 'Aman'
            : preemptiveAlertLevel;
    }
  }

  bool get isRiskyAlert {
    switch (preemptiveAlertLevel.toLowerCase()) {
      case 'critical':
      case 'overload':
      case 'no_capacity':
        return true;
      default:
        return false;
    }
  }

  static String _string(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }
    return text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static int _int(Object? value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    return num.tryParse(value.toString())?.toInt() ?? 0;
  }

  static double _double(Object? value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static List<String> _stringList(Object? value) {
    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final raw = value.toString().trim();
    if (raw.isEmpty || raw == '{}') {
      return const [];
    }

    return raw
        .replaceAll(RegExp(r'^\{|\}$'), '')
        .split(',')
        .map((item) => item.trim().replaceAll('"', ''))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String _formatNumber(double value) {
    if (!value.isFinite) {
      return '0';
    }

    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}
