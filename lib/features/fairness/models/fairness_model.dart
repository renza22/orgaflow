import 'package:flutter/material.dart';

class MemberWorkload {
  final String name;
  final int load;
  final int fairness;
  final WorkloadStatus status;
  final String id;

  MemberWorkload({
    required this.name,
    required this.load,
    required this.fairness,
    required this.status,
    required this.id,
  });

  Color get statusColor {
    switch (status) {
      case WorkloadStatus.red:
        return const Color(0xFFFF7675);
      case WorkloadStatus.yellow:
        return const Color(0xFFFDCB6E);
      case WorkloadStatus.green:
        return const Color(0xFF00B894);
    }
  }
}

enum WorkloadStatus { red, yellow, green }

class FairnessTrend {
  final String month;
  final int score;
  final String id;

  FairnessTrend({
    required this.month,
    required this.score,
    required this.id,
  });
}

class BurnoutAlert {
  final int id;
  final String member;
  final String issue;
  final AlertSeverity severity;
  final String action;

  BurnoutAlert({
    required this.id,
    required this.member,
    required this.issue,
    required this.severity,
    required this.action,
  });

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFFF7675);
      case AlertSeverity.warning:
        return const Color(0xFFFDCB6E);
    }
  }

  String get severityLabel {
    switch (severity) {
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.warning:
        return 'Warning';
    }
  }
}

enum AlertSeverity { critical, warning }
