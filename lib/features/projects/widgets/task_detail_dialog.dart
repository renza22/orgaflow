import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../../assignment/domain/models/assignment_member_option.dart';

class SubTask {
  final int id;
  final String title;
  final bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    required this.isCompleted,
  });
}

class TaskDetailDialog extends StatefulWidget {
  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSmartAssign;
  final VoidCallback? onManualAssign;
  final String? currentUserEmail;
  final bool canManageTasks;

  const TaskDetailDialog({
    super.key,
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onSmartAssign,
    this.onManualAssign,
    this.currentUserEmail,
    this.canManageTasks = false,
  });

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  final List<SubTask> _subTasks = [];
  final TextEditingController _subTaskController = TextEditingController();

  @override
  void dispose() {
    _subTaskController.dispose();
    super.dispose();
  }

  bool get _isAssignedToCurrentUser {
    return widget.currentUserEmail != null &&
        widget.task.assignee.toLowerCase().contains(widget.currentUserEmail!.toLowerCase());
  }

  bool get _canAddSubTasks {
    return _isAssignedToCurrentUser || widget.canManageTasks;
  }

  void _addSubTask() {
    final title = _subTaskController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _subTasks.add(SubTask(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        isCompleted: false,
      ));
      _subTaskController.clear();
    });
  }

  void _toggleSubTask(int id) {
    setState(() {
      final index = _subTasks.indexWhere((st) => st.id == id);
      if (index != -1) {
        _subTasks[index] = SubTask(
          id: _subTasks[index].id,
          title: _subTasks[index].title,
          isCompleted: !_subTasks[index].isCompleted,
        );
      }
    });
  }

  void _deleteSubTask(int id) {
    setState(() {
      _subTasks.removeWhere((st) => st.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isSmallScreen ? screenWidth - 32 : 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.task.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (widget.onEdit != null)
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onEdit!();
                          },
                          tooltip: 'Edit',
                        ),
                      if (widget.onDelete != null)
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDelete!();
                          },
                          tooltip: 'Delete',
                        ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusBadge(),
                      const SizedBox(width: 12),
                      Text(
                        'ID: #${widget.task.id}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: isSmallScreen
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLeftColumn(),
                          const SizedBox(height: 24),
                          _buildRightColumn(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildLeftColumn()),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildRightColumn()),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Text(
          'Deskripsi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.task.description.isNotEmpty
              ? widget.task.description
              : 'Tidak ada deskripsi',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // Checklist / Sub-tasks
        Row(
          children: [
            Icon(Icons.checklist_outlined,
                size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              'Checklist (${_subTasks.where((st) => st.isCompleted).length}/${_subTasks.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Sub-task list
        if (_subTasks.isNotEmpty)
          ..._subTasks.map((subTask) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: subTask.isCompleted
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: subTask.isCompleted
                      ? Colors.green.shade200
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _canAddSubTasks
                        ? () => _toggleSubTask(subTask.id)
                        : null,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: subTask.isCompleted
                            ? Colors.green.shade600
                            : Colors.white,
                        border: Border.all(
                          color: subTask.isCompleted
                              ? Colors.green.shade600
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: subTask.isCompleted
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subTask.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: subTask.isCompleted
                            ? Colors.grey.shade600
                            : Colors.grey.shade900,
                        decoration: subTask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (_canAddSubTasks)
                    IconButton(
                      icon: Icon(Icons.close,
                          size: 16, color: Colors.grey.shade600),
                      onPressed: () => _deleteSubTask(subTask.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            );
          }).toList(),
        
        // Add sub-task input (only for assigned member or admin)
        if (_canAddSubTasks) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    decoration: InputDecoration(
                      hintText: 'Tambah sub-task...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                    onSubmitted: (_) => _addSubTask(),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: const Color(0xFF6C5CE7),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _addSubTask,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        if (!_canAddSubTasks && _subTasks.isEmpty)
          Text(
            'Tidak ada checklist',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        
        const SizedBox(height: 24),

        // Dependencies
        Row(
          children: [
            Icon(Icons.account_tree_outlined,
                size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              'Dependencies (${widget.task.dependencies.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.task.dependencies.isNotEmpty)
          ...widget.task.dependencies.map((depId) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Desain Banner Utama',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '5h • Sarah Chen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'in-progress',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList()
        else
          Text(
            'Tidak ada dependencies',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assignee
        Text(
          'Assignee',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: widget.onManualAssign,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.task.assignee.isNotEmpty
                        ? widget.task.assignee
                        : 'Assign Member',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.task.assignee.isNotEmpty
                          ? Colors.grey.shade900
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                if (widget.onManualAssign != null)
                  Icon(Icons.arrow_drop_down,
                      size: 20, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Smart Assign Button
        if (widget.onSmartAssign != null)
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onSmartAssign,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text(
                  'Smart Assign',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),

        // Estimasi Waktu
        Text(
          'Estimasi Waktu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.access_time,
                size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              '${widget.task.estimatedHours.toInt()} jam',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Tanggal
        Text(
          'Tanggal',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dibuat',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  _formatDate(DateTime.now()),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.event_outlined,
                size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deadline',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  widget.task.dueDate != null
                      ? _formatDate(widget.task.dueDate!)
                      : 'Belum ditentukan',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Skills Required
        Text(
          'Skills Required',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.task.skills.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.task.skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CEC9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          )
        else
          Text(
            'Tidak ada skill yang dibutuhkan',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;

    switch (widget.task.status) {
      case TaskStatus.backlog:
        color = Colors.grey;
        label = 'Backlog';
        break;
      case TaskStatus.todo:
        color = const Color(0xFF00CEC9);
        label = 'Todo';
        break;
      case TaskStatus.inProgress:
        color = const Color(0xFF6C5CE7);
        label = 'In Progress';
        break;
      case TaskStatus.done:
        color = const Color(0xFF00B894);
        label = 'Done';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
