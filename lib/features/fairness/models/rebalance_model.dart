class RebalanceItem {
  final String id;
  final String planId;
  final String taskId;
  final String taskTitle;
  final String taskStatus;
  final int estimatedHours;
  final String fromMemberId;
  final String fromMember;
  final double fromLoadPercentage;
  final double fromAssignedHours;
  final double fromCapacityHours;
  final String toMemberId;
  final String toMember;
  final double toCurrentLoadPercentage;
  final double toProjectedLoadPercentage;
  final double toAssignedHours;
  final double toCapacityHours;
  final int matchingSkillCount;
  final List<String> matchedSkills;
  final double scoreBefore;
  final double scoreAfter;
  final String reason;
  final String status;
  bool? approved;

  RebalanceItem({
    required this.id,
    required this.planId,
    required this.taskId,
    required this.taskTitle,
    required this.taskStatus,
    required this.estimatedHours,
    required this.fromMemberId,
    required this.fromMember,
    required this.fromLoadPercentage,
    required this.fromAssignedHours,
    required this.fromCapacityHours,
    required this.toMemberId,
    required this.toMember,
    required this.toCurrentLoadPercentage,
    required this.toProjectedLoadPercentage,
    required this.toAssignedHours,
    required this.toCapacityHours,
    required this.matchingSkillCount,
    required this.matchedSkills,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.reason,
    required this.status,
    this.approved,
  });

  factory RebalanceItem.fromJson(Map<String, dynamic> json) {
    return RebalanceItem(
      id: _readString(json['item_id']),
      planId: _readString(json['plan_id']),
      taskId: _readString(json['task_id']),
      taskTitle: _readString(json['task_title']),
      taskStatus: _readString(json['task_status']),
      estimatedHours: _readInt(json['estimated_hours']),
      fromMemberId: _readString(json['from_member_id']),
      fromMember: _readString(json['from_member_name']),
      fromLoadPercentage: _readDouble(json['from_load_percentage']),
      fromAssignedHours: _readDouble(json['from_assigned_hours']),
      fromCapacityHours: _readDouble(json['from_capacity_hours']),
      toMemberId: _readString(json['to_member_id']),
      toMember: _readString(json['to_member_name']),
      toCurrentLoadPercentage: _readDouble(json['to_current_load_percentage']),
      toProjectedLoadPercentage:
          _readDouble(json['to_projected_load_percentage']),
      toAssignedHours: _readDouble(json['to_assigned_hours']),
      toCapacityHours: _readDouble(json['to_capacity_hours']),
      matchingSkillCount: _readInt(json['matching_skill_count']),
      matchedSkills: _readStringList(json['matched_skills']),
      scoreBefore: _readDouble(json['score_before']),
      scoreAfter: _readDouble(json['score_after']),
      reason: _readString(json['recommendation_reason']),
      status: _readString(json['item_status']),
      approved: null,
    );
  }

  String get fromInitials => _initials(fromMember);

  String get toInitials => _initials(toMember);

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
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

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return 0;
    }

    return int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? 0;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return const [];
    }

    if (text.startsWith('{') && text.endsWith('}')) {
      final body = text.substring(1, text.length - 1).trim();
      if (body.isEmpty) {
        return const [];
      }

      return body
          .split(',')
          .map((item) => item.trim().replaceAll('"', ''))
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [text];
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}
