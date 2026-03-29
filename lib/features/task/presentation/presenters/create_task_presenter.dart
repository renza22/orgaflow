import '../../../../core/result/result.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/task_model.dart';

class CreateTaskPresenter {
  CreateTaskPresenter({
    TaskRepository? repository,
  }) : _repository = repository ?? TaskRepository();

  final TaskRepository _repository;

  Future<Result<TaskModel>> createTask({
    required String projectId,
    required String title,
    required String description,
    required int estimatedHours,
    required String priority,
  }) {
    return _repository.createTask(
      projectId: projectId,
      title: title,
      description: description,
      estimatedHours: estimatedHours,
      priority: priority,
    );
  }
}
