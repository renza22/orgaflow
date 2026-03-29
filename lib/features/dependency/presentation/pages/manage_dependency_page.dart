import 'package:flutter/material.dart';

import '../../../task/domain/models/task_model.dart';
import '../../domain/models/task_dependency_model.dart';
import '../presenters/manage_dependency_presenter.dart';

class ManageDependencyPage extends StatefulWidget {
  const ManageDependencyPage({
    super.key,
    required this.taskId,
    required this.projectId,
  });

  final String taskId;
  final String projectId;

  @override
  State<ManageDependencyPage> createState() => _ManageDependencyPageState();
}

class _ManageDependencyPageState extends State<ManageDependencyPage> {
  final ManageDependencyPresenter _presenter = ManageDependencyPresenter();

  List<TaskModel> tasks = [];
  List<TaskDependencyModel> dependencies = [];
  String? selectedDependsOnTaskId;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final result = await _presenter.loadData(
      taskId: widget.taskId,
      projectId: widget.projectId,
    );

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
      tasks = result.data!.tasks;
      dependencies = result.data!.dependencies;
      isLoading = false;
    });
  }

  Future<void> addDependency() async {
    if (selectedDependsOnTaskId == null) {
      showMessage('Pilih task dependency terlebih dahulu');
      return;
    }

    setState(() {
      isSaving = true;
    });

    final result = await _presenter.addDependency(
      taskId: widget.taskId,
      dependsOnTaskId: selectedDependsOnTaskId!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = false;
    });

    if (result.isFailure) {
      showMessage(result.error!.message);
      return;
    }

    showMessage('Dependency berhasil ditambahkan');
    selectedDependsOnTaskId = null;
    await fetchData();
  }

  Future<void> deleteDependency(String dependencyId) async {
    final result = await _presenter.deleteDependency(dependencyId);

    if (result.isFailure) {
      showMessage(result.error!.message);
      return;
    }

    showMessage('Dependency berhasil dihapus');
    await fetchData();
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
                        value: task.id,
                        child: Text(task.title),
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

                              return Card(
                                child: ListTile(
                                  title: Text(dependency.dependsOnTaskTitle),
                                  trailing: IconButton(
                                    onPressed: () {
                                      deleteDependency(dependency.id);
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
