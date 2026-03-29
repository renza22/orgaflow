import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/supabase_config.dart';
import '../../../task/domain/models/task_model.dart';
import '../../domain/models/manage_dependency_data.dart';
import '../../domain/models/task_dependency_model.dart';

class TaskDependencyRemoteDatasource {
  TaskDependencyRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<ManageDependencyData> fetchData({
    required String taskId,
    required String projectId,
  }) async {
    final responses = await Future.wait<dynamic>([
      _client
          .from('tasks')
          .select()
          .eq('project_id', projectId)
          .neq('id', taskId)
          .order('created_at', ascending: false),
      _client
          .from('task_dependencies')
          .select(
            'id, depends_on_task_id, tasks!task_dependencies_depends_on_task_id_fkey(title)',
          )
          .eq('task_id', taskId),
    ]);

    final tasks = (responses[0] as List<dynamic>)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();

    final dependencies = (responses[1] as List<dynamic>).map((json) {
      final item = Map<String, dynamic>.from(json as Map);
      final taskRelation = item['tasks'];

      String title = 'Task tidak ditemukan';
      if (taskRelation is Map<String, dynamic>) {
        title = taskRelation['title'] as String? ?? title;
      } else if (taskRelation is List && taskRelation.isNotEmpty) {
        final relationMap =
            Map<String, dynamic>.from(taskRelation.first as Map);
        title = relationMap['title'] as String? ?? title;
      }

      return TaskDependencyModel(
        id: item['id'] as String,
        dependsOnTaskId: item['depends_on_task_id'] as String,
        dependsOnTaskTitle: title,
      );
    }).toList();

    return ManageDependencyData(
      tasks: tasks,
      dependencies: dependencies,
    );
  }

  Future<void> addDependency({
    required String taskId,
    required String dependsOnTaskId,
  }) async {
    if (taskId == dependsOnTaskId) {
      throw const AppError('Task tidak bisa bergantung pada dirinya sendiri.');
    }

    final existing = await _client
        .from('task_dependencies')
        .select('id')
        .eq('task_id', taskId)
        .eq('depends_on_task_id', dependsOnTaskId)
        .maybeSingle();

    if (existing != null) {
      throw const AppError('Dependency ini sudah ada.');
    }

    final tasks = await _client
        .from('tasks')
        .select('id, project_id')
        .inFilter('id', [taskId, dependsOnTaskId]);

    final taskRows = (tasks as List<dynamic>)
        .map((json) => Map<String, dynamic>.from(json as Map))
        .toList();

    if (taskRows.length != 2) {
      throw const AppError('Task dependency tidak valid.');
    }

    final projectIds = taskRows
        .map((item) => item['project_id'] as String?)
        .whereType<String>()
        .toSet();

    if (projectIds.length != 1) {
      throw const AppError('Dependency harus berasal dari project yang sama.');
    }

    await _client.from('task_dependencies').insert({
      'task_id': taskId,
      'depends_on_task_id': dependsOnTaskId,
    });
  }

  Future<void> deleteDependency(String dependencyId) async {
    await _client.from('task_dependencies').delete().eq('id', dependencyId);
  }
}
