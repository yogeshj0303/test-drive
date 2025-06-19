import 'package:flutter/material.dart';
import 'cancel_test_drive_screen.dart';
import 'review_form_screen.dart';

class TestDriveStatusScreen extends StatefulWidget {
  const TestDriveStatusScreen({super.key});

  @override
  State<TestDriveStatusScreen> createState() => _TestDriveStatusScreenState();
}

class _TestDriveStatusScreenState extends State<TestDriveStatusScreen> {
  // Mock data for test drive requests
  final List<Map<String, dynamic>> _testDriveRequests = [
    {
      'id': 'TD001',
      'carName': 'Tata Nexon EV',
      'showroom': 'Tata Motors, Andheri East',
      'date': '2024-03-25',
      'time': '14:00',
      'status': 'approved',
      'duration': '30 mins',
      'hasReview': false,
    },
    {
      'id': 'TD002',
      'carName': 'Mahindra XUV700',
      'showroom': 'Mahindra Auto, Powai',
      'date': '2024-03-28',
      'time': '11:30',
      'status': 'pending',
      'duration': '45 mins',
      'hasReview': false,
    },
    {
      'id': 'TD003',
      'carName': 'Hyundai Creta',
      'showroom': 'Hyundai Motors, Vikhroli',
      'date': '2024-03-20',
      'time': '15:30',
      'status': 'completed',
      'duration': '30 mins',
      'hasReview': false,
    },
    {
      'id': 'TD004',
      'carName': 'Kia Seltos',
      'showroom': 'Kia Motors, Bhandup',
      'date': '2024-03-22',
      'time': '10:00',
      'status': 'cancelled',
      'duration': '45 mins',
      'hasReview': false,
    },
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFFA000);
      case 'completed':
        return const Color(0xFF2196F3);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.pending_actions_outlined;
      case 'completed':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  void _handleAction(Map<String, dynamic> request) {
    switch (request['status']) {
      case 'approved':
      case 'pending':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CancelTestDriveScreen(),
          ),
        );
        break;
      case 'completed':
        if (!request['hasReview']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReviewFormScreen(),
            ),
          ).then((_) {
            // Refresh the list after review submission
            setState(() {
              request['hasReview'] = true;
            });
          });
        }
        break;
    }
  }

  String _getActionText(Map<String, dynamic> request) {
    switch (request['status']) {
      case 'approved':
      case 'pending':
        return 'Cancel Test Drive';
      case 'completed':
        return request['hasReview'] ? 'Reviewed' : 'Leave a Review';
      case 'cancelled':
        return 'Cancelled';
      default:
        return '';
    }
  }

  Color _getActionColor(Map<String, dynamic> request) {
    switch (request['status']) {
      case 'approved':
      case 'pending':
        return Colors.red;
      case 'completed':
        return request['hasReview'] ? const Color(0xFF4CAF50) : const Color(0xFF0095D9);
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showTestDriveDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getStatusIcon(request['status']),
                      color: _getStatusColor(request['status']),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request['carName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Request ID: ${request['id']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Details
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDetailItem(
                    'Showroom',
                    request['showroom'],
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    'Date',
                    request['date'],
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    'Time',
                    request['time'],
                    Icons.access_time_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    'Duration',
                    request['duration'],
                    Icons.timer_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    'Status',
                    _getStatusText(request['status']),
                    _getStatusIcon(request['status']),
                    valueColor: _getStatusColor(request['status']),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Test Drive Status',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _testDriveRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Test Drive Requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Schedule a test drive to see it here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0095D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Schedule Test Drive',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testDriveRequests.length,
              itemBuilder: (context, index) {
                final request = _testDriveRequests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: InkWell(
                    onTap: () => _showTestDriveDetails(request),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(request['status'])
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getStatusIcon(request['status']),
                                  color: _getStatusColor(request['status']),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request['carName'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      request['showroom'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(request['status'])
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusText(request['status']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(request['status']),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Date',
                                  request['date'],
                                  Icons.calendar_today_outlined,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Time',
                                  request['time'],
                                  Icons.access_time_rounded,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Duration',
                                  request['duration'],
                                  Icons.timer_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
} 