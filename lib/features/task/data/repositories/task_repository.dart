import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_service.dart';
import '../../domain/models/task_model.dart';
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
  }) async {
    try {
      final userId = _sessionService.currentUserId;
      if (userId == null) {
        return Result<TaskModel>.failure(
          const AppError('User belum login.'),
        );
      }

      final task = await _remoteDatasource.createTask(
        projectId: projectId,
        createdBy: userId,
        title: title,
        description: description,
        estimatedHours: estimatedHours,
        priority: priority,
      );

      return Result<TaskModel>.success(task);
    } catch (error) {
      return Result<TaskModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<List<TaskModel>>> fetchTasks(String projectId) async {
    try {
      final tasks = await _remoteDatasource.fetchTasks(projectId);
      return Result<List<TaskModel>>.success(tasks);
    } catch (error) {
      return Result<List<TaskModel>>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      await _remoteDatasource.updateTaskStatus(
        taskId: taskId,
        status: status,
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
}
