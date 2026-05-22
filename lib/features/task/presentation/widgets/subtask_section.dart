import 'package:flutter/material.dart';

import '../../domain/models/subtask_model.dart';

class SubtaskSection extends StatelessWidget {
  final List<SubtaskModel> subtasks;
  final bool isLoading;
  final String? currentUserEmail;
  final bool canAddSubtask;
  final VoidCallback onAddSubtask;
  final Function(SubtaskModel) onToggleStatus;
  final Function(SubtaskModel) onEdit;
  final Function(SubtaskModel) onDelete;

  const SubtaskSection({
    super.key,
    required this.subtasks,
    required this.isLoading,
    required this.currentUserEmail,
    required this.canAddSubtask,
    required this.onAddSubtask,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Sub-tasks',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 8),
                if (subtasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_completedCount}/${subtasks.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ),
              ],
            ),
            if (canAddSubtask)
              TextButton.icon(
                onPressed: onAddSubtask,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Sub-task'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6C5CE7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (subtasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    canAddSubtask
                        ? 'Belum ada sub-task. Klik "Tambah Sub-task" untuk memecah tugas ini menjadi bagian-bagian kecil.'
                        : 'Belum ada sub-task untuk tugas ini.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: subtasks.map((subtask) {
              return _buildSubtaskItem(context, subtask);
            }).toList(),
          ),
      ],
    );
  }

  int get _completedCount =>
      subtasks.where((s) => s.status == 'done').length;

  Widget _buildSubtaskItem(BuildContext context, SubtaskModel subtask) {
    final isDone = subtask.status == 'done';
    final canEdit = currentUserEmail == subtask.assignedToEmail;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          InkWell(
            onTap: canEdit ? () => onToggleStatus(subtask) : null,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? Colors.green.shade600 : Colors.white,
                border: Border.all(
                  color: isDone ? Colors.green.shade600 : Colors.grey.shade400,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtask.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDone ? Colors.grey.shade600 : Colors.black,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (subtask.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtask.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtask.assignedToName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isDone && subtask.completedAt != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(subtask.completedAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Actions
          if (canEdit)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade600),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit(subtask);
                } else if (value == 'delete') {
                  onDelete(subtask);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Hari ini ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (targetDate == yesterday) {
      return 'Kemarin';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
