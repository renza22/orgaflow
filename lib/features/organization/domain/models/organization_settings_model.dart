class OrganizationSettingsModel {
  const OrganizationSettingsModel({
    required this.organizationId,
    required this.name,
    this.slug,
    required this.typeCode,
    required this.inviteCode,
    this.description,
    this.logoPath,
    this.periodLabel,
    this.semesterLabel,
    this.periodStartDate,
    this.periodEndDate,
    required this.isActive,
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.overloadThreshold,
    required this.burnoutAlertDays,
    required this.skillWeight,
    required this.capacityWeight,
    required this.fairnessWeight,
    this.updatedAt,
  });

  static const double defaultWarningThreshold = 0.70;
  static const double defaultCriticalThreshold = 0.90;
  static const double defaultOverloadThreshold = 1.00;
  static const int defaultBurnoutAlertDays = 14;
  static const double defaultSkillWeight = 0.40;
  static const double defaultCapacityWeight = 0.35;
  static const double defaultFairnessWeight = 0.25;

  final String organizationId;
  final String name;
  final String? slug;
  final String typeCode;
  final String inviteCode;
  final String? description;
  final String? logoPath;
  final String? periodLabel;
  final String? semesterLabel;
  final DateTime? periodStartDate;
  final DateTime? periodEndDate;
  final bool isActive;
  final double warningThreshold;
  final double criticalThreshold;
  final double overloadThreshold;
  final int burnoutAlertDays;
  final double skillWeight;
  final double capacityWeight;
  final double fairnessWeight;
  final DateTime? updatedAt;

  factory OrganizationSettingsModel.fromJson(Map<String, dynamic> json) {
    return OrganizationSettingsModel(
      organizationId: _parseRequiredString(json['organization_id']),
      name: _parseString(json['name']) ?? '',
      slug: _parseString(json['slug']),
      typeCode: _parseString(json['type_code']) ?? '',
      inviteCode: _parseString(json['invite_code']) ?? '',
      description: _parseString(json['description']),
      logoPath: _parseString(json['logo_path']),
      periodLabel: _parseString(json['period_label']),
      semesterLabel: _parseString(json['semester_label']),
      periodStartDate: _parseDateTime(json['period_start_date']),
      periodEndDate: _parseDateTime(json['period_end_date']),
      isActive: json['is_active'] as bool? ?? true,
      warningThreshold: _parseDouble(
        json['warning_threshold'],
        defaultWarningThreshold,
      ),
      criticalThreshold: _parseDouble(
        json['critical_threshold'],
        defaultCriticalThreshold,
      ),
      overloadThreshold: _parseDouble(
        json['overload_threshold'],
        defaultOverloadThreshold,
      ),
      burnoutAlertDays: _parseInt(
        json['burnout_alert_days'],
        defaultBurnoutAlertDays,
      ),
      skillWeight: _parseDouble(json['skill_weight'], defaultSkillWeight),
      capacityWeight: _parseDouble(
        json['capacity_weight'],
        defaultCapacityWeight,
      ),
      fairnessWeight: _parseDouble(
        json['fairness_weight'],
        defaultFairnessWeight,
      ),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static String _parseRequiredString(dynamic value) {
    return _parseString(value) ?? '';
  }

  static String? _parseString(dynamic value) {
    if (value == null) {
      return null;
    }

    final normalized = value.toString().trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static double _parseDouble(dynamic value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
