import 'package:flutter/material.dart';

import '../../features/task/domain/models/task_skill_requirement_model.dart';
import '../../features/task/presentation/presenters/create_task_presenter.dart';

/*
LEGACY FLOW:
This page belongs to the old setup/project/task flow and is not part of the
current primary app flow. Current primary flow uses OnboardingPage,
ProjectsPage, and ProjectBoardPage Kanban modal. Keep this file for reference
only until safe removal.
*/
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
  bool isLoadingSkills = true;

  String priority = 'medium';
  List<TaskSkillOptionModel> activeSkills = [];
  final Set<String> selectedSkillIds = <String>{};

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    final result = await _presenter.fetchActiveSkills();

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        isLoadingSkills = false;
      });
      showMessage(result.error!.message);
      return;
    }

    setState(() {
      activeSkills = result.data!;
      isLoadingSkills = false;
    });
  }

  Future<void> createTask() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final hoursText = hoursController.text.trim();

    if (title.isEmpty) {
      showMessage('Judul task wajib diisi');
      return;
    }

    if (hoursText.isEmpty) {
      showMessage('Estimasi jam wajib diisi');
      return;
    }

    final hours = int.tryParse(hoursText);
    if (hours == null || hours <= 0) {
      showMessage('Estimasi jam harus angka lebih dari 0');
      return;
    }

    if (selectedSkillIds.isEmpty) {
      showMessage('Minimal satu skill requirement wajib dipilih');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await _presenter.createTask(
      projectId: widget.projectId,
      title: title,
      description: description,
      estimatedHours: hours,
      priority: priority,
      skillRequirements: selectedSkillIds
          .map((skillId) => TaskSkillRequirementInput(skillId: skillId))
          .toList(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });

    if (result.isFailure) {
      showMessage(result.error!.message);
      return;
    }

    showMessage('Task berhasil dibuat');
    Navigator.pop(context, true);
  }

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

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
        child: SingleChildScrollView(
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
              const SizedBox(height: 12),
              _buildSkillRequirementPicker(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading || isLoadingSkills ? null : createTask,
                  child: Text(
                    isLoading ? 'Menyimpan...' : 'Buat Task',
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillRequirementPicker() {
    if (isLoadingSkills) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (activeSkills.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Belum ada skill aktif'),
      );
    }

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Skill Requirements',
        border: OutlineInputBorder(),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: activeSkills.map((skill) {
          final selected = selectedSkillIds.contains(skill.id);

          return FilterChip(
            label: Text(skill.name),
            selected: selected,
            onSelected: isLoading
                ? null
                : (value) {
                    setState(() {
                      if (value) {
                        selectedSkillIds.add(skill.id);
                      } else {
                        selectedSkillIds.remove(skill.id);
                      }
                    });
                  },
          );
        }).toList(),
      ),
    );
  }
}
