import 'master_option.dart';
import 'skill_category_model.dart';
import 'skill_model.dart';

class OnboardingMasterData {
  const OnboardingMasterData({
    required this.studyPrograms,
    required this.positions,
    required this.divisions,
    required this.portfolioPlatforms,
    required this.skillCategories,
    required this.skills,
  });

  final List<MasterOption> studyPrograms;
  final List<MasterOption> positions;
  final List<MasterOption> divisions;
  final List<MasterOption> portfolioPlatforms;
  final List<SkillCategoryModel> skillCategories;
  final List<SkillModel> skills;

  SkillCategoryModel? findCategoryByLabel(String label) {
    for (final category in skillCategories) {
      if (category.label == label) {
        return category;
      }
    }
    return null;
  }

  SkillModel? findSkillByName(String name) {
    for (final skill in skills) {
      if (skill.name == name) {
        return skill;
      }
    }
    return null;
  }
}
