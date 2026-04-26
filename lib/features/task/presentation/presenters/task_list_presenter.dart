import '../../../../core/result/result.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/task_model.dart';
import '../../domain/models/task_skill_requirement_model.dart';

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

  Future<Result<TaskModel>> updateTask({
    required String taskId,
    required String title,
    required String description,
    required int estimatedHours,
    required String priority,
    required List<TaskSkillRequirementInput> skillRequirements,
    DateTime? dueDate,
  }) {
    return _repository.updateTask(
      taskId: taskId,
      title: title,
      description: description,
      estimatedHours: estimatedHours,
      priority: priority,
      dueDate: dueDate,
      skillRequirements: skillRequirements,
    );
  }

  Future<Result<void>> deleteTask(String taskId) {
    return _repository.deleteTask(taskId);
  }

  Future<bool> canManageTasks({
    bool refresh = false,
  }) {
    return _repository.canManageTasks(refresh: refresh);
  }
}
