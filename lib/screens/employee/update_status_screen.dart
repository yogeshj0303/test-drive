import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/test_drive_model.dart';
import '../../models/employee_model.dart';
import '../../services/driver_api_service.dart';
import '../../services/employee_storage_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UpdateStatusScreen extends StatefulWidget {
  final AssignedTestDrive? selectedTestDrive;
  
  const UpdateStatusScreen({super.key, this.selectedTestDrive});

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  bool _isLoading = false;
  AssignedTestDrive? _selectedTestDrive;
  final GlobalKey<_UpdateStatusFormState> _formKey = GlobalKey<_UpdateStatusFormState>();

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Update Status',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
        actions: [
        ],
      ),
      body: SafeArea(
        child: _buildUpdateForm(),
      ),
    );
  }

  void _resetForm() {
    // Reset the form state
    _formKey.currentState?.resetForm();
    setState(() {
      _selectedTestDrive = widget.selectedTestDrive;
    });
  }

  Widget _buildUpdateForm() {
    return UpdateStatusForm(
      key: _formKey,
      testDrive: _selectedTestDrive,
      onCancel: () => Navigator.of(context).pop(),
      onReset: _resetForm,
    );
  }
}

class UpdateStatusForm extends StatefulWidget {
  final AssignedTestDrive? testDrive;
  final VoidCallback onCancel;
  final VoidCallback? onReset;
  
  const UpdateStatusForm({super.key, this.testDrive, required this.onCancel, this.onReset});

  @override
  State<UpdateStatusForm> createState() => _UpdateStatusFormState();
}

