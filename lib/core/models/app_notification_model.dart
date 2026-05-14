class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.recipientMemberId,
    required this.actorUserId,
    required this.type,
    required this.title,
    required this.body,
    required this.entityType,
    required this.entityId,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final String recipientMemberId;
  final String? actorUserId;
  final String type;
  final String title;
  final String? body;
  final String? entityType;
  final String? entityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: _string(json['id']),
      recipientMemberId: _string(json['recipient_member_id']),
      actorUserId: _nullableString(json['actor_user_id']),
      type: _string(json['type'], fallback: 'system'),
      title: _string(json['title'], fallback: 'Notifikasi'),
      body: _nullableString(json['body']),
      entityType: _nullableString(json['entity_type']),
      entityId: _nullableString(json['entity_id']),
      isRead: _bool(json['is_read']),
      readAt: _dateTime(json['read_at']),
      createdAt: _dateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  AppNotificationModel copyWith({
    String? id,
    String? recipientMemberId,
    String? actorUserId,
    String? type,
    String? title,
    String? body,
    String? entityType,
    String? entityId,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      recipientMemberId: recipientMemberId ?? this.recipientMemberId,
      actorUserId: actorUserId ?? this.actorUserId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get relativeTime {
    final now = DateTime.now();
    final localCreatedAt = createdAt.toLocal();
    final difference = now.difference(localCreatedAt);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    }

    return '${localCreatedAt.day}/${localCreatedAt.month}/${localCreatedAt.year}';
  }

  static String _string(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }
    return text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static bool _bool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final text = value?.toString().toLowerCase().trim();
    return text == 'true' || text == '1';
  }

  static DateTime? _dateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}
