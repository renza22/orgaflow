import 'package:flutter/material.dart';

import '../../../../core/supabase_config.dart';
import '../../../task/presentation/pages/create_task_page.dart';
import '../../../task/presentation/pages/task_list_page.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isLoading = false;

  Future<void> createProject() async {

    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('User belum login');
      return;
    }

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

      final member = await supabase
          .from('members')
          .select()
          .eq('profile_id', user.id)
          .single();

      final project = await supabase
        .from('projects')
        .insert({
          'organization_id': member['organization_id'],
          'name': name,
          'description': description,
          'status': 'draft',
          'created_by': user.id
        })
        .select()
        .single();

      showMessage('Project berhasil dibuat');

      if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => TaskListPage(
      projectId: project['id'],
    ),
  ),
);

    } catch (e) {

      showMessage('Gagal membuat project: $e');

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
                  isLoading
                      ? 'Membuat...'
                      : 'Buat Project',
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}