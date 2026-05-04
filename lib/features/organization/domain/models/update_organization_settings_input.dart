class UpdateOrganizationSettingsInput {
  const UpdateOrganizationSettingsInput({
    required this.organizationId,
    required this.name,
    required this.typeCode,
    this.description,
    this.periodLabel,
    this.semesterLabel,
    this.periodStartDate,
    this.periodEndDate,
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.overloadThreshold,
    required this.burnoutAlertDays,
    required this.skillWeight,
    required this.capacityWeight,
    required this.fairnessWeight,
  });

  final String organizationId;
  final String name;
  final String typeCode;
  final String? description;
  final String? periodLabel;
  final String? semesterLabel;
  final DateTime? periodStartDate;
  final DateTime? periodEndDate;
  final double warningThreshold;
  final double criticalThreshold;
  final double overloadThreshold;
  final int burnoutAlertDays;
  final double skillWeight;
  final double capacityWeight;
  final double fairnessWeight;

  Map<String, dynamic> toRpcParams() {
    return {
      'p_organization_id': organizationId,
      'p_name': name,
      'p_type_code': typeCode,
      'p_description': description,
      'p_period_label': periodLabel,
      'p_semester_label': semesterLabel,
      'p_period_start_date': _formatDate(periodStartDate),
      'p_period_end_date': _formatDate(periodEndDate),
      'p_warning_threshold': warningThreshold,
      'p_critical_threshold': criticalThreshold,
      'p_overload_threshold': overloadThreshold,
      'p_burnout_alert_days': burnoutAlertDays,
      'p_skill_weight': skillWeight,
      'p_capacity_weight': capacityWeight,
      'p_fairness_weight': fairnessWeight,
    };
  }

  static String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }

    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
