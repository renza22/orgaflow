import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase_config.dart';
import '../../domain/models/project_model.dart';

class ProjectRemoteDatasource {
  ProjectRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  static const String _projectColumns =
      'id, organization_id, name, description, status, start_date, end_date, '
      'created_by, created_at, updated_at';

  Future<List<ProjectModel>> fetchProjects({
    required String organizationId,
  }) async {
    final response = await _client
        .from('projects')
        .select(_projectColumns)
        .eq('organization_id', organizationId)
        .order('updated_at', ascending: false);

    final projects = (response as List<dynamic>)
        .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
        .toList();

    if (projects.isEmpty) {
      return const [];
    }

    final projectIds = projects.map((project) => project.id).toList();
    final taskRows = await _client
        .from('tasks')
        .select('id, project_id, status')
        .inFilter('project_id', projectIds);

    final totalTasksByProjectId = <String, int>{};
    final completedTasksByProjectId = <String, int>{};
    final taskIdToProjectId = <String, String>{};

    for (final rawTask in taskRows as List<dynamic>) {
      final task = Map<String, dynamic>.from(rawTask as Map);
      final taskId = task['id'] as String?;
      final projectId = task['project_id'] as String?;

      if (taskId == null || projectId == null) {
        continue;
      }

      taskIdToProjectId[taskId] = projectId;
      totalTasksByProjectId.update(
        projectId,
        (current) => current + 1,
        ifAbsent: () => 1,
      );

      if ((task['status'] as String? ?? '') == 'done') {
        completedTasksByProjectId.update(
          projectId,
          (current) => current + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final memberIdsByProjectId = <String, Set<String>>{};
    if (taskIdToProjectId.isNotEmpty) {
      final assignmentRows = await _client
          .from('task_assignments')
          .select('task_id, member_id')
          .inFilter('task_id', taskIdToProjectId.keys.toList());

      for (final rawAssignment in assignmentRows as List<dynamic>) {
        final assignment = Map<String, dynamic>.from(rawAssignment as Map);
        final taskId = assignment['task_id'] as String?;
        final memberId = assignment['member_id'] as String?;

        if (taskId == null || memberId == null) {
          continue;
        }

        final projectId = taskIdToProjectId[taskId];
        if (projectId == null) {
          continue;
        }

        memberIdsByProjectId.putIfAbsent(projectId, () => <String>{});
        memberIdsByProjectId[projectId]!.add(memberId);
      }
    }

    return projects
        .map(
          (project) => project.copyWith(
            totalTasks: totalTasksByProjectId[project.id] ?? 0,
            completedTasks: completedTasksByProjectId[project.id] ?? 0,
            memberCount: memberIdsByProjectId[project.id]?.length ?? 0,
          ),
        )
        .toList();
  }

  Future<ProjectModel> createProject({
    required String organizationId,
    required String createdBy,
    required String name,
    required String description,
    DateTime? endDate,
  }) async {
    final payload = <String, dynamic>{
      'organization_id': organizationId,
      'name': name,
      'description': description,
      'status': 'draft',
      'created_by': createdBy,
      if (endDate != null) 'end_date': _formatDate(endDate),
    };

    final response = await _client
        .from('projects')
        .insert(payload)
        .select(_projectColumns)
        .single();

    return ProjectModel.fromJson(response);
  }

  Future<ProjectModel> updateProject({
    required String projectId,
    required String name,
    required String description,
    DateTime? endDate,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'description': description,
      'end_date': endDate == null ? null : _formatDate(endDate),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status != null && status.isNotEmpty) {
      payload['status'] = status;
    }

    final response = await _client
        .from('projects')
        .update(payload)
        .eq('id', projectId)
        .select(_projectColumns)
        .single();

    return ProjectModel.fromJson(response);
  }

  Future<void> deleteProject({
    required String projectId,
  }) async {
    await _client.from('projects').delete().eq('id', projectId);
  }

  String _formatDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}
