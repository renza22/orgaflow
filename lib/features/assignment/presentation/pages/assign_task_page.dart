import 'package:flutter/material.dart';

import '../../domain/models/assignment_member_option.dart';
import '../presenters/assign_task_presenter.dart';

class AssignTaskPage extends StatefulWidget {
  const AssignTaskPage({
    super.key,
    required this.taskId,
  });

  final String taskId;

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final AssignTaskPresenter _presenter = AssignTaskPresenter();

  List<AssignmentMemberOption> members = [];
  String? selectedMemberId;
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    final result = await _presenter.loadMembers();

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
      members = result.data!;
      isLoading = false;
    });
  }

  Future<void> assignTask() async {
    if (selectedMemberId == null) {
      showMessage('Pilih member terlebih dahulu');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final result = await _presenter.assignTask(
      taskId: widget.taskId,
      memberId: selectedMemberId!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isSubmitting = false;
    });

    if (result.isFailure) {
      showMessage(result.error!.message);
      return;
    }

    showMessage('Task berhasil di-assign');
    Navigator.pop(context);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Task'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedMemberId,
                    items: members.map<DropdownMenuItem<String>>((member) {
                      return DropdownMenuItem<String>(
                        value: member.id,
                        child: Text(member.displayLabel),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMemberId = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Pilih Member',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : assignTask,
                      child: Text(
                        isSubmitting ? 'Menyimpan...' : 'Assign Task',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