class _UpdateStatusFormState extends State<UpdateStatusForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String _selectedStatus = 'completed';
  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _closingKmController = TextEditingController();
  final Map<String, File?> _returnImages = {
    'return_front_img': null,
    'return_back_img': null,
    'return_right_img': null,
    'return_left_img': null,
    'return_upper_img': null,
  };
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'completed', 'label': 'Completed', 'color': Colors.green, 'icon': Icons.check_circle_outline},
    {'value': 'cancelled', 'label': 'Cancelled', 'color': Colors.red, 'icon': Icons.cancel_outlined},
    {'value': 'rescheduled', 'label': 'Reschedule', 'color': const Color(0xFF9C27B0), 'icon': Icons.schedule},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.testDrive != null) {
      // Only allow completed or cancelled status for assigned test drives
      if (widget.testDrive!.status == 'approved' || widget.testDrive!.status == 'in_progress') {
        _selectedStatus = 'completed'; // Default to completed for assigned drives
      } else {
        _selectedStatus = widget.testDrive!.status ?? '';
      }
      _notesController.text = widget.testDrive!.note ?? '';
    }
  }

  bool _canUpdateStatus() {
    if (widget.testDrive == null) return false;
    
    final status = widget.testDrive!.status?.toLowerCase() ?? '';
    // Only allow updates if status is not cancelled or completed
    return status != 'cancelled' && status != 'completed';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _closingKmController.dispose();
    super.dispose();
  }

  void resetForm() {
    setState(() {
      _selectedStatus = 'completed';
      _notesController.clear();
      _selectedDate = null;
      _selectedTime = null;
    });
    
    // Call the parent reset callback if provided
    widget.onReset?.call();
  }

  Future<void> _updateStatus() async {
    if (_formKey.currentState!.validate()) {
      // Validate date for rescheduling
      if (_selectedStatus == 'rescheduled') {
        if (_selectedDate == null) {
          _showErrorSnackBar('Please select a new date for rescheduling');
          return;
        }
      }
      // Validate for completed: closing_km and images
      if (_selectedStatus == 'completed') {
        if (_closingKmController.text.trim().isEmpty) {
          _showErrorSnackBar('Please enter the closing KM');
          return;
        }
        for (final key in _returnImages.keys) {
          if (_returnImages[key] == null) {
            _showErrorSnackBar('Please select all required return images');
            return;
          }
        }
      }
      setState(() => _isLoading = true);
      try {
        final employee = await EmployeeStorageService.getEmployeeData();
        if (employee == null) {
          _showErrorSnackBar('Employee data not found. Please login again.');
          setState(() => _isLoading = false);
          return;
        }
        EmployeeApiResponse<Map<String, dynamic>> response;
        if (_selectedStatus == 'rescheduled') {
          final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
          response = await EmployeeApiService().rescheduleTestDrive(
            testDriveId: widget.testDrive!.id,
            driverId: employee.id,
            newDate: formattedDate,
            reason: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );
        } else if (_selectedStatus == 'completed') {
          // Prepare images map (non-null)
          final images = <String, File>{};
          _returnImages.forEach((k, v) { if (v != null) images[k] = v!; });
          response = await EmployeeApiService().completeTestDriveWithImages(
            driverId: employee.id,
            testDriveId: widget.testDrive!.id,
            closingKm: int.parse(_closingKmController.text.trim()),
            returnImages: images,
          );
        } else {
          response = await EmployeeApiService().updateTestDriveStatus(
            testDriveId: widget.testDrive!.id,
            driverId: employee.id,
            status: _selectedStatus,
            cancelDescription: _selectedStatus == 'cancelled' ? _notesController.text.trim() : null,
          );
        }
        setState(() => _isLoading = false);
        if (mounted) {
          if (response.success) {
            _showSuccessSnackBar(response.message);
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
        return Colors.red;
      case 'rejected':
        return Colors.red;
      case 'rescheduled':
        return const Color(0xFF9C27B0);
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
        return Icons.cancel_outlined;
      case 'rejected':
        return Icons.block;
      case 'rescheduled':
        return Icons.schedule;
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
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'rescheduled':
        return 'Rescheduled';
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

    // Check if status can be updated
    final canUpdate = _canUpdateStatus();

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
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
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
            
            // Status Update Disabled Message
            if (!canUpdate) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This test drive cannot be updated because it is already ${_getStatusDisplayName(widget.testDrive!.status ?? '').toLowerCase()}.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Status Selection
            Text(
              'Update Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: canUpdate ? Colors.black87 : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
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
                    ...(_statusOptions.map((status) => _buildStatusOption(status, enabled: canUpdate))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date and Time Selection for Rescheduling
            if (_selectedStatus == 'rescheduled' && canUpdate) ...[
              Text(
                'New Date & Time',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
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
                              color: const Color(0xFF9C27B0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: Color(0xFF9C27B0),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Select New Date & Time',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedDate != null
                                          ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                                          : 'Select Date',
                                      style: TextStyle(
                                        color: _selectedDate != null ? Colors.black87 : Colors.grey[500],
                                        fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 18,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedTime != null
                                          ? _selectedTime!.format(context)
                                          : 'Select Time',
                                      style: TextStyle(
                                        color: _selectedTime != null ? Colors.black87 : Colors.grey[500],
                                        fontWeight: _selectedTime != null ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Notes Section
            if (canUpdate) ...[
              Text(
                _selectedStatus == 'cancelled' 
                    ? 'Cancellation Reason' 
                    : _selectedStatus == 'rescheduled'
                        ? 'Rescheduling Reason'
                        : 'Additional Notes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
            if (canUpdate) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
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
                            _selectedStatus == 'cancelled' 
                                ? 'Reason for Cancellation' 
                                : _selectedStatus == 'rescheduled'
                                    ? 'Reason for Rescheduling'
                                    : 'Notes & Comments',
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
                        enabled: canUpdate,
                        validator: _selectedStatus == 'cancelled' || _selectedStatus == 'rescheduled'
                            ? (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return _selectedStatus == 'cancelled' 
                                      ? 'Please provide a reason for cancellation'
                                      : 'Please provide a reason for rescheduling';
                                }
                                return null;
                              }
                            : null,
                        decoration: InputDecoration(
                          hintText: _selectedStatus == 'cancelled' 
                              ? 'Enter the reason for cancellation...'
                              : _selectedStatus == 'rescheduled'
                                  ? 'Enter the reason for rescheduling...'
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
            ],
            if (_selectedStatus == 'completed' && canUpdate) ...[
              const SizedBox(height: 16),
              Text('Closing KM', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _closingKmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter closing KM',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_selectedStatus == 'completed' && (value == null || value.trim().isEmpty)) {
                    return 'Closing KM is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Return Car Images (Required)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _returnImages.keys.map((key) => _buildImagePicker(key)).toList(),
              ),
            ],
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
                      onPressed: (canUpdate && !_isLoading) ? _updateStatus : null,
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

  Widget _buildStatusOption(Map<String, dynamic> status, {bool enabled = true}) {
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
              color: enabled ? color : Colors.grey[400],
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              status['label'] as String,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: enabled 
                    ? (isSelected ? color : Colors.black87)
                    : Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
        value: status['value'] as String,
        groupValue: _selectedStatus,
        onChanged: enabled ? (value) {
          setState(() {
            _selectedStatus = value!;
          });
        } : null,
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3080A5),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3080A5),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
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

  Widget _buildImagePicker(String key) {
    final labelMap = {
      'return_front_img': 'Front',
      'return_back_img': 'Back',
      'return_right_img': 'Right',
      'return_left_img': 'Left',
      'return_upper_img': 'Upper',
    };
    final file = _returnImages[key];
    return GestureDetector(
      onTap: () async {
        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (picked != null) {
          setState(() {
            _returnImages[key] = File(picked.path);
          });
        }
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: file != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _returnImages[key] = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, color: Color(0xFF3080A5), size: 28),
                    const SizedBox(height: 4),
                    Text(labelMap[key] ?? key, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
      ),
    );
  }
} 