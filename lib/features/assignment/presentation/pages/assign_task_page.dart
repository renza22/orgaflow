import 'package:flutter/material.dart';
import '../../../../core/supabase_config.dart';

class AssignTaskPage extends StatefulWidget {

  final String taskId;

  const AssignTaskPage({
    super.key,
    required this.taskId,
  });

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {

  List members = [];
  String? selectedMemberId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {

    try {

      final user = supabase.auth.currentUser;

      if (user == null) return;

      final member = await supabase
          .from('members')
          .select()
          .eq('profile_id', user.id)
          .single();

      final organizationId = member['organization_id'];

      final data = await supabase
          .from('members')
          .select('id, position')
          .eq('organization_id', organizationId);

      setState(() {
        members = data;
        isLoading = false;
      });

    } catch (e) {

      setState(() {
        isLoading = false;
      });

      showMessage('Gagal mengambil members: $e');
    }
  }

  Future<void> assignTask() async {

    if (selectedMemberId == null) {
      showMessage('Pilih member terlebih dahulu');
      return;
    }

    try {

      await supabase.from('task_assignments').insert({
        'task_id': widget.taskId,
        'member_id': selectedMemberId
      });

      showMessage('Task berhasil di-assign');

      Navigator.pop(context);

    } catch (e) {

      showMessage('Gagal assign task: $e');

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
                        value: member['id'],
                        child: Text(member['position']),
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
                      onPressed: assignTask,
                      child: const Text('Assign Task'),
                    ),
                  )

                ],
              ),
            ),
    );
  }
}