import 'package:flutter/material.dart';

class EmployeeNotificationScreen extends StatefulWidget {
  const EmployeeNotificationScreen({super.key});

  @override
  State<EmployeeNotificationScreen> createState() => _EmployeeNotificationScreenState();
}

class _EmployeeNotificationScreenState extends State<EmployeeNotificationScreen> {
  // Sample notifications data for employees
  final List<Map<String, dynamic>> notifications = [
    {
      'type': 'test_drive_assignment',
      'title': 'New Test Drive Assignment',
      'message': 'You have been assigned a test drive for Tesla Model 3 with John Smith at 2:00 PM today',
      'time': '30 minutes ago',
      'isRead': false,
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFF3080A5),
    },
    {
      'type': 'expense_approval',
      'title': 'Expense Approved',
      'message': 'Your fuel expense of \$45.00 for test drive on BMW X5 has been approved',
      'time': '2 hours ago',
      'isRead': false,
      'icon': Icons.receipt_long_rounded,
      'color': Colors.green,
    },
    {
      'type': 'status_update',
      'title': 'Test Drive Status Updated',
      'message': 'Customer completed test drive for Mercedes C-Class. Please update final status',
      'time': '4 hours ago',
      'isRead': true,
      'icon': Icons.update_rounded,
      'color': Colors.orange,
    },
    {
      'type': 'reminder',
      'title': 'Test Drive Reminder',
      'message': 'You have a test drive scheduled for Audi A4 with Sarah Johnson in 1 hour',
      'time': '1 hour ago',
      'isRead': true,
      'icon': Icons.notifications_active_rounded,
      'color': Colors.purple,
    },
    {
      'type': 'location_required',
      'title': 'Location Tracking Required',
      'message': 'Please enable location tracking for your current test drive session',
      'time': '3 hours ago',
      'isRead': true,
      'icon': Icons.location_on_rounded,
      'color': Colors.red,
    },
    {
      'type': 'performance',
      'title': 'Monthly Performance Update',
      'message': 'You completed 15 test drives this month. Great job!',
      'time': '1 day ago',
      'isRead': true,
      'icon': Icons.trending_up_rounded,
      'color': Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3080A5);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _markAllAsRead(),
            icon: const Icon(Icons.done_all_rounded, size: 20, color: Colors.white),
            label: const Text(
              'Mark all as read',
              style: TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildNotificationStats(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationStats() {
    final unreadCount = notifications.where((n) => !n['isRead']).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3080A5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF3080A5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '$unreadCount unread • ${notifications.length} total',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            'You\'ll be notified about test drives, expenses, and updates',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification['isRead'] 
                  ? Colors.grey[200]! 
                  : notification['color'].withOpacity(0.2),
              width: notification['isRead'] ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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
                    const SizedBox(height: 8),
                    _buildActionButtons(notification),
                  ],
                ),
              ),
              if (!notification['isRead'])
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: notification['color'],
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'test_drive_assignment':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleTestDriveAction(notification),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3080A5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        );
      case 'expense_approval':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleExpenseAction(notification),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Receipt',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        );
      case 'status_update':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleStatusUpdateAction(notification),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Update Status',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    setState(() {
      notification['isRead'] = true;
    });
    
    // Handle different notification types
    switch (notification['type']) {
      case 'test_drive_assignment':
        _handleTestDriveAction(notification);
        break;
      case 'expense_approval':
        _handleExpenseAction(notification);
        break;
      case 'status_update':
        _handleStatusUpdateAction(notification);
        break;
      case 'location_required':
        _handleLocationAction(notification);
        break;
      default:
        // Show a snackbar for other notification types
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Handling ${notification['title']}'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  void _handleTestDriveAction(Map<String, dynamic> notification) {
    // Navigate to assigned test drives screen
    Navigator.pop(context); // Close notification screen
    // You can add navigation logic here when the assigned test drives screen is ready
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening test drive details...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleExpenseAction(Map<String, dynamic> notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening expense details...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleStatusUpdateAction(Map<String, dynamic> notification) {
    Navigator.pop(context); // Close notification screen
    // You can add navigation logic here when the update status screen is ready
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening status update...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleLocationAction(Map<String, dynamic> notification) {
    Navigator.pop(context); // Close notification screen
    // You can add navigation logic here when the location tracking screen is ready
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening location tracking...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification['isRead'] = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }
} 