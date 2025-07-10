import 'package:flutter/material.dart';
import '../../models/test_drive_model.dart';
import '../../services/driver_api_service.dart';
import '../../services/employee_storage_service.dart';

class UpdateStatusScreen extends StatefulWidget {
  final AssignedTestDrive? selectedTestDrive;
  
  const UpdateStatusScreen({super.key, this.selectedTestDrive});

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  bool _isLoading = false;
  AssignedTestDrive? _selectedTestDrive;

  @override
  void initState() {
    super.initState();
    // Set the selected test drive
    _selectedTestDrive = widget.selectedTestDrive;
  }



  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.blue;
      case 'in_progress':
      case 'in progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.schedule;
      case 'in_progress':
      case 'in progress':
        return Icons.play_circle_outline;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel_outlined;
      case 'rejected':
        return Icons.block;
      default:
        return Icons.schedule;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Scheduled';
      case 'in_progress':
      case 'in progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Update Status',
          style: TextStyle(
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _buildUpdateForm(),
      ),
    );
  }

  Widget _buildUpdateForm() {
    return UpdateStatusForm(
      testDrive: _selectedTestDrive,
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}

class UpdateStatusForm extends StatefulWidget {
  final AssignedTestDrive? testDrive;
  final VoidCallback onCancel;
  
  const UpdateStatusForm({super.key, this.testDrive, required this.onCancel});

  @override
  State<UpdateStatusForm> createState() => _UpdateStatusFormState();
}

class _UpdateStatusFormState extends State<UpdateStatusForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String _selectedStatus = 'completed';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'completed', 'label': 'Completed', 'color': Colors.green, 'icon': Icons.check_circle_outline},
    {'value': 'canceled', 'label': 'Cancelled', 'color': Colors.red, 'icon': Icons.cancel_outlined},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.testDrive != null) {
      // Only allow completed or canceled status for assigned test drives
      if (widget.testDrive!.status == 'approved' || widget.testDrive!.status == 'in_progress') {
        _selectedStatus = 'completed'; // Default to completed for assigned drives
      } else {
        _selectedStatus = widget.testDrive!.status ?? '';
      }
      _notesController.text = widget.testDrive!.note ?? '';
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
      
      try {
        // Get employee data to get the driver ID
        final employee = await EmployeeStorageService.getEmployeeData();
        if (employee == null) {
          _showErrorSnackBar('Employee data not found. Please login again.');
          setState(() => _isLoading = false);
          return;
        }

        final response = await EmployeeApiService().updateTestDriveStatus(
          testDriveId: widget.testDrive!.id,
          driverId: employee.id,
          status: _selectedStatus,
          cancelDescription: _selectedStatus == 'canceled' ? _notesController.text.trim() : null,
        );
        
        setState(() => _isLoading = false);
        
        if (mounted) {
          if (response.success) {
            _showSuccessSnackBar(response.message);
            // Navigate back to the previous screen (AssignedTestDrivesScreen)
            widget.onCancel();
          } else {
            _showErrorSnackBar(response.message);
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          _showErrorSnackBar('An error occurred: ${e.toString()}');
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.blue;
      case 'in_progress':
      case 'in progress':
        return Colors.blue; // Use same color as approved/scheduled
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.schedule;
      case 'in_progress':
      case 'in progress':
        return Icons.schedule; // Use same icon as approved/scheduled
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel_outlined;
      case 'rejected':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Scheduled';
      case 'in_progress':
      case 'in progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.testDrive == null) {
      return const Center(
        child: Text('No test drive selected'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Drive Information Card
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
                    _buildModernInfoRow('Customer', widget.testDrive!.frontUser?.name ?? 'Unknown', Icons.person),
                    _buildModernInfoRow('Vehicle', widget.testDrive!.car?.name ?? 'Unknown', Icons.directions_car),
                    _buildModernInfoRow('Date & Time', '${widget.testDrive!.date} at ${widget.testDrive!.time}', Icons.calendar_today),
                    _buildModernInfoRow('Current Status', _getStatusDisplayName(widget.testDrive!.status ?? ''), _getStatusIcon(widget.testDrive!.status ?? ''), 
                        color: _getStatusColor(widget.testDrive!.status ?? '')),
                    _buildModernInfoRow('Location', widget.testDrive!.car?.showroom?.name ?? 'Unknown', Icons.location_on),
                    if (widget.testDrive!.note?.isNotEmpty == true)
                      _buildModernInfoRow('Notes', widget.testDrive!.note ?? '', Icons.note),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
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
              _selectedStatus == 'canceled' ? 'Cancellation Reason' : 'Additional Notes',
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
                        Text(
                          _selectedStatus == 'canceled' ? 'Reason for Cancellation' : 'Notes & Comments',
                          style: const TextStyle(
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
                      validator: _selectedStatus == 'canceled' 
                          ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please provide a reason for cancellation';
                              }
                              return null;
                            }
                          : null,
                      decoration: InputDecoration(
                        hintText: _selectedStatus == 'canceled' 
                            ? 'Enter the reason for cancellation...'
                            : 'Enter any additional notes or comments...',
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
                      onPressed: () => Navigator.of(context).pop(),
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
} 