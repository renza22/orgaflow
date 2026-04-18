import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/task_model.dart';

class WorkflowTab extends StatelessWidget {
  final List<Task> tasks;

  const WorkflowTab({super.key, required this.tasks});

  List<Task> get _readyTasks => tasks.where((t) {
        if (t.status == TaskStatus.done) return false;
        if (t.dependencies.isEmpty) return true;
        return t.dependencies.every((depId) =>
            tasks.any((dt) => dt.id == depId && dt.status == TaskStatus.done));
      }).toList();

  List<Task> get _blockedTasks => tasks.where((t) {
        if (t.status == TaskStatus.done) return false;
        if (t.dependencies.isEmpty) return false;
        return !t.dependencies.every((depId) =>
            tasks.any((dt) => dt.id == depId && dt.status == TaskStatus.done));
      }).toList();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 900;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DAG Visualization Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Dependency Graph',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                    Row(children: [
                      _buildLegendDot(const Color(0xFF00B894), 'Done'),
                      const SizedBox(width: 12),
                      _buildLegendDot(const Color(0xFF6C5CE7), 'Ready'),
                      const SizedBox(width: 12),
                      _buildLegendDot(Colors.orange, 'Blocked'),
                    ]),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: CustomPaint(
                    size: const Size(double.infinity, 300),
                    painter: _DAGPainter(tasks: tasks),
                    child: _buildDAGNodes(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Ready vs Blocked lists
          isSmall
              ? Column(children: [
                  _buildTaskListCard('Ready Tasks', _readyTasks, const Color(0xFF00B894), Icons.check_circle_outline),
                  const SizedBox(height: 20),
                  _buildTaskListCard('Blocked Tasks', _blockedTasks, Colors.orange, Icons.block),
                ])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTaskListCard('Ready Tasks', _readyTasks, const Color(0xFF00B894), Icons.check_circle_outline)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildTaskListCard('Blocked Tasks', _blockedTasks, Colors.orange, Icons.block)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }

  Widget _buildDAGNodes() {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks yet'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final positions = _calculateNodePositions(width, height);

        return Stack(
          children: tasks.map((task) {
            final pos = positions[task.id]!;
            final color = _getNodeColor(task);
            return Positioned(
              left: pos.dx - 55,
              top: pos.dy - 22,
              child: Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  task.title,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _getNodeColor(Task task) {
    if (task.status == TaskStatus.done) return const Color(0xFF00B894);
    final isBlocked = task.dependencies.isNotEmpty &&
        !task.dependencies.every((depId) =>
            tasks.any((dt) => dt.id == depId && dt.status == TaskStatus.done));
    if (isBlocked) return Colors.orange;
    return const Color(0xFF6C5CE7);
  }

  Map<int, Offset> _calculateNodePositions(double width, double height) {
    final Map<int, int> levels = {};
    for (final task in tasks) {
      _calcLevel(task, levels);
    }
    final maxLevel = levels.values.fold(0, (a, b) => a > b ? a : b);
    final Map<int, List<int>> byLevel = {};
    for (final entry in levels.entries) {
      byLevel.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    final Map<int, Offset> positions = {};
    for (int level = 0; level <= maxLevel; level++) {
      final ids = byLevel[level] ?? [];
      final xStep = width / (ids.length + 1);
      final y = (level + 1) * height / (maxLevel + 2);
      for (int i = 0; i < ids.length; i++) {
        positions[ids[i]] = Offset(xStep * (i + 1), y);
      }
    }
    return positions;
  }

  int _calcLevel(Task task, Map<int, int> levels) {
    if (levels.containsKey(task.id)) return levels[task.id]!;
    if (task.dependencies.isEmpty) {
      levels[task.id] = 0;
      return 0;
    }
    int maxParent = 0;
    for (final depId in task.dependencies) {
      final dep = tasks.firstWhere((t) => t.id == depId, orElse: () => task);
      if (dep.id != task.id) {
        maxParent = max(maxParent, _calcLevel(dep, levels));
      }
    }
    levels[task.id] = maxParent + 1;
    return maxParent + 1;
  }

  Widget _buildTaskListCard(String title, List<Task> taskList, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${taskList.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ),
          ]),
          const SizedBox(height: 12),
          if (taskList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('Tidak ada task', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
            )
          else
            ...taskList.map((task) => _buildTaskItem(task, color)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(task.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (task.dependencies.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('${task.dependencies.length} deps',
                style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
          ),
        const SizedBox(width: 8),
        Text('${task.estimatedHours}h', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _DAGPainter extends CustomPainter {
  final List<Task> tasks;
  _DAGPainter({required this.tasks});

  @override
  void paint(Canvas canvas, Size size) {
    final positions = _calculatePositions(size.width, size.height);
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final task in tasks) {
      for (final depId in task.dependencies) {
        if (positions.containsKey(depId) && positions.containsKey(task.id)) {
          final from = positions[depId]!;
          final to = positions[task.id]!;
          paint.color = Colors.grey.shade400;
          final path = Path()
            ..moveTo(from.dx, from.dy + 10)
            ..cubicTo(from.dx, from.dy + 40, to.dx, to.dy - 40, to.dx, to.dy - 10);
          canvas.drawPath(path, paint);

          // Arrow head
          final arrowPaint = Paint()
            ..color = Colors.grey.shade400
            ..style = PaintingStyle.fill;
          final arrowPath = Path()
            ..moveTo(to.dx, to.dy - 10)
            ..lineTo(to.dx - 4, to.dy - 18)
            ..lineTo(to.dx + 4, to.dy - 18)
            ..close();
          canvas.drawPath(arrowPath, arrowPaint);
        }
      }
    }
  }

  Map<int, Offset> _calculatePositions(double width, double height) {
    final Map<int, int> levels = {};
    for (final task in tasks) {
      _calcLevel(task, levels);
    }
    final maxLevel = levels.values.fold(0, (a, b) => a > b ? a : b);
    final Map<int, List<int>> byLevel = {};
    for (final e in levels.entries) {
      byLevel.putIfAbsent(e.value, () => []).add(e.key);
    }
    final Map<int, Offset> pos = {};
    for (int lvl = 0; lvl <= maxLevel; lvl++) {
      final ids = byLevel[lvl] ?? [];
      final xStep = width / (ids.length + 1);
      final y = (lvl + 1) * height / (maxLevel + 2);
      for (int i = 0; i < ids.length; i++) {
        pos[ids[i]] = Offset(xStep * (i + 1), y);
      }
    }
    return pos;
  }

  int _calcLevel(Task task, Map<int, int> levels) {
    if (levels.containsKey(task.id)) return levels[task.id]!;
    if (task.dependencies.isEmpty) { levels[task.id] = 0; return 0; }
    int maxP = 0;
    for (final depId in task.dependencies) {
      final dep = tasks.firstWhere((t) => t.id == depId, orElse: () => task);
      if (dep.id != task.id) maxP = max(maxP, _calcLevel(dep, levels));
    }
    levels[task.id] = maxP + 1;
    return maxP + 1;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
