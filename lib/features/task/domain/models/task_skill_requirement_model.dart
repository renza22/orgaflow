class TaskSkillRequirementModel {
  const TaskSkillRequirementModel({
    required this.skillId,
    required this.skillName,
    required this.minimumLevel,
    required this.priorityWeight,
  });

  final String skillId;
  final String skillName;
  final int minimumLevel;
  final num priorityWeight;

  factory TaskSkillRequirementModel.fromJson(Map<String, dynamic> json) {
    return TaskSkillRequirementModel.fromRequirementRow(json);
  }

  factory TaskSkillRequirementModel.fromRequirementRow(
    Map<String, dynamic> json,
  ) {
    return TaskSkillRequirementModel(
      skillId: _readString(json, const ['skill_id', 'skillId']) ?? '',
      skillName: _readString(json, const ['skill_name', 'skillName', 'name']) ??
          _extractSkillName(json['skills'] ?? json['skill']),
      minimumLevel: _parseInt(
        json['minimum_level'] ?? json['minimumLevel'],
        1,
      ),
      priorityWeight: _parseNum(
        json['priority_weight'] ?? json['priorityWeight'],
        1,
      ),
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  factory TaskSkillRequirementModel.fromSkillOption(
    TaskSkillOptionModel skill, {
    int minimumLevel = 1,
    num priorityWeight = 1,
  }) {
    return TaskSkillRequirementModel(
      skillId: skill.skillId,
      skillName: skill.skillName,
      minimumLevel: minimumLevel,
      priorityWeight: priorityWeight,
    );
  }

  static String _extractSkillName(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['name'] as String? ?? '';
    }

    if (value is Map) {
      return value['name'] as String? ?? '';
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        return first['name'] as String? ?? '';
      }
      if (first is Map) {
        return first['name'] as String? ?? '';
      }
    }

    return '';
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

  static num _parseNum(dynamic value, num fallback) {
    if (value is num) {
      return value;
    }

    if (value is String) {
      return num.tryParse(value) ?? fallback;
    }

    return fallback;
  }
}

class TaskSkillRequirementInput {
  const TaskSkillRequirementInput({
    required this.skillId,
    this.minimumLevel = 1,
    this.priorityWeight = 1,
  });

  final String skillId;
  final int minimumLevel;
  final num priorityWeight;

  Map<String, dynamic> toJson() {
    return {
      'skill_id': skillId,
      'minimum_level': minimumLevel,
      'priority_weight': priorityWeight,
    };
  }
}

class TaskSkillOptionModel {
  const TaskSkillOptionModel({
    required this.skillId,
    required this.skillName,
    required this.categoryCode,
    required this.isActive,
  });

  final String skillId;
  final String skillName;
  final String categoryCode;
  final bool isActive;

  String get id => skillId;
  String get name => skillName;

  factory TaskSkillOptionModel.fromJson(Map<String, dynamic> json) {
    return TaskSkillOptionModel.fromSkillRow(json);
  }

  factory TaskSkillOptionModel.fromSkillRow(Map<String, dynamic> json) {
    return TaskSkillOptionModel(
      skillId: json['id'] as String? ?? '',
      skillName: json['name'] as String? ?? '',
      categoryCode: json['category_code'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  bool get hasValidIdentity => skillId.isNotEmpty && skillName.isNotEmpty;
}
