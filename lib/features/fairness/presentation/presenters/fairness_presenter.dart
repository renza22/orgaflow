import '../../../../core/result/result.dart';
import '../../data/repositories/fairness_repository.dart';
import '../../domain/models/burnout_alert_model.dart';
import '../../domain/models/fairness_summary_model.dart';
import '../../domain/models/fairness_trend_model.dart';
import '../../domain/models/member_fairness_breakdown_model.dart';
import '../../models/rebalance_model.dart';

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

  Future<Result<List<BurnoutAlertModel>>> getCriticalBurnoutAlerts({
    required String organizationId,
  }) {
    return _repository.getCriticalBurnoutAlerts(
      organizationId: organizationId,
    );
  }

  Future<Result<List<RebalanceItem>>> generateAutoRebalancePlan({
    required String organizationId,
    int maxItems = 5,
    String? projectId,
  }) {
    return _repository.generateAutoRebalancePlan(
      organizationId: organizationId,
      maxItems: maxItems,
      projectId: projectId,
    );
  }

  Future<Result<Map<String, dynamic>>> executeRebalancePlan({
    required String planId,
    required List<String> itemIds,
  }) {
    return _repository.executeRebalancePlan(
      planId: planId,
      itemIds: itemIds,
    );
  }
}
