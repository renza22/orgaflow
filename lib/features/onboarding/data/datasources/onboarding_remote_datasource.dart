import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../../auth/domain/models/profile_model.dart';
import '../../../organization/domain/models/member_model.dart';
import '../../domain/models/master_option.dart';
import '../../domain/models/onboarding_master_data.dart';
import '../../domain/models/onboarding_submission.dart';
import '../../domain/models/portfolio_link_input.dart';
import '../../domain/models/selected_skill_input.dart';
import '../../domain/models/skill_category_model.dart';
import '../../domain/models/skill_model.dart';

class OnboardingRemoteDatasource {
  OnboardingRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<OnboardingMasterData> fetchMasterData() async {
    final responses = await Future.wait<dynamic>([
      _fetchMasterOptions('study_programs'),
      _fetchMasterOptions('position_templates'),
      _fetchMasterOptions('division_templates'),
      _fetchMasterOptions('portfolio_platforms'),
      _fetchSkillCategories(),
      _fetchSkills(),
    ]);

    final studyPrograms = responses[0] as List<MasterOption>;
    final positions = responses[1] as List<MasterOption>;
    final divisions = responses[2] as List<MasterOption>;
    final portfolioPlatforms = responses[3] as List<MasterOption>;
    final categories = responses[4] as List<SkillCategoryModel>;
    final skills = responses[5] as List<SkillModel>;

    final categoryMap = {
      for (final category in categories) category.code: <SkillModel>[],
    };

    for (final skill in skills) {
      categoryMap.putIfAbsent(skill.categoryCode, () => <SkillModel>[]);
      categoryMap[skill.categoryCode]!.add(skill);
    }

    final categoriesWithSkills = categories
        .map(
          (category) => category.copyWith(
            skills: categoryMap[category.code] ?? const [],
          ),
        )
        .toList();

    return OnboardingMasterData(
      studyPrograms: studyPrograms,
      positions: positions,
      divisions: divisions,
      portfolioPlatforms: portfolioPlatforms,
      skillCategories: categoriesWithSkills,
      skills: skills,
    );
  }

  Future<ProfileModel?> fetchProfile(String profileId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', profileId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return ProfileModel.fromJson(response);
  }

  Future<MemberModel?> fetchMember(String memberId) async {
    final response =
        await _client.from('members').select().eq('id', memberId).maybeSingle();

    if (response == null) {
      return null;
    }

    return MemberModel.fromJson(response);
  }

  Future<List<PortfolioLinkInput>> fetchPortfolioLinks(String profileId) async {
    final response = await _client
        .from('portfolio_links')
        .select('platform_code, url, sort_order')
        .eq('profile_id', profileId)
        .order('sort_order', ascending: true);

    return (response as List<dynamic>).map((json) {
      final item = json as Map<String, dynamic>;
      return PortfolioLinkInput(
        platformCode: item['platform_code'] as String? ?? '',
        url: item['url'] as String? ?? '',
        sortOrder: (item['sort_order'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<SelectedSkillInput>> fetchMemberSkills(String memberId) async {
    final response = await _client
        .from('member_skills')
        .select('skill_id, proficiency_level')
        .eq('member_id', memberId);

    return (response as List<dynamic>).map((json) {
      final item = json as Map<String, dynamic>;
      return SelectedSkillInput(
        skillId: item['skill_id'] as String,
        proficiencyLevel: (item['proficiency_level'] as num?)?.toInt() ?? 3,
      );
    }).toList();
  }

  Future<void> submitOnboarding({
    required String profileId,
    required String memberId,
    required OnboardingSubmission submission,
  }) async {
    final profilePayload = <String, dynamic>{
      'full_name': submission.fullName,
      'nim': submission.nim,
      'study_program_code': submission.studyProgramCode,
      'bio': submission.bio,
    };

    if (submission.avatarPath != null) {
      profilePayload['avatar_path'] = submission.avatarPath;
    }

    await _client.from('profiles').update(profilePayload).eq('id', profileId);

    await _client.from('members').update({
      'position_code': submission.positionCode,
      'division_code': submission.divisionCode,
      'weekly_capacity_hours': submission.weeklyCapacityHours,
      'availability_status': submission.availabilityStatus,
    }).eq('id', memberId);

    await _client.from('portfolio_links').delete().eq('profile_id', profileId);

    if (submission.portfolioLinks.isNotEmpty) {
      await _client.from('portfolio_links').insert(
            submission.portfolioLinks
                .map(
                  (item) => {
                    'profile_id': profileId,
                    'platform_code': item.platformCode,
                    'url': item.url,
                    'sort_order': item.sortOrder,
                  },
                )
                .toList(),
          );
    }

    await _client.from('member_skills').delete().eq('member_id', memberId);

    if (submission.skills.isNotEmpty) {
      await _client.from('member_skills').insert(
            submission.skills
                .map(
                  (item) => {
                    'member_id': memberId,
                    'skill_id': item.skillId,
                    'proficiency_level': item.proficiencyLevel,
                    'source': 'manual',
                  },
                )
                .toList(),
          );
    }

    await _client.from('profiles').update({
      'onboarding_completed': true,
    }).eq('id', profileId);
  }

  Future<List<MasterOption>> _fetchMasterOptions(String table) async {
    final response = await _client
        .from(table)
        .select('code, label')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List<dynamic>)
        .map((json) => MasterOption.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<SkillCategoryModel>> _fetchSkillCategories() async {
    final response = await _client
        .from('skill_categories')
        .select('code, label')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List<dynamic>)
        .map(
          (json) => SkillCategoryModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<SkillModel>> _fetchSkills() async {
    final response = await _client
        .from('skills')
        .select('id, category_code, name, description, is_active, sort_order')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List<dynamic>)
        .map((json) => SkillModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
