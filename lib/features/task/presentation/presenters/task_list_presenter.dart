import '../../../../core/result/result.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/task_model.dart';

class TaskListPresenter {
  TaskListPresenter({
    TaskRepository? repository,
  }) : _repository = repository ?? TaskRepository();

  final TaskRepository _repository;

  Future<Result<List<TaskModel>>> fetchTasks(String projectId) {
    return _repository.fetchTasks(projectId);
  }

  Future<Result<void>> updateTaskStatus({
    required String taskId,
    required String status,
  }) {
    return _repository.updateTaskStatus(
      taskId: taskId,
      status: status,
    );
  }

  Future<Result<void>> evaluateTaskStatuses(String projectId) {
    return _repository.evaluateTaskStatuses(projectId);
  }
}
