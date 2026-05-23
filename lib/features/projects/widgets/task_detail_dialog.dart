import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../../task/data/repositories/subtask_repository.dart';
import '../../task/domain/models/subtask_model.dart';
import '../../task/presentation/widgets/add_subtask_dialog.dart';
import '../../task/presentation/widgets/subtask_section.dart';

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
  final SubtaskRepository _subtaskRepository = SubtaskRepository();

  List<SubtaskModel> _subtasks = const [];
  bool _isLoadingSubtasks = false;
  bool _isSavingSubtask = false;
  String? _subtaskError;

  @override
  void initState() {
    super.initState();
    _loadSubtasks();
  }

  bool get _isAssignedToCurrentUser {
    return widget.task.isAssignedToCurrentUser;
  }

  // PENTING: Hanya member yang di-assign yang bisa menambah sub-task
  // Admin TIDAK bisa menambah sub-task (hanya bisa melihat)
  bool get _canAddSubTasks {
    return _isAssignedToCurrentUser; // Hanya assigned member, bukan admin
  }

  // Admin bisa melihat sub-task tapi tidak bisa edit
  bool get _canViewSubTasks {
    return _isAssignedToCurrentUser || widget.canManageTasks;
  }

  String? get _parentTaskId {
    final taskId = widget.task.sourceTaskId?.trim();
    if (taskId == null || taskId.isEmpty) {
      return null;
    }
    return taskId;
  }

  String? get _currentMemberId {
    for (final assignee in widget.task.assignees) {
      if (assignee.isCurrentUser && assignee.memberId.trim().isNotEmpty) {
        return assignee.memberId.trim();
      }
    }
    return null;
  }

  String get _currentAssigneeName {
    for (final assignee in widget.task.assignees) {
      if (assignee.isCurrentUser && assignee.fullName.trim().isNotEmpty) {
        return assignee.fullName.trim();
      }
    }

    if (widget.task.assignee.trim().isNotEmpty) {
      return widget.task.assignee.trim();
    }

    return 'Diri sendiri';
  }

  Future<void> _loadSubtasks() async {
    final parentTaskId = _parentTaskId;
    if (!_canViewSubTasks || parentTaskId == null) {
      setState(() {
        _subtasks = const [];
        _isLoadingSubtasks = false;
        _subtaskError = null;
      });
      return;
    }

    setState(() {
      _isLoadingSubtasks = true;
      _subtaskError = null;
    });

    final result = await _subtaskRepository.fetchSubtasks(parentTaskId);

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        _subtasks = const [];
        _subtaskError = result.error!.message;
        _isLoadingSubtasks = false;
      });
      return;
    }

    setState(() {
      _subtasks = result.data ?? const [];
      _subtaskError = null;
      _isLoadingSubtasks = false;
    });
  }

  Future<void> _addSubTask() async {
    if (!_canAddSubTasks || _isSavingSubtask) {
      return;
    }

    final parentTaskId = _parentTaskId;
    if (parentTaskId == null) {
      _showMessage('Task utama tidak valid.');
      return;
    }

    final input = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddSubtaskDialog(
        assignedToName: _currentAssigneeName,
      ),
    );

    if (input == null || !mounted) {
      return;
    }

    setState(() {
      _isSavingSubtask = true;
    });

    final result = await _subtaskRepository.createSubtask(
      parentTaskId: parentTaskId,
      title: input['title'] ?? '',
      description: input['description'] ?? '',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingSubtask = false;
    });

    if (result.isFailure) {
      _showMessage(result.error!.message);
      return;
    }

    setState(() {
      _subtasks = [..._subtasks, result.data!];
    });
  }

  Future<void> _toggleSubtaskStatus(SubtaskModel subtask) async {
    if (!_canEditSubtask(subtask) || _isSavingSubtask) {
      return;
    }

    final nextStatus = subtask.status == 'done' ? 'todo' : 'done';
    await _updateSubtask(
      subtaskId: subtask.id,
      status: nextStatus,
    );
  }

  Future<void> _editSubtask(SubtaskModel subtask) async {
    if (!_canEditSubtask(subtask) || _isSavingSubtask) {
      return;
    }

    final input = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddSubtaskDialog(
        initialTitle: subtask.title,
        initialDescription: subtask.description,
        assignedToName: subtask.assignedToName,
        isEdit: true,
      ),
    );

    if (input == null || !mounted) {
      return;
    }

    await _updateSubtask(
      subtaskId: subtask.id,
      title: input['title'] ?? '',
      description: input['description'] ?? '',
    );
  }

  Future<void> _updateSubtask({
    required String subtaskId,
    String? title,
    String? description,
    String? status,
  }) async {
    setState(() {
      _isSavingSubtask = true;
    });

    final result = await _subtaskRepository.updateSubtask(
      subtaskId: subtaskId,
      title: title,
      description: description,
      status: status,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingSubtask = false;
    });

    if (result.isFailure) {
      _showMessage(result.error!.message);
      return;
    }

    final updatedSubtask = result.data!;
    setState(() {
      _subtasks = _subtasks
          .map((item) => item.id == updatedSubtask.id ? updatedSubtask : item)
          .toList();
    });
  }

  Future<void> _deleteSubtask(SubtaskModel subtask) async {
    if (!_canEditSubtask(subtask) || _isSavingSubtask) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Sub-task?'),
        content: Text('Sub-task "${subtask.title}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSavingSubtask = true;
    });

    final result = await _subtaskRepository.deleteSubtask(subtask.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingSubtask = false;
    });

    if (result.isFailure) {
      _showMessage(result.error!.message);
      return;
    }

    setState(() {
      _subtasks = _subtasks.where((item) => item.id != subtask.id).toList();
    });
  }

  bool _canEditSubtask(SubtaskModel subtask) {
    if (!_isAssignedToCurrentUser) {
      return false;
    }

    final currentMemberId = _currentMemberId;
    if (currentMemberId != null &&
        currentMemberId.isNotEmpty &&
        currentMemberId == subtask.assignedMemberId) {
      return true;
    }

    final currentEmail = widget.currentUserEmail?.trim().toLowerCase();
    return currentEmail != null &&
        currentEmail.isNotEmpty &&
        currentEmail == subtask.assignedToEmail.trim().toLowerCase();
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
                          icon: Icon(Icons.edit_outlined,
                              color: Colors.grey.shade600),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onEdit!();
                          },
                          tooltip: 'Edit',
                        ),
                      if (widget.onDelete != null)
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Colors.grey.shade600),
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

        _buildSubtaskArea(),
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
          })
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

  Widget _buildSubtaskArea() {
    if (!_canViewSubTasks) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isAssignedToCurrentUser)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sub-task adalah to-do list pribadi Anda. Otomatis ter-assign ke Anda dan tidak menambah beban jam kerja organisasi.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_subtaskError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _subtaskError!,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                  ),
                ),
                TextButton(
                  onPressed: _isLoadingSubtasks ? null : _loadSubtasks,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        SubtaskSection(
          subtasks: _subtasks,
          isLoading: _isLoadingSubtasks,
          currentUserEmail: widget.currentUserEmail,
          currentMemberId: _currentMemberId,
          canAddSubtask:
              _canAddSubTasks && !_isSavingSubtask && _parentTaskId != null,
          canEditSubtasks: _isAssignedToCurrentUser && !_isSavingSubtask,
          onAddSubtask: _addSubTask,
          onToggleStatus: _toggleSubtaskStatus,
          onEdit: _editSubtask,
          onDelete: _deleteSubtask,
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
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
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
            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
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
            Icon(Icons.event_outlined, size: 16, color: Colors.grey.shade400),
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
