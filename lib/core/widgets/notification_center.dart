import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification_model.dart';
import '../session/session_service.dart';
import '../supabase_config.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter>
    with SingleTickerProviderStateMixin {
  static const String _markAllValue = '__mark_all_as_read__';

  late final AnimationController _pulseController;

  final List<AppNotificationModel> _notifications = [];

  RealtimeChannel? _notificationChannel;
  String? _recipientMemberId;
  bool _isOpen = false;
  bool _isLoading = true;
  String? _errorMessage;

  int get _unreadCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  bool get _hasUnread => _unreadCount > 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadNotifications();
  }

  @override
  void dispose() {
    final channel = _notificationChannel;
    if (channel != null) {
      supabase.removeChannel(channel);
    }
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final context = await sessionService.getCurrentContext();
      final memberId = context?.activeMember?.id;

      if (!mounted) {
        return;
      }

      if (memberId == null || memberId.trim().isEmpty) {
        await _removeNotificationChannel();
        if (!mounted) {
          return;
        }
        setState(() {
          _recipientMemberId = null;
          _notifications.clear();
          _isLoading = false;
        });
        _syncPulseAnimation();
        return;
      }

      if (_recipientMemberId != memberId) {
        await _subscribeToNotifications(memberId);
        if (!mounted) {
          return;
        }
      }

      final response = await supabase
          .from('notifications')
          .select(
            'id, recipient_member_id, actor_user_id, type, title, body, '
            'entity_type, entity_id, is_read, read_at, created_at',
          )
          .eq('recipient_member_id', memberId)
          .order('created_at', ascending: false)
          .limit(20);

      if (!mounted) {
        return;
      }

      final notifications = (response as List<dynamic>)
          .map(
            (json) => AppNotificationModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .where((notification) => notification.id.isNotEmpty)
          .toList(growable: false);

      setState(() {
        _recipientMemberId = memberId;
        _notifications
          ..clear()
          ..addAll(notifications);
        _isLoading = false;
        _errorMessage = null;
      });
      _syncPulseAnimation();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications.clear();
        _isLoading = false;
        _errorMessage = 'Gagal memuat notifikasi.';
      });
      _syncPulseAnimation();
    }
  }

  Future<void> _subscribeToNotifications(String memberId) async {
    await _removeNotificationChannel();

    final channel = supabase.channel('notifications:$memberId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_member_id',
          value: memberId,
        ),
        callback: _handleRealtimeNotification,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_member_id',
          value: memberId,
        ),
        callback: _handleRealtimeNotification,
      )
      ..subscribe();

    _notificationChannel = channel;
    _recipientMemberId = memberId;
  }

  Future<void> _removeNotificationChannel() async {
    final channel = _notificationChannel;
    if (channel == null) {
      return;
    }

    _notificationChannel = null;
    await supabase.removeChannel(channel);
  }

  void _handleRealtimeNotification(PostgresChangePayload payload) {
    final record = payload.newRecord;
    if (record.isEmpty) {
      return;
    }

    final notification = AppNotificationModel.fromJson(record);
    if (notification.id.isEmpty ||
        notification.recipientMemberId != _recipientMemberId) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      final index = _notifications.indexWhere(
        (item) => item.id == notification.id,
      );

      if (payload.eventType == PostgresChangeEvent.insert) {
        if (index == -1) {
          _notifications.insert(0, notification);
          if (_notifications.length > 20) {
            _notifications.removeRange(20, _notifications.length);
          }
        } else {
          _notifications[index] = notification;
        }
      } else if (payload.eventType == PostgresChangeEvent.update) {
        if (index != -1) {
          _notifications[index] = notification;
        }
      }
    });
    _syncPulseAnimation();
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    final memberId = _recipientMemberId;
    if (memberId == null) {
      return;
    }

    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index == -1 || _notifications[index].isRead) {
      return;
    }

    final readAt = DateTime.now().toUtc();

    try {
      await supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': readAt.toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('recipient_member_id', memberId);

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: readAt,
        );
      });
      _syncPulseAnimation();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Gagal menandai notifikasi sebagai sudah dibaca.');
    }
  }

  Future<void> _markAllAsRead() async {
    final memberId = _recipientMemberId;
    if (memberId == null || _unreadCount == 0) {
      return;
    }

    final readAt = DateTime.now().toUtc();

    try {
      await supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': readAt.toIso8601String(),
          })
          .eq('recipient_member_id', memberId)
          .eq('is_read', false);

      if (!mounted) {
        return;
      }

      setState(() {
        for (var index = 0; index < _notifications.length; index++) {
          final notification = _notifications[index];
          if (!notification.isRead) {
            _notifications[index] = notification.copyWith(
              isRead: true,
              readAt: readAt,
            );
          }
        }
      });
      _syncPulseAnimation();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Gagal menandai semua notifikasi sebagai sudah dibaca.');
    }
  }

  void _handleMenuOpened() {
    setState(() => _isOpen = true);
    _syncPulseAnimation();
    _loadNotifications();
  }

  void _handleMenuClosed() {
    if (!mounted) {
      return;
    }

    setState(() => _isOpen = false);
    _syncPulseAnimation();
  }

  Future<void> _handleMenuSelection(String value) async {
    _handleMenuClosed();

    if (value == _markAllValue) {
      await _markAllAsRead();
      return;
    }

    await _markNotificationAsRead(value);
  }

  void _syncPulseAnimation() {
    if (!mounted) {
      return;
    }

    if (_hasUnread && !_isOpen) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
      return;
    }

    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    _pulseController.reset();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onOpened: _handleMenuOpened,
      onCanceled: _handleMenuClosed,
      onSelected: _handleMenuSelection,
      itemBuilder: (context) => _buildMenuItems(),
      child: _buildBellButton(),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        enabled: false,
        child: SizedBox(
          width: 320,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
      const PopupMenuDivider(height: 1),
    ];

    if (_isLoading) {
      items.add(
        const PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 320,
            height: 72,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );
    } else if (_errorMessage != null) {
      items.add(
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ),
        ),
      );
    } else if (_notifications.isEmpty) {
      items.add(
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Belum ada notifikasi.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      for (final notification in _notifications) {
        items.add(
          PopupMenuItem<String>(
            value: notification.id,
            child: SizedBox(
              width: 320,
              child: _NotificationMenuItem(notification: notification),
            ),
          ),
        );
      }
    }

    items.add(const PopupMenuDivider(height: 1));
    items.add(
      PopupMenuItem<String>(
        enabled: _unreadCount > 0,
        value: _markAllValue,
        child: SizedBox(
          width: 320,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Mark all as read',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _unreadCount > 0
                      ? const Color(0xFF6C5CE7)
                      : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return items;
  }

  Widget _buildBellButton() {
    return Stack(
      children: [
        if (_hasUnread && !_isOpen)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withValues(
                      alpha: (1 - _pulseController.value) * 0.5,
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _isOpen ? Colors.grey.shade100 : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.notifications_outlined,
                  color:
                      _isOpen ? const Color(0xFF6C5CE7) : Colors.grey.shade700,
                  size: 22,
                ),
              ),
              if (_hasUnread)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationMenuItem extends StatelessWidget {
  const _NotificationMenuItem({
    required this.notification,
  });

  final AppNotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notification.type);
    final body = notification.body?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: notification.isRead ? 0.08 : 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _typeIcon(notification.type),
              size: 14,
              color: color,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        notification.isRead ? FontWeight.w500 : FontWeight.w700,
                    color: notification.isRead
                        ? Colors.grey.shade700
                        : Colors.black,
                  ),
                ),
                if (body != null && body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  notification.relativeTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead) ...[
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(top: 7),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'assignment':
        return Colors.blue;
      case 'dependency':
        return Colors.orange;
      case 'rebalance':
        return const Color(0xFF6C5CE7);
      case 'system':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'assignment':
        return Icons.task_alt;
      case 'dependency':
        return Icons.account_tree_outlined;
      case 'rebalance':
        return Icons.balance_outlined;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }
}
