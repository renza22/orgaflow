import 'package:flutter/material.dart';
import '../../models/task_model.dart';

class KanbanTab extends StatefulWidget {
  final List<Task> tasks;
  final List<KanbanColumn> columns;
  final void Function(int taskId, TaskStatus newStatus) onMoveTask;
  final VoidCallback onAddTask;

  const KanbanTab({
    super.key,
    required this.tasks,
    required this.columns,
    required this.onMoveTask,
    required this.onAddTask,
  });

  @override
  State<KanbanTab> createState() => _KanbanTabState();
}

class _KanbanTabState extends State<KanbanTab> {
  List<Task> _getTasksByStatus(TaskStatus status) {
    return widget.tasks.where((task) => task.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Text('Kanban board untuk manajemen task proyek',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const Spacer(),
              if (!isSmallScreen)
                ElevatedButton.icon(
                  onPressed: widget.onAddTask,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        // Board — no Expanded, let it size itself
        isSmallScreen || isMediumScreen
            ? _buildScrollableBoard()
            : _buildGridBoard(),
      ],
    );
  }

  Widget _buildScrollableBoard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.columns.map((column) {
            final tasks = _getTasksByStatus(column.status);
            return Container(
              width: 320,
              margin: const EdgeInsets.only(right: 16),
              child: _buildColumn(column, tasks),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGridBoard() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.columns.map((column) {
            final tasks = _getTasksByStatus(column.status);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildColumn(column, tasks),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildColumn(KanbanColumn column, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: Color(column.color), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(column.title.toUpperCase(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text('${tasks.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        // Body — ConstrainedBox replaces Expanded for unbounded parent compatibility
        DragTarget<Task>(
          onWillAcceptWithDetails: (details) => details.data.status != column.status,
          onAcceptWithDetails: (details) => widget.onMoveTask(details.data.id, column.status),
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 200),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isHovering ? Color(column.color).withValues(alpha: 0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHovering ? Color(column.color) : Colors.grey.shade200,
                    width: isHovering ? 2 : 1,
                  ),
                ),
                child: tasks.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Drop task here', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                      ))
                    : Column(
                        children: tasks
                            .map((t) => _buildTaskCard(t, column.color))
                            .toList(),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(Task task, int columnColor) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 280, child: Opacity(opacity: 0.8, child: _buildCardContent(task, columnColor))),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildCardContent(task, columnColor)),
      child: _buildCardContent(task, columnColor),
    );
  }

  Widget _buildCardContent(Task task, int columnColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: Color(columnColor), width: 3),
          right: BorderSide(color: Colors.grey.shade200),
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.drag_indicator, size: 16, color: Colors.grey.shade300),
            const SizedBox(width: 6),
            Expanded(child: Text(task.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(task.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Row(children: [
              if (task.dependencies.isNotEmpty) ...[
                Icon(Icons.account_tree, size: 12, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text('${task.dependencies.length} deps',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                const SizedBox(width: 12),
              ],
              Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('${task.estimatedHours}h', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (task.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Wrap(spacing: 4, runSpacing: 4, children: task.skills.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                child: Text(s, style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
              )).toList()),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(left: 22, top: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: task.assignee.isNotEmpty
                ? Row(children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.2)),
                      ),
                      child: Center(child: Text(task.initials,
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF6C5CE7)))),
                    ),
                    const SizedBox(width: 6),
                    Text(task.assignee, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ])
                : TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('+ Assign', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ),
          ),
        ]),
      ),
    );
  }
}
