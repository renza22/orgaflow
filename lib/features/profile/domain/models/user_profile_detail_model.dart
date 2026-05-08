import 'profile_portfolio_link_model.dart';
import 'profile_skill_model.dart';
import 'profile_task_history_model.dart';
import 'profile_workload_trend_model.dart';

class UserProfileDetailModel {
  const UserProfileDetailModel({
    required this.memberId,
    required this.profileId,
    required this.organizationId,
    required this.fullName,
    required this.email,
    this.nim,
    this.studyProgramCode,
    this.studyProgramLabel,
    this.avatarPath,
    this.avatarSignedUrl,
    this.bio,
    required this.role,
    this.positionCode,
    this.positionLabel,
    this.divisionCode,
    this.divisionLabel,
    required this.weeklyCapacityHours,
    required this.assignedHours,
    required this.activeTaskCount,
    required this.loadRatio,
    required this.loadPercentage,
    required this.workloadStatus,
    required this.availabilityStatus,
    this.joinedAt,
    this.createdAt,
    this.updatedAt,
    this.fairnessScore,
    this.fairnessScoreDate,
    this.skills = const [],
    this.taskHistory = const [],
    this.workloadTrend = const [],
    this.portfolioLinks = const [],
  });

  final String memberId;
  final String profileId;
  final String organizationId;
  final String fullName;
  final String email;
  final String? nim;
  final String? studyProgramCode;
  final String? studyProgramLabel;
  final String? avatarPath;
  final String? avatarSignedUrl;
  final String? bio;
  final String role;
  final String? positionCode;
  final String? positionLabel;
  final String? divisionCode;
  final String? divisionLabel;
  final int weeklyCapacityHours;
  final int assignedHours;
  final int activeTaskCount;
  final double loadRatio;
  final double loadPercentage;
  final String workloadStatus;
  final String availabilityStatus;
  final DateTime? joinedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? fairnessScore;
  final DateTime? fairnessScoreDate;
  final List<ProfileSkillModel> skills;
  final List<ProfileTaskHistoryModel> taskHistory;
  final List<ProfileWorkloadTrendModel> workloadTrend;
  final List<ProfilePortfolioLinkModel> portfolioLinks;

  String get displayName {
    final value = fullName.trim();
    if (value.isNotEmpty) {
      return value;
    }
    return email.trim().isEmpty ? '-' : email.trim();
  }

  String get displayRole {
    final position = positionLabel ?? positionCode;
    if (position != null && position.trim().isNotEmpty) {
      return position;
    }

    switch (role.trim().toLowerCase()) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      case 'member':
        return 'Member';
      default:
        return role.trim().isEmpty ? '-' : role;
    }
  }

  String get displayDivision {
    final division = divisionLabel ?? divisionCode;
    if (division != null && division.trim().isNotEmpty) {
      return division;
    }
    return '-';
  }

  String get initials {
    final source = fullName.trim().isNotEmpty ? fullName : email;
    final parts = source
        .trim()
        .split(RegExp(r'\s+|@'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    return parts.map((part) => part[0].toUpperCase()).join();
  }

  double get progressValue => loadRatio.clamp(0.0, 1.0).toDouble();

  String get workloadStatusLabel {
    switch (workloadStatus.trim().toLowerCase()) {
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
        return workloadStatus.trim().isEmpty ? '-' : workloadStatus;
    }
  }
}
