import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../domain/models/project_model.dart';

class ProjectRemoteDatasource {
  ProjectRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  Future<ProjectModel> createProject({
    required String organizationId,
    required String createdBy,
    required String name,
    required String description,
  }) async {
    final response = await _client
        .from('projects')
        .insert({
          'organization_id': organizationId,
          'name': name,
          'description': description,
          'status': 'draft',
          'created_by': createdBy,
        })
        .select()
        .single();

    return ProjectModel.fromJson(response);
  }
}
