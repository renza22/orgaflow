import 'package:flutter/material.dart';

import '../../../assignment/presentation/pages/assign_task_page.dart';
import '../../../dependency/presentation/pages/manage_dependency_page.dart';
import '../../../workload/presentation/pages/workload_dashboard_page.dart';
import '../../domain/models/task_model.dart';
import '../presenters/task_list_presenter.dart';
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
  final TaskListPresenter _presenter = TaskListPresenter();
  List<TaskModel> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
    });

    final result = await _presenter.fetchTasks(widget.projectId);

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        isLoading = false;
      });
      showMessage(result.error!.message);
      return;
    }

    setState(() {
      tasks = result.data!;
      isLoading = false;
    });
  }

  Future<void> evaluateTaskStatuses() async {
    final result = await _presenter.evaluateTaskStatuses(widget.projectId);

    if (result.isFailure) {
      showMessage(result.error!.message);
      return;
    }

    await fetchTasks();
    showMessage('Status task berhasil dievaluasi');
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

    final updateResult = await _presenter.updateTaskStatus(
      taskId: taskId,
      status: result,
    );

    if (updateResult.isFailure) {
      showMessage(updateResult.error!.message);
      return;
    }

    showMessage('Status task berhasil diperbarui');
    await fetchTasks();
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
                                    task.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if ((task.description ?? '').isNotEmpty)
                                    Text(task.description!),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Estimasi: ${task.estimatedHours} jam',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${formatStatus(task.status)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor(task.status),
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
                                      task.priority,
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
                                              taskId: task.id,
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
                                              taskId: task.id,
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
                                          taskId: task.id,
                                          currentStatus: task.status,
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
