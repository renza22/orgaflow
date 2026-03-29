class TaskDependencyModel {
  const TaskDependencyModel({
    required this.id,
    required this.dependsOnTaskId,
    required this.dependsOnTaskTitle,
  });

  final String id;
  final String dependsOnTaskId;
  final String dependsOnTaskTitle;
}
