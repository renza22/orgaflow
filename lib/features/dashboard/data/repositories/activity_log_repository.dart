import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../models/activity_log_model.dart';
import '../datasources/activity_log_remote_datasource.dart';

class ActivityLogRepository {
  ActivityLogRepository({
    ActivityLogRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource = remoteDatasource ?? ActivityLogRemoteDatasource();

  final ActivityLogRemoteDatasource _remoteDatasource;

  Future<Result<List<ActivityLog>>> fetchActivityLogs({
    required String organizationId,
    int limit = 20,
    String? entityType,
    String? entityId,
  }) async {
    try {
      final normalizedOrganizationId = organizationId.trim();
      if (normalizedOrganizationId.isEmpty) {
        return Result<List<ActivityLog>>.failure(
          const AppError('User belum memiliki organisasi aktif.'),
        );
      }

      final normalizedEntityType = entityType?.trim();
      final normalizedEntityId = entityId?.trim();
      final activities = await _remoteDatasource.fetchActivityLogs(
        organizationId: normalizedOrganizationId,
        limit: limit,
        entityType: normalizedEntityType == null || normalizedEntityType.isEmpty
            ? null
            : normalizedEntityType,
        entityId: normalizedEntityId == null || normalizedEntityId.isEmpty
            ? null
            : normalizedEntityId,
      );

      return Result<List<ActivityLog>>.success(activities);
    } catch (error) {
      return Result<List<ActivityLog>>.failure(ErrorMapper.map(error));
    }
  }
}
