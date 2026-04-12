import 'package:flutter/material.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isOpen = false;

  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: 'Sarah Chen is reaching Overloaded capacity',
      type: NotificationType.warning,
      time: '5 min ago',
    ),
    NotificationItem(
      title: 'New task assigned: API Documentation',
      type: NotificationType.info,
      time: '1 hour ago',
    ),
    NotificationItem(
      title: 'System Update complete',
      type: NotificationType.success,
      time: '2 hours ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onOpened: () => setState(() => _isOpen = true),
      onCanceled: () => setState(() => _isOpen = false),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
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
              const Divider(height: 1),
              ..._notifications.map((notification) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening: ${notification.title}')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4, right: 12),
                          decoration: BoxDecoration(
                            color: notification.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(height: 1),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View all notifications')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: const Text(
                    'View All Notifications',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Stack(
        children: [
          // Pulse animation
          if (!_isOpen)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withOpacity(
                        (1 - _pulseController.value) * 0.5,
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          // Bell icon with badge
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
                    color: _isOpen ? const Color(0xFF6C5CE7) : Colors.grey.shade700,
                    size: 22,
                  ),
                ),
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
                      '${_notifications.length}',
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
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final NotificationType type;
  final String time;

  NotificationItem({
    required this.title,
    required this.type,
    required this.time,
  });

  Color get color {
    switch (type) {
      case NotificationType.warning:
        return Colors.red;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.success:
        return Colors.green;
    }
  }
}

enum NotificationType { warning, info, success }
