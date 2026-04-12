enum TaskStatus { backlog, todo, inProgress, done }

class Task {
  final int id;
  final String title;
  final String description;
  final String assignee;
  final TaskStatus status;
  final double estimatedHours;
  final List<String> skills;
  final List<int> dependencies;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.status,
    required this.estimatedHours,
    required this.skills,
    required this.dependencies,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? assignee,
    TaskStatus? status,
    double? estimatedHours,
    List<String>? skills,
    List<int>? dependencies,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      status: status ?? this.status,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      skills: skills ?? this.skills,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  String get initials {
    if (assignee.isEmpty) return '';
    final names = assignee.split(' ');
    return names.map((n) => n[0]).join('');
  }
}

class KanbanColumn {
  final String id;
  final String title;
  final TaskStatus status;
  final int color;

  KanbanColumn({
    required this.id,
    required this.title,
    required this.status,
    required this.color,
  });
}
