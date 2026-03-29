class SkillModel {
  const SkillModel({
    required this.id,
    required this.categoryCode,
    required this.name,
    this.description,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String categoryCode;
  final String name;
  final String? description;
  final bool isActive;
  final int sortOrder;

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] as String,
      categoryCode: json['category_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
