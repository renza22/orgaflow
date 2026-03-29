import '../../../../core/result/result.dart';
import '../../data/repositories/project_repository.dart';
import '../../domain/models/project_model.dart';

class CreateProjectPresenter {
  CreateProjectPresenter({
    ProjectRepository? repository,
  }) : _repository = repository ?? ProjectRepository();

  final ProjectRepository _repository;

  Future<Result<ProjectModel>> createProject({
    required String name,
    required String description,
  }) {
    return _repository.createProject(
      name: name,
      description: description,
    );
  }
}
