import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../models/activity_log_model.dart';

class ActivityLogRemoteDatasource {
  ActivityLogRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<List<ActivityLog>> fetchActivityLogs({
    required String organizationId,
    int limit = 20,
    String? entityType,
    String? entityId,
  }) async {
    final response = await _client.rpc(
      'get_activity_logs',
      params: {
        'p_organization_id': organizationId,
        'p_limit': limit,
        'p_entity_type': entityType,
        'p_entity_id': entityId,
      },
    );

    return _extractRows(response).map(ActivityLog.fromJson).toList();
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

    if (response is Map<String, dynamic>) {
      return [response];
    }

    if (response is Map) {
      return [Map<String, dynamic>.from(response)];
    }

    return const [];
  }
}
