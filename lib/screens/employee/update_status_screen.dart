import 'package:flutter/material.dart';

class UpdateStatusScreen extends StatefulWidget {
  const UpdateStatusScreen({super.key});

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  bool _isLoading = false;
  bool _showForm = false;
  Map<String, dynamic>? _selectedTestDrive;

  // Mock data - replace with actual API call
  final List<Map<String, dynamic>> _testDrives = [
    {
      'id': 'TD001',
      'customerName': 'Rajesh Kumar',
      'vehicleYear': '2024',
      'vehicleModel': 'Maruti Swift',
      'scheduledDate': '2024-01-15',
      'scheduledTime': '10:00 AM',
      'status': 'Scheduled',
    },
    {
      'id': 'TD002',
      'customerName': 'Priya Sharma',
      'vehicleYear': '2023',
      'vehicleModel': 'Honda City',
      'scheduledDate': '2024-01-15',
      'scheduledTime': '2:00 PM',
      'status': 'In Progress',
    },
    {
      'id': 'TD003',
      'customerName': 'Amit Patel',
      'vehicleYear': '2024',
      'vehicleModel': 'Hyundai i20',
      'scheduledDate': '2024-01-16',
      'scheduledTime': '11:30 AM',
      'status': 'Completed',
    },
    {
      'id': 'TD004',
      'customerName': 'Neha Singh',
      'vehicleYear': '2023',
      'vehicleModel': 'Tata Nexon',
      'scheduledDate': '2024-01-16',
      'scheduledTime': '3:00 PM',
      'status': 'Scheduled',
    },
    {
      'id': 'TD005',
      'customerName': 'Vikram Malhotra',
      'vehicleYear': '2024',
      'vehicleModel': 'Mahindra XUV700',
      'scheduledDate': '2024-01-17',
      'scheduledTime': '9:00 AM',
      'status': 'Scheduled',
    },
    {
      'id': 'TD006',
      'customerName': 'Anjali Desai',
      'vehicleYear': '2023',
      'vehicleModel': 'Kia Sonet',
      'scheduledDate': '2024-01-17',
      'scheduledTime': '1:00 PM',
      'status': 'No Show',
    },
    {
      'id': 'TD007',
      'customerName': 'Rahul Verma',
      'vehicleYear': '2024',
      'vehicleModel': 'MG Hector',
      'scheduledDate': '2024-01-18',
      'scheduledTime': '10:30 AM',
      'status': 'Scheduled',
    },
    {
      'id': 'TD008',
      'customerName': 'Sneha Reddy',
      'vehicleYear': '2023',
      'vehicleModel': 'Toyota Innova Crysta',
      'scheduledDate': '2024-01-18',
      'scheduledTime': '4:00 PM',
      'status': 'Cancelled',
    },
  ];

  void _selectTestDrive(Map<String, dynamic> testDrive) {
    setState(() {
      _selectedTestDrive = testDrive;
      _showForm = true;
    });
  }

  void _goBackToList() {
    setState(() {
      _showForm = false;
      _selectedTestDrive = null;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'No Show':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Scheduled':
        return Icons.schedule;
      case 'In Progress':
        return Icons.play_circle_outline;
      case 'Completed':
        return Icons.check_circle_outline;
      case 'Cancelled':
        return Icons.cancel_outlined;
      case 'No Show':
        return Icons.person_off_outlined;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _showForm ? 'Update Status' : 'Test Drives',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: _showForm ? _goBackToList : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _showForm 
          ? _buildUpdateForm()
          : _buildTestDriveList(),
      ),
    );
  }

  Widget _buildTestDriveList() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                  Icons.directions_car,
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
                      'Test Drive Requests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_testDrives.length} test drives available',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _testDrives.length,
            itemBuilder: (context, index) {
              final testDrive = _testDrives[index];
              final statusColor = _getStatusColor(testDrive['status']);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _selectTestDrive(testDrive),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      testDrive['customerName'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${testDrive['vehicleYear']} ${testDrive['vehicleModel']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(testDrive['status']),
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      testDrive['status'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${testDrive['scheduledDate']} at ${testDrive['scheduledTime']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateForm() {
    return UpdateStatusForm(
      testDrive: _selectedTestDrive,
      onCancel: _goBackToList,
    );
  }
}

class UpdateStatusForm extends StatefulWidget {
  final Map<String, dynamic>? testDrive;
  final VoidCallback onCancel;
  
  const UpdateStatusForm({super.key, this.testDrive, required this.onCancel});

  @override
  State<UpdateStatusForm> createState() => _UpdateStatusFormState();
}

class _UpdateStatusFormState extends State<UpdateStatusForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String _selectedStatus = 'Scheduled';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'Scheduled', 'label': 'Scheduled', 'color': Colors.blue, 'icon': Icons.schedule},
    {'value': 'In Progress', 'label': 'In Progress', 'color': Colors.orange, 'icon': Icons.play_circle_outline},
    {'value': 'Completed', 'label': 'Completed', 'color': Colors.green, 'icon': Icons.check_circle_outline},
    {'value': 'Cancelled', 'label': 'Cancelled', 'color': Colors.red, 'icon': Icons.cancel_outlined},
    {'value': 'No Show', 'label': 'No Show', 'color': Colors.grey, 'icon': Icons.person_off_outlined},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.testDrive != null) {
      _selectedStatus = widget.testDrive!['status'] ?? 'Scheduled';
      _notesController.text = widget.testDrive!['notes'] ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // TODO: Implement actual API call to update status
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Status updated to $_selectedStatus'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        widget.onCancel();
      }
    }
  }

  Color _getStatusColor(String status) {
    final option = _statusOptions.firstWhere((option) => option['value'] == status);
    return option['color'] as Color;
  }

  IconData _getStatusIcon(String status) {
    final option = _statusOptions.firstWhere((option) => option['value'] == status);
    return option['icon'] as IconData;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Drive Information Card
            if (widget.testDrive != null) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3080A5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Color(0xFF3080A5),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Test Drive Details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildModernInfoRow('Customer', widget.testDrive!['customerName'], Icons.person),
                      _buildModernInfoRow('Vehicle', '${widget.testDrive!['vehicleYear']} ${widget.testDrive!['vehicleModel']}', Icons.directions_car),
                      _buildModernInfoRow('Date & Time', '${widget.testDrive!['scheduledDate']} at ${widget.testDrive!['scheduledTime']}', Icons.calendar_today),
                      _buildModernInfoRow('Current Status', widget.testDrive!['status'], _getStatusIcon(widget.testDrive!['status']), 
                        color: _getStatusColor(widget.testDrive!['status'])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Status Selection
            Text(
              'Update Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3080A5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.update,
                            color: Color(0xFF3080A5),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Select New Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_statusOptions.map((status) => _buildStatusOption(status))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Notes Section
            Text(
              'Additional Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3080A5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.note,
                            color: Color(0xFF3080A5),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Notes & Comments',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter any additional notes or comments...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF3080A5), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3080A5), Color(0xFF1E5A7A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Update Status',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey[400])!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color ?? Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(Map<String, dynamic> status) {
    final isSelected = _selectedStatus == status['value'];
    final color = status['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Row(
          children: [
            Icon(
              status['icon'] as IconData,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              status['label'] as String,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
        value: status['value'] as String,
        groupValue: _selectedStatus,
        onChanged: (value) {
          setState(() {
            _selectedStatus = value!;
          });
        },
        activeColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
} 