class ProfileSkillModel {
  const ProfileSkillModel({
    required this.name,
    required this.proficiencyLevel,
  });

  final String name;
  final int proficiencyLevel;

  String get proficiencyLabel {
    switch (proficiencyLevel.clamp(1, 5)) {
      case 1:
      case 2:
        return 'Beginner';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Intermediate';
    }
  }

  int get proficiencyPercent {
    switch (proficiencyLevel.clamp(1, 5)) {
      case 1:
        return 20;
      case 2:
        return 40;
      case 3:
        return 60;
      case 4:
        return 80;
      case 5:
        return 100;
      default:
        return 60;
    }
  }
}
