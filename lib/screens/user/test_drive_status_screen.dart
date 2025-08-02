import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:varenyam/services/api_config.dart';
import '../../providers/user_test_drives_provider.dart';
import '../../models/test_drive_model.dart';

class TestDriveStatusScreen extends StatefulWidget {
  final bool showBackButton;
  const TestDriveStatusScreen({super.key, this.showBackButton = true});

  @override
  State<TestDriveStatusScreen> createState() => TestDriveStatusScreenState();
}

class TestDriveStatusScreenState extends State<TestDriveStatusScreen> {
  String? _selectedStatusFilter;

  List<TestDriveListResponse> _applyFilters(
      List<TestDriveListResponse> allTestDrives) {
    if (_selectedStatusFilter == null) {
      return List.from(allTestDrives);
    } else {
      return allTestDrives
          .where((testDrive) =>
              testDrive.status?.toLowerCase() ==
              _selectedStatusFilter?.toLowerCase())
          .toList();
    }
  }

  Widget _buildFilterChips() {
    final theme = Theme.of(context);
    final statusOptions = [
      {'label': 'All', 'value': null, 'color': const Color(0xFF2196F3)},
      {
        'label': 'Pending',
        'value': 'pending',
        'color': const Color(0xFFFFA000)
      },
      {
        'label': 'Approved',
        'value': 'approved',
        'color': const Color(0xFF4CAF50)
      },
      {
        'label': 'Completed',
        'value': 'completed',
        'color': const Color(0xFF2196F3)
      },
      {
        'label': 'Rejected',
        'value': 'rejected',
        'color': const Color(0xFFE53935)
      },
      {
        'label': 'Cancelled',
        'value': 'cancelled',
        'color': const Color(0xFFE53935)
      },
      {
        'label': 'Rescheduled',
        'value': 'rescheduled',
        'color': const Color(0xFF9C27B0)
      },
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                avatar: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
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
        return Icons.cancel_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'rescheduled':
        return Icons.schedule_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserTestDrivesProvider>(
      builder: (context, provider, child) {
        final filteredTestDrives = _applyFilters(provider.allTestDrives);
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Test Drive Status',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: widget.showBackButton
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 18),
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 18),
                ),
                onPressed: provider.refresh,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: provider.refresh,
            color: const Color(0xFF0095D9),
            child: Column(
              children: [
                // Filter Chips Section
                if (!provider.isLoading &&
                    provider.errorMessage == null &&
                    provider.allTestDrives.isNotEmpty)
                  _buildFilterChips(),
                // Main Content
                Expanded(
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0095D9),
                          ),
                        )
                      : provider.errorMessage != null
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
                                    provider.errorMessage!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: provider.refresh,
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
                          : filteredTestDrives.isEmpty
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
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredTestDrives.length,
                                  itemBuilder: (context, index) {
                                    final request = filteredTestDrives[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                            color: Colors.grey[200]!),
                                      ),
                                      child: InkWell(
                                        onTap: () =>
                                            _showTestDriveDetails(request),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              // Status icon
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                          request.status ??
                                                              'Unknown')
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  _getStatusIcon(
                                                      request.status ??
                                                          'Unknown'),
                                                  color: _getStatusColor(
                                                      request.status ??
                                                          'Unknown'),
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Main content
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Car name and status in same row
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            request.car?.name ??
                                                                'Unknown',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Color(
                                                                  0xFF1A1A1A),
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _getStatusColor(
                                                                    request.status ??
                                                                        'Unknown')
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                          child: Text(
                                                            _getStatusText(
                                                                request.status ??
                                                                    'Unknown'),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: _getStatusColor(
                                                                  request.status ??
                                                                      'Unknown'),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    // Showroom name
                                                    Text(
                                                      request.showroom?.name ??
                                                          'Unknown',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    // Date and time in same row
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .calendar_today_outlined,
                                                          size: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          request.date ??
                                                              'Unknown',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey[600],
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Icon(
                                                          Icons
                                                              .access_time_rounded,
                                                          size: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          request.time ??
                                                              'Unknown',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey[600],
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    // Pickup location and pincode in same row
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .location_on_outlined,
                                                          size: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            request.pickupCity ??
                                                                'Unknown',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey[600],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Icon(
                                                          Icons
                                                              .pin_drop_outlined,
                                                          size: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          request.pickupPincode ??
                                                              'Unknown',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey[600],
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
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
      },
    );
  }

  void _handleAction(TestDriveListResponse request) {
    switch (request.status?.toLowerCase() ?? '') {
      case 'approved':
      case 'pending':
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const CancelTestDriveScreen(),
        //   ),
        // );
        break;
      case 'completed':
        // Review functionality removed
        break;
      case 'rejected':
      case 'cancelled':
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
                      color: _getStatusColor(request.status ?? 'Unknown')
                          .withOpacity(0.1),
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
                    request.car?.color ?? 'Unknown',
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
                              child: image?.imagePath != null
                                  ? Image.network(
                                      'https://varenyam.acttconnect.com/${image?.imagePath}',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : const SizedBox.shrink(),
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
                        _cleanHtmlDescription(
                            request.car?.description ?? 'Unknown'),
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
                  if (request.driverId != null &&
                      request.driverId!.isNotEmpty) ...[
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
                    const SizedBox(height: 12),
                    // Opening Kilometer
                    if (request.openingKm != null)
                      _buildDetailSection(
                        'Opening Kilometer',
                        [
                          _buildDetailRow(
                              'Opening KM', request.openingKm.toString()),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Closing Kilometer

                    //only for completed test drives
                    if (request.closingKm != null &&
                        request.status?.toLowerCase() == 'completed')
                      _buildDetailSection(
                        'Closing Kilometer',
                        [
                          _buildDetailRow(
                              'Closing KM', request.closingKm.toString()),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Additional section for user-submitted car images
                    if ((request.car_front_img != null &&
                            request.car_front_img!.isNotEmpty) ||
                        (request.back_car_img != null &&
                            request.back_car_img!.isNotEmpty) ||
                        (request.upper_view != null &&
                            request.upper_view!.isNotEmpty) ||
                        (request.right_side_img != null &&
                            request.right_side_img!.isNotEmpty) ||
                        (request.left_side_img != null &&
                            request.left_side_img!.isNotEmpty))
                      _buildDetailSection(
                        'Car Images (Submitted by User)',
                        [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (request.car_front_img != null &&
                                    request.car_front_img!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Column(
                                      children: [
                                        const Text('Front side',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildGalleryImage(
                                                request.car_front_img),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (request.back_car_img != null &&
                                    request.back_car_img!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Column(
                                      children: [
                                        const Text('co-driver side',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildGalleryImage(
                                                request.back_car_img),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (request.right_side_img != null &&
                                    request.right_side_img!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Column(
                                      children: [
                                        const Text('Rear side',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildGalleryImage(
                                                request.right_side_img),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (request.left_side_img != null &&
                                    request.left_side_img!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Column(
                                      children: [
                                        const Text('driver side',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildGalleryImage(
                                                request.left_side_img),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (request.upper_view != null &&
                                    request.upper_view!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Column(
                                      children: [
                                        const Text('Meter reading',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildGalleryImage(
                                                request.upper_view),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Additional section for user-submitted car images

                    // for completed test drives
                    if (request.status?.toLowerCase() == 'completed' &&
                            (request.return_front_img != null &&
                                request.return_front_img!.isNotEmpty) ||
                        (request.return_back_img != null &&
                            request.return_back_img!.isNotEmpty) ||
                        (request.return_right_img != null &&
                            request.return_right_img!.isNotEmpty) ||
                        (request.return_left_img != null &&
                            request.return_left_img!.isNotEmpty) ||
                        (request.return_upper_img != null &&
                            request.return_upper_img!.isNotEmpty))
                      _buildDetailSection(
                        'Car Images (Finished Test Drive)',
                        [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (request.return_front_img != null &&
                                    request.return_front_img!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Column(
                                      children: [
                                        const Text('Return Front side',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildGalleryImage(
                                                request.car_front_img),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (request.return_back_img != null &&
                                    request.return_back_img!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Column(
                                      children: [
                                        const Text('Return co-driver side',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildGalleryImage(
                                                request.back_car_img),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (request.return_right_img != null &&
                                    request.return_right_img!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Column(
                                      children: [
                                        const Text('Return Rear side',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildGalleryImage(
                                                request.right_side_img),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (request.return_left_img != null &&
                                    request.return_left_img!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Column(
                                      children: [
                                        const Text('Return driver side',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildGalleryImage(
                                                request.left_side_img),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (request.return_upper_img != null &&
                                    request.return_upper_img!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: Column(
                                      children: [
                                        const Text('Return Meter reading',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: _buildGalleryImage(
                                                request.upper_view),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildGalleryImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.image,
          color: Colors.grey.shade400,
          size: 32,
        ),
      );
    }

    // Construct the full URL if it's a relative path
    String fullImageUrl = imagePath;
    if (!imagePath.startsWith('http://') && !imagePath.startsWith('https://')) {
      fullImageUrl = '${ApiConfig.baseUrl}/$imagePath';
    }

    return Image.network(
      fullImageUrl,
      fit: BoxFit.fill,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: Icon(
            Icons.image,
            color: Colors.grey.shade400,
            size: 32,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
    String cleaned = htmlDescription
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r' +'), ' ');
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

  void refreshData() {
    final provider =
        Provider.of<UserTestDrivesProvider>(context, listen: false);
    provider.refresh();
  }
}
