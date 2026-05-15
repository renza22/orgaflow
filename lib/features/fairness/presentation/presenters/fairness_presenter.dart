import '../../../../core/result/result.dart';
import '../../data/repositories/fairness_repository.dart';
import '../../domain/models/fairness_summary_model.dart';
import '../../domain/models/fairness_trend_model.dart';
import '../../domain/models/member_fairness_breakdown_model.dart';

class FairnessPresenter {
  FairnessPresenter({
    FairnessRepository? repository,
  }) : _repository = repository ?? FairnessRepository();

  final FairnessRepository _repository;

  Future<Result<FairnessSummaryModel?>> fetchOrganizationFairnessSummary({
    required String organizationId,
  }) {
    return _repository.fetchOrganizationFairnessSummary(
      organizationId: organizationId,
    );
  }

  Future<Result<List<MemberFairnessBreakdownModel>>>
      fetchMemberFairnessBreakdown({
    required String organizationId,
  }) {
    return _repository.fetchMemberFairnessBreakdown(
      organizationId: organizationId,
    );
  }

  Future<Result<List<FairnessTrendModel>>> fetchOrganizationFairnessTrend({
    required String organizationId,
    int limit = 12,
  }) {
    return _repository.fetchOrganizationFairnessTrend(
      organizationId: organizationId,
      limit: limit,
    );
  }

  Future<Result<void>> refreshOrganizationFairnessScores({
    required String organizationId,
    required DateTime scoreDate,
  }) {
    return _repository.refreshOrganizationFairnessScores(
      organizationId: organizationId,
      scoreDate: scoreDate,
    );
  }
}
