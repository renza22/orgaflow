import '../../../auth/domain/models/profile_model.dart';
import '../../../organization/domain/models/member_model.dart';
import 'onboarding_master_data.dart';
import 'portfolio_link_input.dart';
import 'selected_skill_input.dart';

class OnboardingInitialData {
  const OnboardingInitialData({
    required this.masterData,
    required this.member,
    this.profile,
    this.portfolioLinks = const [],
    this.skills = const [],
  });

  final OnboardingMasterData masterData;
  final ProfileModel? profile;
  final MemberModel member;
  final List<PortfolioLinkInput> portfolioLinks;
  final List<SelectedSkillInput> skills;
}
