import 'package:flutter/material.dart';
import '../../../../core/supabase_config.dart';

class WorkloadDashboardPage extends StatefulWidget {
  const WorkloadDashboardPage({super.key});

  @override
  State<WorkloadDashboardPage> createState() => _WorkloadDashboardPageState();
}

class _WorkloadDashboardPageState extends State<WorkloadDashboardPage> {
  List<Map<String, dynamic>> workloadData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWorkloadData();
  }

Future<void> fetchWorkloadData() async {
  try {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('User belum login');
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Cari member milik user login
    final currentMemberList = await supabase
        .from('members')
        .select()
        .eq('profile_id', user.id);

    if (currentMemberList.isEmpty) {
      showMessage(
        'User ini belum punya data keanggotaan di tabel members. '
        'Coba login dengan akun yang sudah melewati setup member.',
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    final currentMember = currentMemberList.first;
    final organizationId = currentMember['organization_id'];

    // Ambil semua member dalam organisasi
    final members = await supabase
        .from('members')
        .select()
        .eq('organization_id', organizationId);

    List<Map<String, dynamic>> results = [];

    for (final member in members) {
      final profileList = await supabase
          .from('profiles')
          .select()
          .eq('id', member['profile_id']);

      final profile = profileList.isNotEmpty ? profileList.first : null;

      final assignments = await supabase
          .from('task_assignments')
          .select('task_id, tasks(estimated_hours, title)')
          .eq('member_id', member['id']);

      int totalWorkload = 0;

      for (final assignment in assignments) {
        final task = assignment['tasks'];
        if (task != null && task['estimated_hours'] != null) {
          totalWorkload += (task['estimated_hours'] as num).toInt();
        }
      }

      final int capacity =
          ((member['capacity_hours_per_week'] ?? 0) as num).toInt();

      final double loadRatio =
          capacity > 0 ? totalWorkload / capacity : 0.0;

      String status;
      if (capacity == 0) {
        status = 'No Capacity';
      } else if (loadRatio > 1.0) {
        status = 'Overload';
      } else if (loadRatio >= 0.8) {
        status = 'Warning';
      } else {
        status = 'Aman';
      }

      results.add({
        'member_id': member['id'],
        'full_name': profile?['full_name'] ?? 'Tanpa Nama',
        'position': member['position'] ?? '-',
        'capacity': capacity,
        'workload': totalWorkload,
        'load_ratio': loadRatio,
        'status': status,
      });
    }

    setState(() {
      workloadData = results;
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    showMessage('Gagal mengambil workload: $e');
  }
}

  Color statusColor(String status) {
    switch (status) {
      case 'Overload':
        return Colors.red;
      case 'Warning':
        return Colors.orange;
      case 'Aman':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String formatPercent(double ratio) {
    return '${(ratio * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workload Dashboard'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : workloadData.isEmpty
              ? const Center(child: Text('Belum ada data workload'))
              : ListView.builder(
                  itemCount: workloadData.length,
                  itemBuilder: (context, index) {
                    final item = workloadData[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['full_name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Jabatan: ${item['position']}'),
                            Text('Capacity: ${item['capacity']} jam/minggu'),
                            Text('Workload: ${item['workload']} jam'),
                            Text('Load Ratio: ${formatPercent(item['load_ratio'])}'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor(item['status']),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['status'],
                                style: const TextStyle(color: Colors.white),
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