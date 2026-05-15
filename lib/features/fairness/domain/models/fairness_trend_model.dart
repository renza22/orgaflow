class FairnessTrendModel {
  const FairnessTrendModel({
    required this.organizationId,
    required this.scoreDate,
    required this.averageLoadPercentage,
    required this.stddevLoadPercentage,
    required this.fairnessScore,
    required this.safeCount,
    required this.warningCount,
    required this.overloadCount,
  });

  final String organizationId;
  final DateTime? scoreDate;
  final double averageLoadPercentage;
  final double stddevLoadPercentage;
  final double fairnessScore;
  final int safeCount;
  final int warningCount;
  final int overloadCount;

  factory FairnessTrendModel.fromJson(Map<String, dynamic> json) {
    return FairnessTrendModel(
      organizationId: json['organization_id']?.toString() ?? '',
      scoreDate: _parseDateTime(json['score_date']),
      averageLoadPercentage: _readDouble(json['average_load_percentage']),
      stddevLoadPercentage: _readDouble(json['stddev_load_percentage']),
      fairnessScore: _clampScore(_readDouble(json['fairness_score'])),
      safeCount: _readInt(json['safe_count']),
      warningCount: _readInt(json['warning_count']),
      overloadCount: _readInt(json['overload_count']),
    );
  }

  String get dateLabel {
    final date = scoreDate;
    if (date == null) {
      return '-';
    }

    return '${date.day}/${date.month}';
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

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
