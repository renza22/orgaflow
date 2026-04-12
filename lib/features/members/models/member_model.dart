import 'package:flutter/material.dart';

enum MemberStatus { active, warning, overloaded }

class Member {
  final int id;
  final String name;
  final String role;
  final String email;
  final int capacityMax;
  final int capacityUsed;
  final List<String> skills;
  final MemberStatus status;
  final int tasksCount;

  Member({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.capacityMax,
    required this.capacityUsed,
    required this.skills,
    required this.status,
    required this.tasksCount,
  });

  double get loadRatio => (capacityUsed / capacityMax) * 100;

  String get initials {
    final names = name.split(' ');
    return names.map((n) => n[0]).join('');
  }

  StatusConfig get statusConfig {
    switch (status) {
      case MemberStatus.overloaded:
        return StatusConfig(
          color: Colors.red,
          label: 'Overload',
        );
      case MemberStatus.warning:
        return StatusConfig(
          color: Colors.orange,
          label: 'Warning',
        );
      case MemberStatus.active:
        return StatusConfig(
          color: Colors.green,
          label: 'Healthy',
        );
    }
  }
}

class StatusConfig {
  final Color color;
  final String label;

  StatusConfig({
    required this.color,
    required this.label,
  });
}
