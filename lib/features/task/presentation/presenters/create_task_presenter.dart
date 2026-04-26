import '../../../../core/result/result.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/task_model.dart';
import '../../domain/models/task_skill_requirement_model.dart';

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
    required List<TaskSkillRequirementInput> skillRequirements,
  }) {
    return _repository.createTask(
      projectId: projectId,
      title: title,
      description: description,
      estimatedHours: estimatedHours,
      priority: priority,
      skillRequirements: skillRequirements,
    );
  }

  Future<Result<List<TaskSkillOptionModel>>> fetchActiveSkills() {
    return _repository.fetchActiveSkills();
  }

  Future<bool> canManageTasks({
    bool refresh = false,
  }) {
    return _repository.canManageTasks(refresh: refresh);
  }
}
