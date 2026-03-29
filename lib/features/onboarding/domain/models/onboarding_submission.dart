import 'portfolio_link_input.dart';
import 'selected_skill_input.dart';

class OnboardingSubmission {
  const OnboardingSubmission({
    required this.fullName,
    required this.nim,
    required this.studyProgramCode,
    required this.bio,
    required this.positionCode,
    required this.divisionCode,
    required this.weeklyCapacityHours,
    required this.availabilityStatus,
    required this.portfolioLinks,
    required this.skills,
    this.avatarPath,
  });

  final String fullName;
  final String nim;
  final String studyProgramCode;
  final String bio;
  final String? avatarPath;
  final String? positionCode;
  final String? divisionCode;
  final int weeklyCapacityHours;
  final String availabilityStatus;
  final List<PortfolioLinkInput> portfolioLinks;
  final List<SelectedSkillInput> skills;
}
