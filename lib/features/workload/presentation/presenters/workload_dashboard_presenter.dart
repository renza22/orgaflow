import '../../../../core/result/result.dart';
import '../../data/repositories/workload_repository.dart';
import '../../domain/models/workload_item_model.dart';

class WorkloadDashboardPresenter {
  WorkloadDashboardPresenter({
    WorkloadRepository? repository,
  }) : _repository = repository ?? WorkloadRepository();

  final WorkloadRepository _repository;

  Future<Result<List<WorkloadItemModel>>> loadWorkload() {
    return _repository.fetchWorkload();
  }
}
