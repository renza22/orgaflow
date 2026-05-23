import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../domain/models/subtask_model.dart';

class SubtaskRemoteDatasource {
  SubtaskRemoteDatasource({SupabaseClient? client})
      : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<List<SubtaskModel>> fetchSubtasks(String parentTaskId) async {
    final response = await _client.rpc(
      'get_task_subtasks',
      params: {
        'p_parent_task_id': parentTaskId,
      },
    );

    return _extractRows(response).map(SubtaskModel.fromJson).toList();
  }

  Future<SubtaskModel> createSubtask({
    required String parentTaskId,
    required String title,
    required String description,
  }) async {
    final response = await _client.rpc(
      'create_my_subtask',
      params: {
        'p_parent_task_id': parentTaskId,
        'p_title': title,
        'p_description': description,
      },
    );

    return SubtaskModel.fromJson(_extractRequiredSingleRow(response));
  }

  Future<SubtaskModel> updateSubtask({
    required String subtaskId,
    String? title,
    String? description,
    String? status,
  }) async {
    final response = await _client.rpc(
      'update_my_subtask',
      params: {
        'p_subtask_id': subtaskId,
        'p_title': title,
        'p_description': description,
        'p_status': status,
      },
    );

    return SubtaskModel.fromJson(_extractRequiredSingleRow(response));
  }

  Future<void> deleteSubtask(String subtaskId) async {
    await _client.rpc(
      'delete_my_subtask',
      params: {
        'p_subtask_id': subtaskId,
      },
    );
  }

  Map<String, dynamic> _extractRequiredSingleRow(dynamic response) {
    final row = _extractSingleRow(response);
    if (row == null) {
      throw const FormatException('RPC sub-task tidak mengembalikan data.');
    }
    return row;
  }

  Map<String, dynamic>? _extractSingleRow(dynamic response) {
    if (response == null) {
      return null;
    }

    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _extractRows(dynamic response) {
    if (response == null) {
      return const [];
    }

    if (response is List) {
      return response
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }

    final row = _extractSingleRow(response);
    return row == null ? const [] : [row];
  }
}
