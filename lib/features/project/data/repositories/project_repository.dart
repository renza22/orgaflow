import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_context.dart';
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

  Future<Result<List<ProjectModel>>> fetchProjects() async {
    try {
      final context = await _requireActiveContext();
      final projects = await _remoteDatasource.fetchProjects(
        organizationId: context.activeMember!.organizationId,
      );

      return Result<List<ProjectModel>>.success(projects);
    } catch (error) {
      return Result<List<ProjectModel>>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<ProjectModel>> createProject({
    required String name,
    required String description,
    DateTime? endDate,
  }) async {
    try {
      final context = await _requireManageContext();
      final organizationId = _resolveOrganizationId(context);
      final createdBy = _resolveCreatedBy(context);

      final project = await _remoteDatasource.createProject(
        organizationId: organizationId,
        createdBy: createdBy,
        name: name,
        description: description,
        endDate: endDate,
      );

      return Result<ProjectModel>.success(project);
    } catch (error) {
      return Result<ProjectModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<ProjectModel>> updateProject({
    required String projectId,
    required String name,
    required String description,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      await _requireManageContext();

      final project = await _remoteDatasource.updateProject(
        projectId: projectId,
        name: name,
        description: description,
        endDate: endDate,
        status: status,
      );

      return Result<ProjectModel>.success(project);
    } catch (error) {
      return Result<ProjectModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> deleteProject(String projectId) async {
    try {
      await _requireManageContext();
      await _remoteDatasource.deleteProject(projectId: projectId);
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<bool> canManageProjects({
    bool refresh = false,
  }) async {
    final context = await _sessionService.getCurrentContext(refresh: refresh);
    return _canManageContext(context);
  }

  bool _canManageContext(SessionContext? context) {
    final activeMember = context?.activeMember;
    if (activeMember == null) {
      return false;
    }

    return activeMember.isOwner || activeMember.role == 'admin';
  }

  Future<SessionContext> _requireActiveContext() async {
    final context = await _sessionService.getCurrentContext(refresh: true);

    if (context == null || context.activeMember == null) {
      throw const AppError('User belum memiliki membership aktif.');
    }

    return context;
  }

  Future<SessionContext> _requireManageContext() async {
    final context = await _requireActiveContext();

    if (!_canManageContext(context)) {
      throw const AppError(
        'Anda tidak memiliki izin untuk mengelola proyek.',
      );
    }

    return context;
  }

  String _resolveOrganizationId(SessionContext context) {
    final organizationId =
        context.organization?.id ?? context.activeMember?.organizationId ?? '';

    if (organizationId.trim().isEmpty) {
      throw const AppError('Organisasi aktif tidak ditemukan.');
    }

    return organizationId;
  }

  String _resolveCreatedBy(SessionContext context) {
    final userId = _sessionService.currentUserId ?? context.userId;

    if (userId.trim().isEmpty) {
      throw const AppError('User belum login.');
    }

    return userId;
  }
}
