class BurnoutAlertModel {
  const BurnoutAlertModel({
    required this.alertId,
    required this.organizationId,
    required this.memberId,
    required this.fullName,
    this.positionCode,
    this.divisionCode,
    required this.assignedHours,
    required this.weeklyCapacityHours,
    required this.loadRatio,
    required this.loadPercentage,
    required this.streakDays,
    required this.thresholdDays,
    this.firstRedDate,
    this.lastRedDate,
    this.triggeredAt,
    this.lastNotificationAt,
  });

  final String alertId;
  final String organizationId;
  final String memberId;
  final String fullName;
  final String? positionCode;
  final String? divisionCode;
  final double assignedHours;
  final double weeklyCapacityHours;
  final double loadRatio;
  final double loadPercentage;
  final int streakDays;
  final int thresholdDays;
  final DateTime? firstRedDate;
  final DateTime? lastRedDate;
  final DateTime? triggeredAt;
  final DateTime? lastNotificationAt;

  factory BurnoutAlertModel.fromJson(Map<String, dynamic> json) {
    return BurnoutAlertModel(
      alertId: _readString(json['alert_id']),
      organizationId: _readString(json['organization_id']),
      memberId: _readString(json['member_id']),
      fullName: _readString(json['full_name'], fallback: 'Tanpa Nama'),
      positionCode: _readNullableString(json['position_code']),
      divisionCode: _readNullableString(json['division_code']),
      assignedHours: _readDouble(json['assigned_hours']),
      weeklyCapacityHours: _readDouble(json['weekly_capacity_hours']),
      loadRatio: _readDouble(json['load_ratio']),
      loadPercentage: _readDouble(json['load_percentage']),
      streakDays: _readInt(json['streak_days']),
      thresholdDays: _readInt(json['threshold_days']),
      firstRedDate: _readDateTime(json['first_red_date']),
      lastRedDate: _readDateTime(json['last_red_date']),
      triggeredAt: _readDateTime(json['triggered_at']),
      lastNotificationAt: _readDateTime(json['last_notification_at']),
    );
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }
    return text;
  }

  static String? _readNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}
