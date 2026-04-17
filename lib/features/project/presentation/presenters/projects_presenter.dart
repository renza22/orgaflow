import '../../../../core/result/result.dart';
import '../../data/repositories/project_repository.dart';
import '../../domain/models/project_model.dart';

class ProjectsPresenter {
  ProjectsPresenter({
    ProjectRepository? repository,
  }) : _repository = repository ?? ProjectRepository();

  final ProjectRepository _repository;

  Future<Result<List<ProjectModel>>> fetchProjects() {
    return _repository.fetchProjects();
  }

  Future<Result<ProjectModel>> createProject({
    required String name,
    required String description,
    DateTime? endDate,
  }) {
    return _repository.createProject(
      name: name,
      description: description,
      endDate: endDate,
    );
  }

  Future<Result<ProjectModel>> updateProject({
    required String projectId,
    required String name,
    required String description,
    DateTime? endDate,
    String? status,
  }) {
    return _repository.updateProject(
      projectId: projectId,
      name: name,
      description: description,
      endDate: endDate,
      status: status,
    );
  }

  Future<Result<void>> deleteProject(String projectId) {
    return _repository.deleteProject(projectId);
  }

  Future<bool> canManageProjects({
    bool refresh = false,
  }) {
    return _repository.canManageProjects(refresh: refresh);
  }
}
