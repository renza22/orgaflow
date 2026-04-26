import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_context.dart';
import '../../../../core/session/session_service.dart';
import '../../domain/models/task_model.dart';
import '../../domain/models/task_skill_requirement_model.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepository {
  TaskRepository({
    TaskRemoteDatasource? remoteDatasource,
    SessionService? sessionServiceOverride,
  })  : _remoteDatasource = remoteDatasource ?? TaskRemoteDatasource(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final TaskRemoteDatasource _remoteDatasource;
  final SessionService _sessionService;

  Future<Result<TaskModel>> createTask({
    required String projectId,
    required String title,
    required String description,
    required int estimatedHours,
    required String priority,
    required List<TaskSkillRequirementInput> skillRequirements,
  }) async {
    try {
      await _requireManageContext();

      if (title.trim().isEmpty) {
        return Result<TaskModel>.failure(
          const AppError('Judul task wajib diisi.'),
        );
      }

      if (estimatedHours <= 0) {
        return Result<TaskModel>.failure(
          const AppError('Estimasi jam wajib lebih dari 0.'),
        );
      }

      final validSkillRequirements =
          _normalizeSkillRequirements(skillRequirements);

      final task = await _remoteDatasource.createTask(
        projectId: projectId,
        title: title.trim(),
        description: description.trim(),
        estimatedHours: estimatedHours,
        priority: priority,
        skillRequirements: validSkillRequirements,
      );

      return Result<TaskModel>.success(task);
    } catch (error) {
      return Result<TaskModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<TaskModel>> updateTask({
    required String taskId,
    required String title,
    required String description,
    required int estimatedHours,
    required String priority,
    required List<TaskSkillRequirementInput> skillRequirements,
    DateTime? dueDate,
  }) async {
    try {
      await _requireManageContext();

      if (taskId.trim().isEmpty) {
        return Result<TaskModel>.failure(
          const AppError('Task tidak valid.'),
        );
      }

      if (title.trim().isEmpty) {
        return Result<TaskModel>.failure(
          const AppError('Judul task wajib diisi.'),
        );
      }

      if (estimatedHours <= 0) {
        return Result<TaskModel>.failure(
          const AppError('Estimasi jam wajib lebih dari 0.'),
        );
      }

      final validSkillRequirements =
          _normalizeSkillRequirements(skillRequirements);

      final task = await _remoteDatasource.updateTaskWithRequirements(
        taskId: taskId.trim(),
        title: title.trim(),
        description: description.trim(),
        estimatedHours: estimatedHours,
        priority: priority,
        dueDate: dueDate,
        skillRequirements: validSkillRequirements,
      );

      return Result<TaskModel>.success(task);
    } catch (error) {
      return Result<TaskModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> deleteTask(String taskId) async {
    try {
      await _requireManageContext();

      if (taskId.trim().isEmpty) {
        return Result<void>.failure(
          const AppError('Task tidak valid.'),
        );
      }

      await _remoteDatasource.deleteTask(taskId: taskId.trim());
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<List<TaskModel>>> fetchTasks(String projectId) async {
    try {
      final tasks = await _remoteDatasource.fetchTasks(projectId);
      final requirementsByTaskId =
          await _remoteDatasource.fetchSkillRequirementsForTasks(
        tasks.map((task) => task.id).toList(),
      );
      final tasksWithRequirements = tasks
          .map(
            (task) => task.copyWith(
              skillRequirements: requirementsByTaskId[task.id] ?? const [],
            ),
          )
          .toList();

      return Result<List<TaskModel>>.success(tasksWithRequirements);
    } catch (error) {
      return Result<List<TaskModel>>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<List<TaskSkillOptionModel>>> fetchActiveSkills() async {
    try {
      final skills = await _remoteDatasource.fetchActiveSkills();
      return Result<List<TaskSkillOptionModel>>.success(skills);
    } catch (error) {
      return Result<List<TaskSkillOptionModel>>.failure(
        ErrorMapper.map(error),
      );
    }
  }

  Future<Result<void>> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      await _requireManageContext();

      final normalizedTaskId = taskId.trim();
      if (normalizedTaskId.isEmpty) {
        return Result<void>.failure(
          const AppError('Task tidak valid.'),
        );
      }

      final normalizedStatus = _normalizeTaskStatus(status);

      await _remoteDatasource.updateTaskStatus(
        taskId: normalizedTaskId,
        status: normalizedStatus,
      );
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> evaluateTaskStatuses(String projectId) async {
    try {
      final tasks = await _remoteDatasource.fetchTasks(projectId);
      final taskIds = tasks.map((task) => task.id).toList();
      final dependencyRows = await _remoteDatasource.fetchDependencies(taskIds);

      final dependenciesByTaskId = <String, List<String>>{};
      final dependencyTaskIds = <String>{};

      for (final row in dependencyRows) {
        final taskId = row['task_id'] as String;
        final dependsOnTaskId = row['depends_on_task_id'] as String;
        dependenciesByTaskId.putIfAbsent(taskId, () => <String>[]);
        dependenciesByTaskId[taskId]!.add(dependsOnTaskId);
        dependencyTaskIds.add(dependsOnTaskId);
      }

      final dependencyTasks =
          await _remoteDatasource.fetchTasksByIds(dependencyTaskIds.toList());
      final dependencyStatusMap = {
        for (final task in dependencyTasks) task.id: task.status,
      };

      for (final task in tasks) {
        final dependencies = dependenciesByTaskId[task.id] ?? const [];
        final hasUnfinishedDependency = dependencies.any(
          (dependencyTaskId) => dependencyStatusMap[dependencyTaskId] != 'done',
        );

        if (hasUnfinishedDependency && task.status != 'blocked') {
          await _remoteDatasource.updateTaskStatus(
            taskId: task.id,
            status: 'blocked',
          );
        } else if (!hasUnfinishedDependency && task.status == 'blocked') {
          await _remoteDatasource.updateTaskStatus(
            taskId: task.id,
            status: 'todo',
          );
        }
      }

      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<bool> canManageTasks({
    bool refresh = false,
  }) async {
    final context = await _sessionService.getCurrentContext(refresh: refresh);
    return _canManageContext(context);
  }

  List<TaskSkillRequirementInput> _normalizeSkillRequirements(
    List<TaskSkillRequirementInput> skillRequirements,
  ) {
    final validSkillRequirements = skillRequirements
        .where((requirement) => requirement.skillId.trim().isNotEmpty)
        .map(
          (requirement) => TaskSkillRequirementInput(
            skillId: requirement.skillId.trim(),
            minimumLevel: requirement.minimumLevel,
            priorityWeight: requirement.priorityWeight,
          ),
        )
        .toList();

    if (validSkillRequirements.isEmpty) {
      throw const AppError('Minimal satu skill requirement wajib dipilih.');
    }

    return validSkillRequirements;
  }

  String _normalizeTaskStatus(String status) {
    final normalizedStatus = status.trim().toLowerCase();
    const validStatuses = {
      'backlog',
      'todo',
      'in_progress',
      'in_review',
      'done',
      'blocked',
      'cancelled',
    };

    if (!validStatuses.contains(normalizedStatus)) {
      throw const AppError('Status task tidak valid.');
    }

    return normalizedStatus;
  }

  bool _canManageContext(SessionContext? context) {
    final activeMember = context?.activeMember;
    if (activeMember == null) {
      return false;
    }

    final role = activeMember.role.toLowerCase();
    final positionCode = activeMember.positionCode?.toLowerCase();

    return activeMember.isOwner ||
        role == 'admin' ||
        role == 'kadep' ||
        role == 'ketua_divisi' ||
        role == 'kepala_departemen' ||
        positionCode == 'kadep' ||
        positionCode == 'ketua_divisi' ||
        positionCode == 'kepala_departemen' ||
        positionCode == 'koordinator_divisi';
  }

  Future<SessionContext> _requireActiveContext() async {
    if (_sessionService.currentUserId == null) {
      throw const AppError('User belum login.');
    }

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
        'Anda tidak memiliki izin untuk mengelola task.',
      );
    }

    return context;
  }
}
