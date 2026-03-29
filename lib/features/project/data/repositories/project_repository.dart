import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_service.dart';
import '../../domain/models/project_model.dart';
import '../datasources/project_remote_datasource.dart';

class ProjectRepository {
  ProjectRepository({
    ProjectRemoteDatasource? remoteDatasource,
    SessionService? sessionServiceOverride,
  })  : _remoteDatasource = remoteDatasource ?? ProjectRemoteDatasource(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final ProjectRemoteDatasource _remoteDatasource;
  final SessionService _sessionService;

  Future<Result<ProjectModel>> createProject({
    required String name,
    required String description,
  }) async {
    try {
      final context = await _sessionService.getCurrentContext(refresh: true);

      if (context == null || context.activeMember == null) {
        return Result<ProjectModel>.failure(
          const AppError('User belum memiliki membership aktif.'),
        );
      }

      final project = await _remoteDatasource.createProject(
        organizationId: context.activeMember!.organizationId,
        createdBy: context.userId,
        name: name,
        description: description,
      );

      return Result<ProjectModel>.success(project);
    } catch (error) {
      return Result<ProjectModel>.failure(ErrorMapper.map(error));
    }
  }
}
