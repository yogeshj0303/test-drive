import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Sample notifications data - In a real app, this would come from an API or database
  final List<Map<String, dynamic>> notifications = [
    {
      'type': 'test_drive',
      'title': 'Test Drive Confirmed',
      'message': 'Your test drive for Tata Nexon EV has been confirmed for tomorrow at 2:00 PM',
      'time': '2 hours ago',
      'isRead': false,
      'icon': Icons.directions_car_rounded,
      'color': Colors.blue,
    },
    {
      'type': 'offer',
      'title': 'Special Offer',
      'message': 'Get 10% off on your first car purchase this month!',
      'time': '5 hours ago',
      'isRead': true,
      'icon': Icons.local_offer_rounded,
      'color': Colors.orange,
    },
    {
      'type': 'reminder',
      'title': 'Test Drive Reminder',
      'message': 'Don\'t forget your test drive for Mahindra XUV700 tomorrow',
      'time': '1 day ago',
      'isRead': true,
      'icon': Icons.notifications_active_rounded,
      'color': Colors.green,
    },
    {
      'type': 'update',
      'title': 'Status Update',
      'message': 'Your car loan application has been approved',
      'time': '2 days ago',
      'isRead': true,
      'icon': Icons.update_rounded,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // TODO: Implement mark all as read functionality
            },
            icon: const Icon(Icons.done_all_rounded, size: 20),
            label: const Text('Mark all as read'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0095D9),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something arrives',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Handle notification tap
          setState(() {
            notification['isRead'] = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notification['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification['icon'],
                  color: notification['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification['isRead']
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: notification['isRead']
                                  ? Colors.grey[800]
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notification['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification['isRead'])
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0095D9),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 