import '../../../../core/result/result.dart';
import '../../data/repositories/activity_log_repository.dart';
import '../../models/activity_log_model.dart';

class ActivityLogPresenter {
  ActivityLogPresenter({
    ActivityLogRepository? repository,
  }) : _repository = repository ?? ActivityLogRepository();

  final ActivityLogRepository _repository;

  Future<Result<List<ActivityLog>>> fetchActivityLogs({
    required String organizationId,
    int limit = 20,
    String? entityType,
    String? entityId,
  }) {
    return _repository.fetchActivityLogs(
      organizationId: organizationId,
      limit: limit,
      entityType: entityType,
      entityId: entityId,
    );
  }
}
