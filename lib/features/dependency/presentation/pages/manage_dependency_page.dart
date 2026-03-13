import 'package:flutter/material.dart';
import '../../../../core/supabase_config.dart';

class ManageDependencyPage extends StatefulWidget {
  final String taskId;
  final String projectId;

  const ManageDependencyPage({
    super.key,
    required this.taskId,
    required this.projectId,
  });

  @override
  State<ManageDependencyPage> createState() => _ManageDependencyPageState();
}

class _ManageDependencyPageState extends State<ManageDependencyPage> {
  List tasks = [];
  List dependencies = [];
  String? selectedDependsOnTaskId;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final allTasks = await supabase
          .from('tasks')
          .select()
          .eq('project_id', widget.projectId)
          .neq('id', widget.taskId)
          .order('created_at', ascending: false);

      final currentDependencies = await supabase
          .from('task_dependencies')
          .select('id, depends_on_task_id, tasks!task_dependencies_depends_on_task_id_fkey(title)')
          .eq('task_id', widget.taskId);

      setState(() {
        tasks = allTasks;
        dependencies = currentDependencies;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showMessage('Gagal mengambil dependency: $e');
    }
  }

  Future<void> addDependency() async {
    if (selectedDependsOnTaskId == null) {
      showMessage('Pilih task dependency terlebih dahulu');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await supabase.from('task_dependencies').insert({
        'task_id': widget.taskId,
        'depends_on_task_id': selectedDependsOnTaskId,
      });

      showMessage('Dependency berhasil ditambahkan');
      selectedDependsOnTaskId = null;
      await fetchData();
    } catch (e) {
      showMessage('Gagal menambahkan dependency: $e');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> deleteDependency(String dependencyId) async {
    try {
      await supabase
          .from('task_dependencies')
          .delete()
          .eq('id', dependencyId);

      showMessage('Dependency berhasil dihapus');
      await fetchData();
    } catch (e) {
      showMessage('Gagal menghapus dependency: $e');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Urutan Task'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedDependsOnTaskId,
                    items: tasks.map<DropdownMenuItem<String>>((task) {
                      return DropdownMenuItem<String>(
                        value: task['id'],
                        child: Text(task['title']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDependsOnTaskId = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Task yang harus diselesaikan dulu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : addDependency,
                      child: Text(
                        isSaving ? 'Menyimpan...' : 'Tambah Dependency',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Daftar Dependency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: dependencies.isEmpty
                        ? const Center(
                            child: Text('Belum ada dependency'),
                          )
                        : ListView.builder(
                            itemCount: dependencies.length,
                            itemBuilder: (context, index) {
                              final dependency = dependencies[index];
                              final dependsOnTask =
                                  dependency['tasks'];

                              return Card(
                                child: ListTile(
                                  title: Text(
                                    dependsOnTask?['title'] ?? 'Task tidak ditemukan',
                                  ),
                                  trailing: IconButton(
                                    onPressed: () {
                                      deleteDependency(dependency['id']);
                                    },
                                    icon: const Icon(Icons.delete),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}