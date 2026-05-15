import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/fairness_summary_model.dart';
import '../../domain/models/fairness_trend_model.dart';
import '../../domain/models/member_fairness_breakdown_model.dart';
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
}
