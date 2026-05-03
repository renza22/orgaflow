class TaskHistory {
  final int id;
  final String title;
  final String project;
  final String status;
  final String completedAt;
  final String startedAt;

  TaskHistory({
    required this.id,
    required this.title,
    required this.project,
    required this.status,
    required this.completedAt,
    required this.startedAt,
  });
}
