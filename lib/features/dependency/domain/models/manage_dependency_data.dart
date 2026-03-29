import '../../../task/domain/models/task_model.dart';
import 'task_dependency_model.dart';

class ManageDependencyData {
  const ManageDependencyData({
    required this.tasks,
    required this.dependencies,
  });

  final List<TaskModel> tasks;
  final List<TaskDependencyModel> dependencies;
}
