import 'package:flutter/material.dart';

enum MemberStatus { safe, warning, critical, overload, noCapacity }

class Member {
  Member({
    int? id,
    required this.memberId,
    required this.profileId,
    required this.name,
    required this.role,
    required this.email,
    this.positionCode,
    this.positionLabel,
    this.divisionCode,
    this.divisionLabel,
    this.avatarPath,
    this.avatarSignedUrl,
    required this.capacityMax,
    required this.capacityUsed,
    required this.skills,
    required this.activeTaskCount,
    required this.loadRatio,
    this.loadPercentage,
    required String workloadStatus,
  })  : id = id ?? _stableIntId(memberId),
        workloadStatus = _normalizeWorkloadStatus(workloadStatus),
        status = _statusFromWorkloadStatus(workloadStatus);

  final int id;
  final String memberId;
  final String profileId;
  final String name;
  final String role;
  final String email;
  final String? positionCode;
  final String? positionLabel;
  final String? divisionCode;
  final String? divisionLabel;
  final String? avatarPath;
  final String? avatarSignedUrl;
  final int capacityMax;
  final int capacityUsed;
  final List<String> skills;
  final int activeTaskCount;
  final double loadRatio;
  final double? loadPercentage;
  final String workloadStatus;
  final MemberStatus status;

  int get weeklyCapacityHours => capacityMax;
  int get assignedHours => capacityUsed;
  int get tasksCount => activeTaskCount;

  double get displayLoadPercentage => loadPercentage ?? loadRatio * 100;

  double get progressValue => loadRatio.clamp(0.0, 1.0).toDouble();

  String get displayRole {
    final position = positionLabel ?? positionCode;
    if (position != null && position.trim().isNotEmpty) {
      return position;
    }

    return _formatRole(role);
  }

  String get displayDivision {
    final division = divisionLabel ?? divisionCode;
    if (division != null && division.trim().isNotEmpty) {
      return division;
    }
    return '-';
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    return parts.map((part) => part[0].toUpperCase()).join();
  }

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final searchableText = [
      name,
      email,
      role,
      positionCode,
      positionLabel,
      divisionCode,
      divisionLabel,
      ...skills,
    ].whereType<String>().join(' ').toLowerCase();

    return searchableText.contains(normalizedQuery);
  }

  StatusConfig get statusConfig {
    switch (status) {
      case MemberStatus.overload:
        return StatusConfig(
          color: Colors.red.shade900,
          label: 'Overload',
        );
      case MemberStatus.critical:
        return StatusConfig(
          color: Colors.red.shade600,
          label: 'Critical',
        );
      case MemberStatus.warning:
        return StatusConfig(
          color: Colors.orange.shade700,
          label: 'Warning',
        );
      case MemberStatus.noCapacity:
        return StatusConfig(
          color: Colors.grey.shade600,
          label: 'No Capacity',
        );
      case MemberStatus.safe:
        return StatusConfig(
          color: Colors.green.shade700,
          label: 'Aman',
        );
    }
  }

  static int _stableIntId(String value) {
    final hash = value.hashCode;
    return hash < 0 ? -hash : hash;
  }

  static String _normalizeWorkloadStatus(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    return normalized.isEmpty ? 'safe' : normalized;
  }

  static MemberStatus _statusFromWorkloadStatus(String value) {
    switch (_normalizeWorkloadStatus(value)) {
      case 'overload':
        return MemberStatus.overload;
      case 'critical':
        return MemberStatus.critical;
      case 'warning':
        return MemberStatus.warning;
      case 'no_capacity':
        return MemberStatus.noCapacity;
      case 'safe':
      default:
        return MemberStatus.safe;
    }
  }

  static String _formatRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      case 'member':
        return 'Member';
      default:
        return role.trim().isEmpty ? 'Member' : role;
    }
  }
}

class StatusConfig {
  const StatusConfig({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;
}
