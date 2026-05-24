enum ActivityType {
  autoBalance,
  taskCreated,
  taskCompleted,
  taskAssigned,
  subTaskAdded,
  taskReassigned,
}

class ActivityLog {
  final String id;
  final ActivityType type;
  final String message;
  final DateTime timestamp;
  final String? actorName;
  final String? targetName;
  final String? projectName;
  final String? taskName;
  final bool isSystemAction;

  ActivityLog({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.actorName,
    this.targetName,
    this.projectName,
    this.taskName,
    this.isSystemAction = false,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: _readString(json['id']),
      type: _parseActivityType(json['activity_type']),
      message: _readString(
        json['message'],
        fallback: 'Aktivitas tercatat.',
      ),
      timestamp: _readDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      actorName: _readNullableString(json['actor_name']),
      targetName: _readNullableString(json['target_name']),
      projectName: _readNullableString(json['project_name']),
      taskName: _readNullableString(json['task_name']),
      isSystemAction: _readBool(json['is_system_action']),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return '${(difference.inDays / 7).floor()} minggu yang lalu';
    }
  }

  static ActivityType _parseActivityType(dynamic value) {
    final normalized = value
        ?.toString()
        .trim()
        .replaceAll(RegExp(r'[_\-\s]+'), '')
        .toLowerCase();

    switch (normalized) {
      case 'autobalance':
        return ActivityType.autoBalance;
      case 'taskcreated':
        return ActivityType.taskCreated;
      case 'taskcompleted':
        return ActivityType.taskCompleted;
      case 'taskassigned':
        return ActivityType.taskAssigned;
      case 'subtaskadded':
        return ActivityType.subTaskAdded;
      case 'taskreassigned':
        return ActivityType.taskReassigned;
      default:
        return ActivityType.taskCreated;
    }
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }
    return text;
  }

  static String? _readNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }

  // Mock data for demonstration
  static List<ActivityLog> getMockData() {
    final now = DateTime.now();
    return [
      ActivityLog(
        id: '1',
        type: ActivityType.autoBalance,
        message:
            "Sistem otomatis merebalance 'Design Homepage Mockup' dari Sarah Chen ke Sophia Wang.",
        timestamp: now.subtract(const Duration(hours: 2)),
        actorName: 'Sistem',
        targetName: 'Sophia Wang',
        projectName: 'Website Redesign',
        taskName: 'Design Homepage Mockup',
        isSystemAction: true,
      ),
      ActivityLog(
        id: '2',
        type: ActivityType.subTaskAdded,
        message:
            "Budi Santoso menambahkan sub-task 'Drafting Anggaran' pada proyek Seminar Nasional IT.",
        timestamp: now.subtract(const Duration(hours: 3)),
        actorName: 'Budi Santoso',
        projectName: 'Seminar Nasional IT',
        taskName: 'Drafting Anggaran',
        isSystemAction: false,
      ),
      ActivityLog(
        id: '3',
        type: ActivityType.taskCompleted,
        message:
            "Emma Davis menyelesaikan task 'User Flow Diagrams' pada proyek Mobile App.",
        timestamp: now.subtract(const Duration(hours: 5)),
        actorName: 'Emma Davis',
        projectName: 'Mobile App',
        taskName: 'User Flow Diagrams',
        isSystemAction: false,
      ),
      ActivityLog(
        id: '4',
        type: ActivityType.taskAssigned,
        message:
            "Mike Johnson menugaskan 'Update API Documentation' kepada Alex Kim.",
        timestamp: now.subtract(const Duration(hours: 25)),
        actorName: 'Mike Johnson',
        targetName: 'Alex Kim',
        taskName: 'Update API Documentation',
        isSystemAction: false,
      ),
      ActivityLog(
        id: '5',
        type: ActivityType.taskCreated,
        message:
            "Sarah Chen membuat task baru 'Wireframe Dashboard' pada proyek Website Redesign.",
        timestamp: now.subtract(const Duration(hours: 25)),
        actorName: 'Sarah Chen',
        projectName: 'Website Redesign',
        taskName: 'Wireframe Dashboard',
        isSystemAction: false,
      ),
      ActivityLog(
        id: '6',
        type: ActivityType.autoBalance,
        message:
            "Sistem otomatis merebalance 'Database Migration' dari Tom Wilson ke Lisa Anderson.",
        timestamp: now.subtract(const Duration(days: 2)),
        actorName: 'Sistem',
        targetName: 'Lisa Anderson',
        taskName: 'Database Migration',
        isSystemAction: true,
      ),
    ];
  }
}
