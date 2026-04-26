import 'package:flutter/material.dart';

import '../../features/project/domain/models/project_model.dart';
import '../../features/project/presentation/presenters/create_project_presenter.dart';
import 'task_list_page.dart';

/*
LEGACY FLOW:
This page belongs to the old setup/project/task flow and is not part of the
current primary app flow. Current primary flow uses OnboardingPage,
ProjectsPage, and ProjectBoardPage Kanban modal. Keep this file for reference
only until safe removal.
*/
class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final CreateProjectPresenter _presenter = CreateProjectPresenter();

  bool isLoading = false;

  Future<void> createProject() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) {
      showMessage('Nama project wajib diisi');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final result = await _presenter.createProject(
        name: name,
        description: description,
      );

      if (result.isFailure) {
        showMessage(result.error!.message);
        return;
      }

      final ProjectModel project = result.data!;

      showMessage('Project berhasil dibuat');

      if (!mounted) return;

      // Legacy chain only: CreateProjectPage -> TaskListPage.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TaskListPage(
            projectId: project.id,
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Project',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Project',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : createProject,
                child: Text(
                  isLoading ? 'Membuat...' : 'Buat Project',
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
