import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_service.dart';
import '../../domain/models/onboarding_initial_data.dart';
import '../../domain/models/onboarding_submission.dart';
import '../datasources/onboarding_remote_datasource.dart';

class OnboardingRepository {
  OnboardingRepository({
    OnboardingRemoteDatasource? remoteDatasource,
    SessionService? sessionServiceOverride,
  })  : _remoteDatasource = remoteDatasource ?? OnboardingRemoteDatasource(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final OnboardingRemoteDatasource _remoteDatasource;
  final SessionService _sessionService;

  Future<Result<OnboardingInitialData>> loadInitialData() async {
    try {
      final context = await _sessionService.getCurrentContext(refresh: true);

      if (context == null) {
        return Result<OnboardingInitialData>.failure(
          const AppError('User belum login.'),
        );
      }

      final member = context.activeMember;
      if (member == null) {
        return Result<OnboardingInitialData>.failure(
          const AppError(
            'User belum punya membership aktif. Silakan pilih organisasi terlebih dahulu.',
          ),
        );
      }

      final masterData = await _remoteDatasource.fetchMasterData();
      final profile = context.profile ??
          await _remoteDatasource.fetchProfile(context.userId);
      final freshMember =
          await _remoteDatasource.fetchMember(member.id) ?? member;
      final portfolioLinks =
          await _remoteDatasource.fetchPortfolioLinks(context.userId);
      final memberSkills =
          await _remoteDatasource.fetchMemberSkills(freshMember.id);

      return Result<OnboardingInitialData>.success(
        OnboardingInitialData(
          masterData: masterData,
          profile: profile,
          member: freshMember,
          portfolioLinks: portfolioLinks,
          skills: memberSkills,
        ),
      );
    } catch (error) {
      return Result<OnboardingInitialData>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> submitOnboarding(
    OnboardingSubmission submission,
  ) async {
    try {
      final context = await _sessionService.getCurrentContext(refresh: true);

      if (context == null || context.activeMember == null) {
        return Result<void>.failure(
          const AppError('User belum memiliki membership aktif.'),
        );
      }

      await _remoteDatasource.submitOnboarding(
        profileId: context.userId,
        memberId: context.activeMember!.id,
        submission: submission,
      );

      await _sessionService.clearCache();
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }
}
