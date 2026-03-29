import 'package:flutter/material.dart';

import '../presenters/create_task_presenter.dart';

class CreateTaskPage extends StatefulWidget {
  final String projectId;

  const CreateTaskPage({
    super.key,
    required this.projectId,
  });

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final hoursController = TextEditingController();
  final CreateTaskPresenter _presenter = CreateTaskPresenter();

  bool isLoading = false;

  String priority = 'medium';

  Future<void> createTask() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final hoursText = hoursController.text.trim();

    if (title.isEmpty) {
      showMessage('Judul task wajib diisi');
      return;
    }

    final hours = int.tryParse(hoursText) ?? 1;

    try {
      setState(() {
        isLoading = true;
      });

      final result = await _presenter.createTask(
        projectId: widget.projectId,
        title: title,
        description: description,
        estimatedHours: hours,
        priority: priority,
      );

      if (result.isFailure) {
        showMessage(result.error!.message);
        return;
      }

      showMessage('Task berhasil dibuat');

      if (!mounted) return;

      Navigator.pop(context, true);

      titleController.clear();
      descriptionController.clear();
      hoursController.clear();
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
    titleController.dispose();
    descriptionController.dispose();
    hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Task',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimasi Jam',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: priority,
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (value) {
                setState(() {
                  priority = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : createTask,
                child: Text(
                  isLoading ? 'Menyimpan...' : 'Buat Task',
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
