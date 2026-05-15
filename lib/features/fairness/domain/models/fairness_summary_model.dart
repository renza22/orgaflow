class FairnessSummaryModel {
  const FairnessSummaryModel({
    required this.organizationId,
    required this.memberCount,
    required this.eligibleMemberCount,
    required this.noCapacityCount,
    required this.averageLoadRatio,
    required this.averageLoadPercentage,
    required this.stddevLoadRatio,
    required this.stddevLoadPercentage,
    required this.fairnessScore,
    required this.minLoadRatio,
    required this.maxLoadRatio,
    required this.safeCount,
    required this.warningCount,
    required this.overloadCount,
    required this.generatedAt,
  });

  final String organizationId;
  final int memberCount;
  final int eligibleMemberCount;
  final int noCapacityCount;
  final double averageLoadRatio;
  final double averageLoadPercentage;
  final double stddevLoadRatio;
  final double stddevLoadPercentage;
  final double fairnessScore;
  final double minLoadRatio;
  final double maxLoadRatio;
  final int safeCount;
  final int warningCount;
  final int overloadCount;
  final DateTime? generatedAt;

  factory FairnessSummaryModel.fromJson(Map<String, dynamic> json) {
    return FairnessSummaryModel(
      organizationId: json['organization_id']?.toString() ?? '',
      memberCount: _readInt(json['member_count']),
      eligibleMemberCount: _readInt(json['eligible_member_count']),
      noCapacityCount: _readInt(json['no_capacity_count']),
      averageLoadRatio: _readDouble(json['average_load_ratio']),
      averageLoadPercentage: _readDouble(json['average_load_percentage']),
      stddevLoadRatio: _readDouble(json['stddev_load_ratio']),
      stddevLoadPercentage: _readDouble(json['stddev_load_percentage']),
      fairnessScore: _clampScore(_readDouble(json['fairness_score'])),
      minLoadRatio: _readDouble(json['min_load_ratio']),
      maxLoadRatio: _readDouble(json['max_load_ratio']),
      safeCount: _readInt(json['safe_count']),
      warningCount: _readInt(json['warning_count']),
      overloadCount: _readInt(json['overload_count']),
      generatedAt: _parseDateTime(json['generated_at']),
    );
  }

  bool get isEmpty => memberCount <= 0 && eligibleMemberCount <= 0;

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

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
