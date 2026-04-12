import 'package:flutter/material.dart';

enum CapacityStatus { overloaded, warning, active }

class MemberCapacity {
  final String name;
  final String role;
  final int max;
  final int used;
  final CapacityStatus status;

  MemberCapacity({
    required this.name,
    required this.role,
    required this.max,
    required this.used,
    required this.status,
  });

  double get loadRatio => (used / max) * 100;

  String get initials {
    final names = name.split(' ');
    return names.map((n) => n[0]).join('');
  }

  StatusConfig get statusConfig {
    switch (status) {
      case CapacityStatus.overloaded:
        return StatusConfig(
          color: const Color(0xFFFF7675),
          label: 'Overload',
        );
      case CapacityStatus.warning:
        return StatusConfig(
          color: const Color(0xFFFDCB6E),
          label: 'Warning',
        );
      case CapacityStatus.active:
        return StatusConfig(
          color: const Color(0xFF00B894),
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
