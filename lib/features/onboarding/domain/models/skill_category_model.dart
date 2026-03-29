import 'skill_model.dart';

class SkillCategoryModel {
  const SkillCategoryModel({
    required this.code,
    required this.label,
    this.skills = const [],
  });

  final String code;
  final String label;
  final List<SkillModel> skills;

  SkillCategoryModel copyWith({
    List<SkillModel>? skills,
  }) {
    return SkillCategoryModel(
      code: code,
      label: label,
      skills: skills ?? this.skills,
    );
  }

  factory SkillCategoryModel.fromJson(Map<String, dynamic> json) {
    return SkillCategoryModel(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}
