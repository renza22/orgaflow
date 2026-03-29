import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../domain/models/task_model.dart';

class TaskRemoteDatasource {
  TaskRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<TaskModel> createTask({
    required String projectId,
    required String createdBy,
    required String title,
    required String description,
    required int estimatedHours,
    required String priority,
  }) async {
    final response = await _client
        .from('tasks')
        .insert({
          'project_id': projectId,
          'created_by': createdBy,
          'title': title,
          'description': description,
          'estimated_hours': estimatedHours,
          'priority': priority,
          'status': 'backlog',
        })
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  Future<List<TaskModel>> fetchTasks(String projectId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchDependencies(
    List<String> taskIds,
  ) async {
    if (taskIds.isEmpty) {
      return const [];
    }

    final response = await _client
        .from('task_dependencies')
        .select('task_id, depends_on_task_id')
        .inFilter('task_id', taskIds);

    return (response as List<dynamic>)
        .map((json) => Map<String, dynamic>.from(json as Map))
        .toList();
  }

  Future<List<TaskModel>> fetchTasksByIds(List<String> taskIds) async {
    if (taskIds.isEmpty) {
      return const [];
    }

    final response =
        await _client.from('tasks').select().inFilter('id', taskIds);

    return (response as List<dynamic>)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    await _client.from('tasks').update({'status': status}).eq('id', taskId);
  }
}
