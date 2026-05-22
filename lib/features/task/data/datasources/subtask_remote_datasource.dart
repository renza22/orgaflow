import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../domain/models/subtask_model.dart';

class SubtaskRemoteDatasource {
  SubtaskRemoteDatasource({SupabaseClient? client})
      : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<List<SubtaskModel>> fetchSubtasks(String parentTaskId) async {
    final response = await _client
        .from('subtasks')
        .select()
        .eq('parent_task_id', parentTaskId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => SubtaskModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<SubtaskModel> createSubtask({
    required String parentTaskId,
    required String title,
    required String description,
    required String assignedToEmail,
    required String assignedToName,
    required String createdBy,
  }) async {
    final response = await _client.from('subtasks').insert({
      'parent_task_id': parentTaskId,
      'title': title,
      'description': description,
      'assigned_to_email': assignedToEmail,
      'assigned_to_name': assignedToName,
      'status': 'todo',
      'created_by': createdBy,
    }).select().single();

    return SubtaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<SubtaskModel> updateSubtask({
    required String subtaskId,
    String? title,
    String? description,
    String? status,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (status != null) {
      updateData['status'] = status;
      if (status == 'done') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }
    }

    final response = await _client
        .from('subtasks')
        .update(updateData)
        .eq('id', subtaskId)
        .select()
        .single();

    return SubtaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteSubtask(String subtaskId) async {
    await _client.from('subtasks').delete().eq('id', subtaskId);
  }
}
