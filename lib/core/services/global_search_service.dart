import 'package:flutter/material.dart';
import '../../features/project/presentation/presenters/projects_presenter.dart';
import '../../features/members/data/repositories/members_repository.dart';
import '../../features/task/data/repositories/task_repository.dart';

class GlobalSearchService {
  final ProjectsPresenter _projectsPresenter = ProjectsPresenter();
  final MembersRepository _membersRepository = MembersRepository();
  final TaskRepository _taskRepository = TaskRepository();

  Future<List<Map<String, dynamic>>> fetchAllSearchableData() async {
    final results = <Map<String, dynamic>>[];

    try {
      // 1. Fetch Projects
      final projectsResult = await _projectsPresenter.fetchProjects();
      if (projectsResult.isSuccess && projectsResult.data != null) {
        for (final project in projectsResult.data!) {
          results.add({
            'id': project.id,
            'name': project.name,
            'type': 'project',
            'icon': Icons.folder_outlined,
            'route': '/projects',
          });

          // Fetch Tasks for this project
          final tasksResult = await _taskRepository.fetchTasks(project.id);
          if (tasksResult.isSuccess && tasksResult.data != null) {
            for (final task in tasksResult.data!) {
              results.add({
                'id': task.id,
                'name': task.title,
                'project': project.name,
                'projectId': project.id,
                'type': 'task',
                'icon': Icons.task_outlined,
                'route': '/projects', // Normally we might have a specific task route, but we fallback to /projects for now
              });
            }
          }
        }
      }

      // 2. Fetch Members
      final membersResult = await _membersRepository.fetchMembers();
      if (membersResult.isSuccess && membersResult.data != null) {
        for (final member in membersResult.data!) {
          results.add({
            'id': member.id,
            'name': member.name,
            'role': member.role,
            'type': 'member',
            'icon': Icons.person_outline,
            'route': '/members',
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching search data: $e');
    }

    return results;
  }
}
