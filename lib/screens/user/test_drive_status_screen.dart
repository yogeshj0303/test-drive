import 'package:flutter/material.dart';
import 'cancel_test_drive_screen.dart';
import 'showrooms_screen.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/test_drive_model.dart';

class TestDriveStatusScreen extends StatefulWidget {
  final bool showBackButton;
  
  const TestDriveStatusScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<TestDriveStatusScreen> createState() => TestDriveStatusScreenState();
}

class TestDriveStatusScreenState extends State<TestDriveStatusScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  List<TestDriveListResponse> _testDriveRequests = [];
  List<TestDriveListResponse> _filteredTestDriveRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;
  
  // Filter state
  String? _selectedStatusFilter;
  


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTestDrives();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isLoading) {
        _refreshData();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app becomes active
    if (state == AppLifecycleState.resumed && mounted && !_isLoading) {
      _refreshData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadTestDrives() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = await _storageService.getUser();
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not found. Please login again.';
        });
        return;
      }

      final response = await _apiService.getUserTestDrives(user.id);
      
      if (response.success) {
        setState(() {
          _testDriveRequests = response.data!;
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading test drives: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> refreshData() async {
    await _refreshData();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final user = await _storageService.getUser();
      if (user == null) {
        setState(() {
          _isRefreshing = false;
          _errorMessage = 'User not found. Please login again.';
        });
        return;
      }

      final response = await _apiService.getUserTestDrives(user.id);
      
      if (response.success) {
        setState(() {
          _testDriveRequests = response.data!;
          _applyFilters();
          _isRefreshing = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while refreshing test drives: ${e.toString()}';
        _isRefreshing = false;
      });
    }
  }

  void _applyFilters() {
    if (_selectedStatusFilter == null) {
      // Show all test drives
      _filteredTestDriveRequests = List.from(_testDriveRequests);
    } else {
      // Filter by selected status
      _filteredTestDriveRequests = _testDriveRequests
          .where((testDrive) => 
              testDrive.status?.toLowerCase() == _selectedStatusFilter?.toLowerCase())
          .toList();
    }
  }



  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFFA000);
      case 'completed':
        return const Color(0xFF2196F3);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFE53935);
      case 'rejected':
        return const Color(0xFFE53935);
      case 'rescheduled':
        return const Color(0xFF9C27B0);
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
      case 'canceled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'rescheduled':
        return 'Rescheduled';
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
      case 'canceled':
        return Icons.cancel_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'rescheduled':
        return Icons.schedule_outlined;
      default:
        return Icons.info_outline;
    }
  }

  void _handleAction(TestDriveListResponse request) {
    switch (request.status?.toLowerCase() ?? '') {
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
        // Review functionality removed
        break;
      case 'rejected':
      case 'cancelled':
      case 'canceled':
      case 'rescheduled':
        // No action for these statuses
        break;
    }
  }

  String _getActionText(TestDriveListResponse request) {
    switch (request.status?.toLowerCase() ?? '') {
      case 'approved':
      case 'pending':
        return 'Cancel Test Drive';
      case 'completed':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return '';
    }
  }

  Color _getActionColor(TestDriveListResponse request) {
    switch (request.status?.toLowerCase() ?? '') {
      case 'approved':
      case 'pending':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
      case 'canceled':
      case 'rejected':
      case 'rescheduled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showTestDriveDetails(TestDriveListResponse request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                      color: _getStatusColor(request.status ?? 'Unknown' ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getStatusIcon(request.status ?? 'Unknown'),
                      color: _getStatusColor(request.status ?? 'Unknown'),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.car?.name ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Request ID: ${request.id}',
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
                  // Test Drive Details Section
                  _buildSectionHeader('Test Drive Details'),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Date',
                    request.date ?? 'Unknown',
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Time',
                    request.time ?? 'Unknown',
                    Icons.access_time_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Status',
                    _getStatusText(request.status ?? 'Unknown'),
                    _getStatusIcon(request.status ?? 'Unknown'),
                    valueColor: _getStatusColor(request.status ?? 'Unknown'),
                  ),
                  const SizedBox(height: 20),
                  
                  // Pickup Details Section
                  _buildSectionHeader('Pickup Details'),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Address',
                    request.pickupAddress ?? 'Unknown',
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'City',
                    request.pickupCity ?? 'Unknown',
                    Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Pincode',
                    request.pickupPincode ?? 'Unknown',
                    Icons.pin_drop_outlined,
                  ),
                  const SizedBox(height: 20),
                  
                  // Car Details Section
                  _buildSectionHeader('Car Details'),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Model',
                    request.car?.modelNumber ?? 'Unknown',
                    Icons.directions_car_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Fuel Type',
                    request.car?.fuelType ?? 'Unknown',
                    Icons.local_gas_station_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Transmission',
                    request.car?.transmission ?? 'Unknown',
                    Icons.settings_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Color',
                    request.car?.color ?? 'Unknown'     ,
                    Icons.palette_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Seating Capacity',
                    '${request.car?.seatingCapacity ?? 'Unknown'} seats',
                    Icons.airline_seat_recline_normal_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Year',
                    request.car?.yearOfManufacture.toString() ?? 'Unknown',
                    Icons.event_outlined,
                  ),
                  if (request.car?.drivetrain != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Drivetrain',
                      request.car?.drivetrain ?? 'Unknown',
                      Icons.settings_input_component_outlined,
                    ),
                  ],
                  if (request.car?.bodyType != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Body Type',
                      request.car?.bodyType ?? 'Unknown',
                      Icons.style_outlined,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Condition',
                    request.car?.condition ?? 'Unknown',
                    Icons.verified_outlined,
                  ),
                  if (request.car?.ratting != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Rating',
                      '${request.car?.ratting}/5',
                      Icons.star_outlined,
                    ),
                  ],
                  const SizedBox(height: 20),
                  
                  // Car Images Section
                  if (request.car?.images?.isNotEmpty == true) ...[
                    _buildSectionHeader('Car Images'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        clipBehavior: Clip.none,
                        scrollDirection: Axis.horizontal,
                        itemCount: request.car?.images?.length ?? 0,
                        itemBuilder: (context, index) {
                          final image = request.car?.images?[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 320,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: image?.imagePath != null ? Image.network(
                                'https://varenyam.acttconnect.com/${image?.imagePath}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {      
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                              ) : const SizedBox.shrink() ,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Car Description Section
                    if (request.car?.description?.isNotEmpty == true) ...[
                    _buildSectionHeader('Car Description'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        _cleanHtmlDescription(request.car?.description ?? 'Unknown'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Showroom Details Section
                  _buildSectionHeader('Showroom Details'),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Name',
                    request.showroom?.name ?? 'Unknown',
                    Icons.store_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Address',
                    request.showroom?.address ?? 'Unknown',
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'City',
                    request.showroom?.city ?? 'Unknown',
                    Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Pincode',
                    request.showroom?.pincode ?? 'Unknown',
                    Icons.pin_drop_outlined,
                  ),
                  const SizedBox(height: 20),
                  
                  // Additional Details Section
                  _buildSectionHeader('Additional Details'),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Driving License',
                    request.drivingLicense ?? 'Unknown',
                    Icons.credit_card_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Aadhar Number',
                    request.aadharNo ?? 'Unknown',
                    Icons.badge_outlined,
                  ),
                  if (request.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Notes',
                      request.note ?? 'Unknown',
                      Icons.note_outlined,
                    ),
                  ],
                  if (request.rejectDescription?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Rejection Reason',
                      request.rejectDescription ?? 'Unknown',
                      Icons.cancel_outlined,
                      valueColor: Colors.red,
                    ),
                  ],
                  if (request.cancelDescription?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Cancellation Reason',
                      request.cancelDescription ?? 'Unknown',
                      Icons.cancel_outlined,
                      valueColor: Colors.red,
                    ),
                  ],
                  if (request.cancelDateTime != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Cancellation Date',
                      request.cancelDateTime ?? 'Unknown',
                      Icons.event_outlined,
                      valueColor: Colors.red,
                    ),
                  ],
                  if (request.rescheduledDate != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Rescheduled Date',
                      request.rescheduledDate ?? 'Unknown',
                      Icons.schedule_outlined,
                      valueColor: const Color(0xFF9C27B0),
                    ),
                  ],
                  if (request.approverRejecter != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Processed By',
                      request.approverRejecter?.name ?? 'Unknown',
                      Icons.person_outline,
                    ),
                  ],
                  if (request.approvedOrRejectDate != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Processed Date',
                      request.approvedOrRejectDate ?? 'Unknown',
                      Icons.event_outlined,
                    ),
                  ],
                  if (request.rescheduler != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Rescheduled By',
                      request.rescheduler?.name ?? 'Unknown',
                      Icons.person_outline,
                    ),
                  ],
                  if (request.driverId != null && request.driverId!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Assigned Driver ID',
                      request.driverId ?? 'Unknown',
                      Icons.drive_eta_outlined,
                    ),
                  ],
                  if (request.driverUpdateDate != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Driver Update Date',
                      request.driverUpdateDate ?? 'Unknown',
                      Icons.update_outlined,
                    ),
                  ],
                  if (request.requestbyEmplyee != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      'Requested By',
                      request.requestbyEmplyee?.name ?? 'Unknown',
                      Icons.person_add_outlined,
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  String _cleanHtmlDescription(String htmlDescription) {
    // Remove HTML tags and decode HTML entities
    String cleaned = htmlDescription
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ') // Replace &nbsp; with space
        .replaceAll('&amp;', '&') // Replace &amp; with &
        .replaceAll('&lt;', '<') // Replace &lt; with <
        .replaceAll('&gt;', '>') // Replace &gt; with >
        .replaceAll('&quot;', '"') // Replace &quot; with "
        .replaceAll('&#39;', "'") // Replace &#39; with '
        .replaceAll('\r\n', '\n') // Normalize line breaks
        .replaceAll('\r', '\n') // Normalize line breaks
        .trim(); // Remove leading/trailing whitespace
    
    // Remove extra whitespace and normalize
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n'), '\n\n'); // Remove multiple empty lines
    cleaned = cleaned.replaceAll(RegExp(r' +'), ' '); // Replace multiple spaces with single space
    
    return cleaned;
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
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A1A1A)),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF0095D9),
        child: Column(
          children: [
            // Filter Chips Section
            if (!_isLoading && _errorMessage == null && _testDriveRequests.isNotEmpty)
              _buildFilterChips(),
            
            // Main Content
            Expanded(
              child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0095D9),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Test Drives',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadTestDrives,
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
                            'Retry',
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
                : _testDriveRequests.isEmpty
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
                              'You haven\'t scheduled any test drives yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to showrooms screen to browse available cars
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => const ShowroomsScreen(),
                                //   ),
                                // );
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
                                'Browse Showrooms',
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
                        itemCount: _filteredTestDriveRequests.length,
                        itemBuilder: (context, index) {
                          final request = _filteredTestDriveRequests[index];
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
                                            color: _getStatusColor(request.status ?? 'Unknown')
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _getStatusIcon(request.status ?? 'Unknown'),
                                            color: _getStatusColor(request.status ?? 'Unknown'),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                request.car?.name ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1A1A1A),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                request.showroom?.name ?? 'Unknown',
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
                                            color: _getStatusColor(request.status ?? 'Unknown')
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _getStatusText(request.status ?? 'Unknown'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _getStatusColor(request.status ?? 'Unknown'),
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
                                            request.date ?? 'Unknown',
                                            Icons.calendar_today_outlined,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildInfoItem(
                                            'Time',
                                            request.time ?? 'Unknown',
                                            Icons.access_time_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoItem(
                                            'Pickup',
                                            request.pickupCity ?? 'Unknown',
                                            Icons.location_on_outlined,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildInfoItem(
                                            'Pincode',
                                            request.pickupPincode ?? 'Unknown',
                                            Icons.pin_drop_outlined,
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
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildFilterChips() {
    final theme = Theme.of(context);
    final statusOptions = [
      {'label': 'All', 'value': null, 'color': const Color(0xFF2196F3)},
      {'label': 'Pending', 'value': 'pending', 'color': const Color(0xFFFFA000)},
      {'label': 'Approved', 'value': 'approved', 'color': const Color(0xFF4CAF50)},
      {'label': 'Completed', 'value': 'completed', 'color': const Color(0xFF2196F3)},
      {'label': 'Rejected', 'value': 'rejected', 'color': const Color(0xFFE53935)},
      {'label': 'Cancelled', 'value': 'cancelled', 'color': const Color(0xFFE53935)},
      {'label': 'Rescheduled', 'value': 'rescheduled', 'color': const Color(0xFF9C27B0)},
    ];
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: statusOptions.map((status) {
            final isSelected = _selectedStatusFilter == status['value'];
            final statusColor = status['color'] as Color;
            
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  status['label'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedStatusFilter = status['value'] as String?;
                    _applyFilters();
                  });
                },
                backgroundColor: theme.colorScheme.surfaceVariant,
                selectedColor: statusColor,
                checkmarkColor: theme.colorScheme.onPrimary,
                side: BorderSide(
                  color: isSelected 
                      ? statusColor 
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                avatar: isSelected ? Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ) : null,
              ),
            );
          }).toList(),
        ),
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