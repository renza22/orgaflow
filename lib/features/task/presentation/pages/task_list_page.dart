import 'package:flutter/material.dart';
import '../../../workload/presentation/pages/workload_dashboard_page.dart';
import '../../../../core/supabase_config.dart';
import '../../../assignment/presentation/pages/assign_task_page.dart';

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

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Task List'),
        actions: [
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
                      child: ListTile(

                        title: Text(task['title']),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            if (task['description'] != null)
                              Text(task['description']),

                            Text(
                              'Estimasi: ${task['estimated_hours']} jam',
                              style: const TextStyle(fontSize: 12),
                            ),

                          ],
                        ),

trailing: SizedBox(
  width: 90,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        task['priority'],
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssignTaskPage(
                  taskId: task['id'],
                ),
              ),
            );
          },
          child: const Text(
            'Assign',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    ],
  ),
),
                      ),
                    );
                  },
                ),
    );
  }
}