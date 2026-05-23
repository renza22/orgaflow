import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/burnout_alert_model.dart';
import '../../domain/models/fairness_summary_model.dart';
import '../../domain/models/fairness_trend_model.dart';
import '../../domain/models/member_fairness_breakdown_model.dart';
import '../../models/rebalance_model.dart';
import '../datasources/fairness_remote_datasource.dart';

class FairnessRepository {
  FairnessRepository({
    FairnessRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource = remoteDatasource ?? FairnessRemoteDatasource();

  final FairnessRemoteDatasource _remoteDatasource;

  Future<Result<FairnessSummaryModel?>> fetchOrganizationFairnessSummary({
    required String organizationId,
  }) async {
    try {
      final normalizedOrganizationId = organizationId.trim();
      if (normalizedOrganizationId.isEmpty) {
        return Result<FairnessSummaryModel?>.failure(
          const AppError('User belum memiliki organisasi aktif.'),
        );
      }

      final summary = await _remoteDatasource.fetchOrganizationFairnessSummary(
        normalizedOrganizationId,
      );
      return Result<FairnessSummaryModel?>.success(summary);
    } catch (error) {
      return Result<FairnessSummaryModel?>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<List<MemberFairnessBreakdownModel>>>
      fetchMemberFairnessBreakdown({
    required String organizationId,
  }) async {
    try {
      final normalizedOrganizationId = organizationId.trim();
      if (normalizedOrganizationId.isEmpty) {
        return Result<List<MemberFairnessBreakdownModel>>.failure(
          const AppError('User belum memiliki organisasi aktif.'),
        );
      }

      final breakdown = await _remoteDatasource.fetchMemberFairnessBreakdown(
        normalizedOrganizationId,
      );
      breakdown.sort(
        (left, right) => right.absoluteDeviationPercentage.compareTo(
          left.absoluteDeviationPercentage,
        ),
      );

      return Result<List<MemberFairnessBreakdownModel>>.success(breakdown);
    } catch (error) {
      return Result<List<MemberFairnessBreakdownModel>>.failure(
        ErrorMapper.map(error),
      );
    }
  }

  Future<Result<List<FairnessTrendModel>>> fetchOrganizationFairnessTrend({
    required String organizationId,
    int limit = 12,
  }) async {
    try {
      final normalizedOrganizationId = organizationId.trim();
      if (normalizedOrganizationId.isEmpty) {
        return Result<List<FairnessTrendModel>>.failure(
          const AppError('User belum memiliki organisasi aktif.'),
        );
      }

      final trend = await _remoteDatasource.fetchOrganizationFairnessTrend(
        normalizedOrganizationId,
        limit: limit,
      );
      return Result<List<FairnessTrendModel>>.success(trend);
    } catch (error) {
      return Result<List<FairnessTrendModel>>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> refreshOrganizationFairnessScores({
    required String organizationId,
    required DateTime scoreDate,
  }) async {
    try {
      final normalizedOrganizationId = organizationId.trim();
      if (normalizedOrganizationId.isEmpty) {
        return Result<void>.failure(
          const AppError('User belum memiliki organisasi aktif.'),
        );
      }

      await _remoteDatasource.refreshOrganizationFairnessScores(
        organizationId: normalizedOrganizationId,
        scoreDate: scoreDate,
      );
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<List<BurnoutAlertModel>>> getCriticalBurnoutAlerts({
    required String organizationId,
  }) async {
    try {
      final normalizedOrganizationId = organizationId.trim();
      if (normalizedOrganizationId.isEmpty) {
        return Result<List<BurnoutAlertModel>>.failure(
          const AppError('User belum memiliki organisasi aktif.'),
        );
      }

      final alerts = await _remoteDatasource.getCriticalBurnoutAlerts(
        normalizedOrganizationId,
      );
      return Result<List<BurnoutAlertModel>>.success(alerts);
    } catch (error) {
      return Result<List<BurnoutAlertModel>>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<List<RebalanceItem>>> generateAutoRebalancePlan({
    required String organizationId,
    int maxItems = 5,
    String? projectId,
  }) async {
    try {
      final normalizedOrganizationId = organizationId.trim();
      if (normalizedOrganizationId.isEmpty) {
        return Result<List<RebalanceItem>>.failure(
          const AppError('User belum memiliki organisasi aktif.'),
        );
      }

      final normalizedProjectId = projectId?.trim();
      final items = await _remoteDatasource.generateAutoRebalancePlan(
        organizationId: normalizedOrganizationId,
        maxItems: maxItems,
        projectId: normalizedProjectId == null || normalizedProjectId.isEmpty
            ? null
            : normalizedProjectId,
      );

      return Result<List<RebalanceItem>>.success(items);
    } catch (error) {
      return Result<List<RebalanceItem>>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<Map<String, dynamic>>> executeRebalancePlan({
    required String planId,
    required List<String> itemIds,
  }) async {
    try {
      final normalizedPlanId = planId.trim();
      if (normalizedPlanId.isEmpty) {
        return Result<Map<String, dynamic>>.failure(
          const AppError('Plan rebalance tidak valid.'),
        );
      }

      final normalizedItemIds = itemIds
          .map((itemId) => itemId.trim())
          .where((itemId) => itemId.isNotEmpty)
          .toList();

      if (normalizedItemIds.isEmpty) {
        return Result<Map<String, dynamic>>.failure(
          const AppError('Pilih minimal satu rekomendasi untuk dieksekusi.'),
        );
      }

      final result = await _remoteDatasource.executeRebalancePlan(
        planId: normalizedPlanId,
        itemIds: normalizedItemIds,
      );

      return Result<Map<String, dynamic>>.success(result);
    } catch (error) {
      return Result<Map<String, dynamic>>.failure(ErrorMapper.map(error));
    }
  }
}
