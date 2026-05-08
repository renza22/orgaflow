class ProfileTaskHistoryModel {
  const ProfileTaskHistoryModel({
    required this.id,
    required this.title,
    required this.projectName,
    required this.status,
    this.assignedAt,
    this.dueDate,
    this.allocationHours,
  });

  final String id;
  final String title;
  final String projectName;
  final String status;
  final DateTime? assignedAt;
  final DateTime? dueDate;
  final int? allocationHours;

  bool get isCompleted => status == 'done';

  String get statusLabel {
    switch (status) {
      case 'backlog':
        return 'Backlog';
      case 'todo':
        return 'To Do';
      case 'in_progress':
        return 'In Progress';
      case 'in_review':
        return 'In Review';
      case 'done':
        return 'Completed';
      case 'blocked':
        return 'Blocked';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.trim().isEmpty ? '-' : status;
    }
  }
}
