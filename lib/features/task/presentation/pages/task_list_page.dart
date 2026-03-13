import 'package:flutter/material.dart';

import '../../../../core/supabase_config.dart';
import '../../../assignment/presentation/pages/assign_task_page.dart';
import '../../../dependency/presentation/pages/manage_dependency_page.dart';
import '../../../workload/presentation/pages/workload_dashboard_page.dart';
import 'create_task_page.dart';

class TaskListPage extends StatefulWidget {
  final String projectId;

  const TaskListPage({
    super.key,
    required this.projectId,
  });

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      setState(() {
        isLoading = true;
      });

      final data = await supabase
          .from('tasks')
          .select()
          .eq('project_id', widget.projectId)
          .order('created_at', ascending: false);

      setState(() {
        tasks = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showMessage('Gagal mengambil tasks: $e');
    }
  }

  Future<void> evaluateTaskStatuses() async {
    try {
      final allTasks = await supabase
          .from('tasks')
          .select()
          .eq('project_id', widget.projectId);

      for (final task in allTasks) {
        final dependencies = await supabase
            .from('task_dependencies')
            .select('depends_on_task_id')
            .eq('task_id', task['id']);

        if (dependencies.isEmpty) {
          if (task['status'] == 'blocked') {
            await supabase
                .from('tasks')
                .update({'status': 'todo'})
                .eq('id', task['id']);
          }
          continue;
        }

        bool hasUnfinishedDependency = false;

        for (final dependency in dependencies) {
          final dependencyTaskList = await supabase
              .from('tasks')
              .select('status')
              .eq('id', dependency['depends_on_task_id']);

          if (dependencyTaskList.isNotEmpty) {
            final dependencyTask = dependencyTaskList.first;

            if (dependencyTask['status'] != 'done') {
              hasUnfinishedDependency = true;
              break;
            }
          }
        }

        if (hasUnfinishedDependency) {
          if (task['status'] != 'blocked') {
            await supabase
                .from('tasks')
                .update({'status': 'blocked'})
                .eq('id', task['id']);
          }
        } else {
          if (task['status'] == 'blocked') {
            await supabase
                .from('tasks')
                .update({'status': 'todo'})
                .eq('id', task['id']);
          }
        }
      }

      await fetchTasks();
      showMessage('Status task berhasil dievaluasi');
    } catch (e) {
      showMessage('Gagal mengevaluasi status task: $e');
    }
  }

  Future<void> updateTaskStatus({
    required String taskId,
    required String currentStatus,
  }) async {
    String selectedStatus = currentStatus;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Status Task'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'backlog', child: Text('backlog')),
                  DropdownMenuItem(value: 'todo', child: Text('todo')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('in_progress'),
                  ),
                  DropdownMenuItem(
                    value: 'in_review',
                    child: Text('in_review'),
                  ),
                  DropdownMenuItem(value: 'done', child: Text('done')),
                  DropdownMenuItem(value: 'blocked', child: Text('blocked')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() {
                      selectedStatus = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, selectedStatus);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      await supabase
          .from('tasks')
          .update({'status': result})
          .eq('id', taskId);

      showMessage('Status task berhasil diperbarui');
      await fetchTasks();
    } catch (e) {
      showMessage('Gagal memperbarui status task: $e');
    }
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'blocked':
        return Colors.red;
      case 'todo':
        return Colors.orange;
      case 'backlog':
        return Colors.grey;
      case 'in_review':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String formatStatus(String? status) {
  switch (status) {
    case 'blocked':
      return 'Menunggu Task Lain';
    case 'in_progress':
      return 'Sedang Dikerjakan';
    case 'in_review':
      return 'Dalam Review';
    case 'todo':
      return 'Belum Dikerjakan';
    case 'done':
      return 'Selesai';
    case 'backlog':
      return 'Backlog';
    default:
      return status ?? '-';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateTaskPage(
                    projectId: widget.projectId,
                  ),
                ),
              );

              await fetchTasks();
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () async {
              await evaluateTaskStatuses();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WorkloadDashboardPage(),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(child: Text('Belum ada task'))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task['title'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (task['description'] != null &&
                                      task['description']
                                          .toString()
                                          .isNotEmpty)
                                    Text(task['description']),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Estimasi: ${task['estimated_hours']} jam',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${formatStatus(task['status'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor(task['status']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      task['priority'] ?? '-',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 34,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AssignTaskPage(
                                              taskId: task['id'],
                                            ),
                                          ),
                                        );

                                        await fetchTasks();
                                      },
                                      child: const Text(
                                        'Assign',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 34,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ManageDependencyPage(
                                              taskId: task['id'],
                                              projectId: widget.projectId,
                                            ),
                                          ),
                                        );

                                        await fetchTasks();
                                      },
                                      child: const Text(
                                        'Menunggu',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 34,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await updateTaskStatus(
                                          taskId: task['id'],
                                          currentStatus:
                                              task['status'] ?? 'backlog',
                                        );
                                      },
                                      child: const Text(
                                        'Status',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}