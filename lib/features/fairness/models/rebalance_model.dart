class RebalanceItem {
  final int id;
  final String taskTitle;
  final String fromMember;
  final String toMember;
  final String reason;
  final int estimatedHours;
  bool? approved;

  RebalanceItem({
    required this.id,
    required this.taskTitle,
    required this.fromMember,
    required this.toMember,
    required this.reason,
    required this.estimatedHours,
    this.approved,
  });

  String get fromInitials {
    final names = fromMember.split(' ');
    return names.map((n) => n[0]).join('');
  }

  String get toInitials {
    final names = toMember.split(' ');
    return names.map((n) => n[0]).join('');
  }
}
