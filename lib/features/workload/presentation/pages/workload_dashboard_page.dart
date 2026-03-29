import 'package:flutter/material.dart';

import '../../domain/models/workload_item_model.dart';
import '../presenters/workload_dashboard_presenter.dart';

class WorkloadDashboardPage extends StatefulWidget {
  const WorkloadDashboardPage({super.key});

  @override
  State<WorkloadDashboardPage> createState() => _WorkloadDashboardPageState();
}

class _WorkloadDashboardPageState extends State<WorkloadDashboardPage> {
  final WorkloadDashboardPresenter _presenter = WorkloadDashboardPresenter();

  List<WorkloadItemModel> workloadData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWorkloadData();
  }

  Future<void> fetchWorkloadData() async {
    final result = await _presenter.loadWorkload();

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
      workloadData = result.data!;
      isLoading = false;
    });
  }

  Color statusColor(String status) {
    switch (status) {
      case 'overload':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'safe':
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

  String formatStatus(String status) {
    switch (status) {
      case 'overload':
        return 'Overload';
      case 'warning':
        return 'Warning';
      case 'safe':
        return 'Aman';
      case 'no_capacity':
        return 'No Capacity';
      default:
        return status;
    }
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
                              item.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jabatan: ${item.positionLabel ?? item.positionCode ?? '-'}',
                            ),
                            Text(
                              'Capacity: ${item.weeklyCapacityHours} jam/minggu',
                            ),
                            Text('Workload: ${item.assignedHours} jam'),
                            Text(
                              'Load Ratio: ${formatPercent(item.loadRatio)}',
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor(item.workloadStatus),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                formatStatus(item.workloadStatus),
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
