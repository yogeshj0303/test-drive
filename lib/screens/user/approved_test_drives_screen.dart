import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../../models/test_drive_model.dart';
import '../../services/api_service.dart';
import '../../services/api_config.dart';
import 'package:provider/provider.dart';
import '../../providers/user_test_drives_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../screens/Employee/location_tracking_screen.dart';

class ApprovedTestDrivesScreen extends StatefulWidget {
  const ApprovedTestDrivesScreen({super.key});

  @override
  State<ApprovedTestDrivesScreen> createState() =>
      _ApprovedTestDrivesScreenState();
}

class _ApprovedTestDrivesScreenState extends State<ApprovedTestDrivesScreen> {
  @override
  void initState() {
    super.initState();
    // Use smart refresh with screen-specific caching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<UserTestDrivesProvider>(context, listen: false);
      provider.smartRefresh(screenName: 'approved');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserTestDrivesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Approved Test Drives',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.grey[200],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 18),
              ),
              onPressed: () => Navigator.pop(
                  context, true), // Return true to indicate screen was visited
            ),
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
          body: provider.isLoadingForScreen('approved')
              ? _buildLoadingWidget()
              : RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: provider.approvedTestDrives.isEmpty
                      ? _buildEmptyStateWidget(provider.lastApiMessage)
                      : _buildTestDrivesList(provider.approvedTestDrives),
                ),
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading your approved test drives...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: Colors.green.shade400,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Approved Test Drives',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'You don\'t have any approved test drives at the moment.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Provider.of<UserTestDrivesProvider>(context, listen: false)
                      .refresh(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestDrivesList(List approvedTestDrives) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: approvedTestDrives.length,
      itemBuilder: (context, index) {
        final request = approvedTestDrives[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showTestDriveDetails(request),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  request.car?.name ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  'Approved',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${request.userName ?? 'Unknown'} • ${request.date ?? 'Unknown'} • ${request.time ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  '${request.pickupCity ?? 'Unknown'}, ${request.pickupPincode ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
          ),
        );
      },
    );
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with car image
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              child: Row(
                children: [
                  // Car Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildCarImage(request.car),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (request.car?.modelNumber != null) ...[
                          Text(
                            request.car!.modelNumber!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            'Approved',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildDetailSection(
                      'Test Drive Information',
                      [
                        _buildDetailRow('Request ID', '#${request.id}'),
                        _buildDetailRow('Date', request.date ?? 'Unknown'),
                        _buildDetailRow('Time', request.time ?? 'Unknown'),
                        _buildDetailRow('Status', 'Approved'),
                        if (request.approvedOrRejectDate != null)
                          _buildDetailRow('Approved On',
                              _formatDateTime(request.approvedOrRejectDate!)),
                      ],
                    ),
                    // Requested By
                    if (request.frontUser != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Requested By',
                        [
                          _buildDetailRow(
                              'Name', request.frontUser?.name ?? 'Unknown'),
                          _buildDetailRow(
                              'Email', request.frontUser?.email ?? 'Unknown'),
                          if ((request.frontUser?.mobileNo ?? '').isNotEmpty)
                            _buildDetailRow(
                                'Mobile', request.frontUser!.mobileNo!),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Pickup Details',
                      [
                        _buildDetailRow(
                            'Address', request.pickupAddress ?? 'Unknown'),
                        _buildDetailRow(
                            'City', request.pickupCity ?? 'Unknown'),
                        _buildDetailRow(
                            'Pincode', request.pickupPincode ?? 'Unknown'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Showroom Information',
                      [
                        _buildDetailRow(
                            'Name', request.showroom?.name ?? 'Unknown'),
                        _buildDetailRow('Location',
                            '${request.showroom?.city ?? 'Unknown'}, ${request.showroom?.state ?? 'Unknown'}'),
                        _buildDetailRow('Rating',
                            '${request.showroom?.ratting ?? 'N/A'} ⭐'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'User Information',
                      [
                        _buildDetailRow('Name', request.userName ?? 'Unknown'),
                        _buildDetailRow(
                            'Mobile', request.userMobile ?? 'Unknown'),
                        _buildDetailRow(
                            'Email', request.userEmail ?? 'Unknown'),

                        // Show Aadhar field
                        _buildDetailRow(
                            'Aadhar',
                            (request.userAdhar != null &&
                                    request.userAdhar!.isNotEmpty &&
                                    request.userAdhar != '0')
                                ? request.userAdhar!
                                : 'Not Available'),
                      ],
                    ),
                    if (request.driverDetails != null) ...[
                      const SizedBox(height: 16),
                      _buildDriverDetailsSection(request.driverDetails),
                    ],
                    const SizedBox(height: 16),
                    if (request.note?.isNotEmpty == true)
                      _buildDetailSection(
                        'Additional Notes',
                        [
                          _buildDetailRow('Note', request.note ?? ''),
                        ],
                      ),

                    if (request.driverId != null &&
                        request.driverId!.isNotEmpty)
                      _buildDetailSection(
                        'Driver Assignment',
                        [
                          _buildDetailRow('Driver ID', request.driverId!),
                          if (request.driverUpdateDate != null)
                            _buildDetailRow('Assigned On',
                                _formatDateTime(request.driverUpdateDate!)),
                        ],
                      ),
                    // --- ENHANCED STATUS SECTIONS ---
                    if (request.approverRejecter != null &&
                        request.approvedOrRejectDate != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Approved By',
                        [
                          _buildDetailRow('Name',
                              request.approverRejecter?.name ?? 'Unknown'),
                          _buildDetailRow('Email',
                              request.approverRejecter?.email ?? 'Unknown'),
                          _buildDetailRow('Date',
                              _formatDateTime(request.approvedOrRejectDate!)),
                        ],
                      ),
                    ],
                    // Completed By section: try completedByUser/completedDate, else comment out
                    /*
                    if (request.completedByUser != null && request.completedDate != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Completed By',
                        [
                          _buildDetailRow('Name', request.completedByUser?.name ?? 'Unknown'),
                          _buildDetailRow('Email', request.completedByUser?.email ?? 'Unknown'),
                          _buildDetailRow('Date', _formatDateTime(request.completedDate!)),
                        ],
                      ),
                    ],
                    */
                    if (request.approverRejecter != null &&
                        request.status == 'rejected') ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Rejected By',
                        [
                          _buildDetailRow('Name',
                              request.approverRejecter?.name ?? 'Unknown'),
                          _buildDetailRow('Email',
                              request.approverRejecter?.email ?? 'Unknown'),
                          if (request.approvedOrRejectDate != null)
                            _buildDetailRow('Date',
                                _formatDateTime(request.approvedOrRejectDate!)),
                          if (request.rejectDescription != null &&
                              request.rejectDescription!.isNotEmpty)
                            _buildDetailRow(
                                'Reason', request.rejectDescription!),
                        ],
                      ),
                    ],
                    if (request.rescheduler != null &&
                        request.rescheduledDate != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Rescheduled By',
                        [
                          _buildDetailRow(
                              'Name', request.rescheduler?.name ?? 'Unknown'),
                          _buildDetailRow(
                              'Email', request.rescheduler?.email ?? 'Unknown'),
                          _buildDetailRow('Rescheduled On',
                              _formatDateTime(request.rescheduledDate!)),
                          if (request.date != null)
                            _buildDetailRow('Next Test Drive Date',
                                _formatDateTime(request.date!)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
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
                                            child: _buildSimpleImage(request.car_front_img),
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
                                        const Text('driver side ',
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
                                            child: _buildSimpleImage(request.left_side_img),
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
                                            child: _buildSimpleImage(request.right_side_img),
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
                                        const Text('co-driver side ',
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
                                            child: _buildSimpleImage(request.back_car_img),
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
                                            child: _buildSimpleImage(request.upper_view),
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
                    const SizedBox(height: 24),
                    // Action Buttons
                    _buildActionButtonsSection(request),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsSection(TestDriveListResponse request) {
    // Check permissions
    final canChangeTestDriveStatus =
        Provider.of<UserTestDrivesProvider>(context, listen: false)
                .currentUser
                ?.role
                ?.permissions
                .canChangeTestDriveStatus ??
            false;
    final canDeleteTestDrive =
        Provider.of<UserTestDrivesProvider>(context, listen: false)
                .currentUser
                ?.role
                ?.permissions
                .canDeleteTestDrive ??
            false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // Live Tracking Button - always visible
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LocationSetupPage(
                    key: GlobalKey<LocationSetupPageState>(),
                    carLongitude: request.car?.longitude,
                    carLatitude: request.car?.latitude,
                    carId: request.car?.id,
                    testDriveId: request.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.location_on, size: 18, color: Colors.blue),
            label: const Text('Live Tracking',
                style: TextStyle(color: Colors.blue)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // Complete Test Drive Button - Only show if user has permission to change status
        if (canChangeTestDriveStatus) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showCompleteBottomSheet(request),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Complete Test Drive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],

        // Reschedule Button - Only show if user has permission to change status
        if (canChangeTestDriveStatus) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: () => _showRescheduleDialog(request),
              icon: const Icon(Icons.schedule, size: 18),
              label: const Text('Reschedule Test Drive'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange.shade400),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],

        // Reject Test Drive Button - Only show if user has permission to change status or delete
        if (canChangeTestDriveStatus || canDeleteTestDrive) ...[
          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRejectDialog(request),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Reject Test Drive'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade400),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],

        // Show message if no permissions
        if (!canChangeTestDriveStatus && !canDeleteTestDrive) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You don\'t have permission to perform actions on this test drive',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showRescheduleDialog(TestDriveListResponse request) {
    // Check permission before showing dialog
    final canChangeTestDriveStatus =
        Provider.of<UserTestDrivesProvider>(context, listen: false)
                .currentUser
                ?.role
                ?.permissions
                .canChangeTestDriveStatus ??
            false;

    if (!canChangeTestDriveStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                    'You don\'t have permission to reschedule test drives'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Reschedule Test Drive',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select new date for ${request.car?.name ?? 'Unknown'}:',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // Date Selection
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The test drive will be rescheduled to the selected date. The time will be arranged by the showroom.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _rescheduleTestDrive(request, selectedDate, '');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reschedule'),
            ),
          ],
        ),
      ),
    );
  }

  // Replace _showCompleteDialog with bottom sheet version
  void _showCompleteBottomSheet(TestDriveListResponse request) {
    final canChangeTestDriveStatus =
        Provider.of<UserTestDrivesProvider>(context, listen: false)
                .currentUser
                ?.role
                ?.permissions
                .canChangeTestDriveStatus ??
            false;
    if (!canChangeTestDriveStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text(
                      'You don\'t have permission to complete test drives')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    final TextEditingController closingKmController = TextEditingController();
    final Map<String, File?> returnImages = {
      'return_front_img': null,
      'return_back_img': null,
      'return_right_img': null,
      'return_left_img': null,
      'return_upper_img': null,
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 6),
                      const Text('Complete Test Drive',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Fix malformed Text widget for car name
                  Text(
                      'Complete test drive for ${request.car?.name ?? 'Unknown'}:',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(height: 10),
                  // Closing KM Input
                  Row(
                    children: [
                      Text('Closing Kilometer Reading',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700)),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text('Required',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: closingKmController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter closing kilometer reading',
                      hintStyle:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.green.shade400),
                      ),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Return Images Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Car Return Images',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text('Required - 5 images',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Image Upload Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3, // more compact
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.0,
                    children: [
                      _buildSimpleImageCard(
                          'Front', 'return_front_img', returnImages, setState),
                      _buildSimpleImageCard(
                          'Back', 'return_back_img', returnImages, setState),
                      _buildSimpleImageCard(
                          'Right', 'return_right_img', returnImages, setState),
                      _buildSimpleImageCard(
                          'Left', 'return_left_img', returnImages, setState),
                      _buildSimpleImageCard(
                          'Upper', 'return_upper_img', returnImages, setState),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress Counter
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          returnImages.values.where((f) => f != null).length ==
                                  5
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: returnImages.values
                                    .where((f) => f != null)
                                    .length ==
                                5
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          returnImages.values.where((f) => f != null).length ==
                                  5
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: returnImages.values
                                      .where((f) => f != null)
                                      .length ==
                                  5
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${returnImages.values.where((f) => f != null).length}/5 images uploaded',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: returnImages.values
                                        .where((f) => f != null)
                                        .length ==
                                    5
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Please provide the closing kilometer reading and 5 car return images (front, back, right, left, upper views).',
                            style: TextStyle(
                                fontSize: 10, color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final closingKm =
                                int.tryParse(closingKmController.text.trim());
                            if (closingKm == null || closingKm <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Please enter a valid closing kilometer reading'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                              return;
                            }
                            if (returnImages.values
                                    .where((f) => f != null)
                                    .length !=
                                5) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Please provide exactly 5 car return images (currently ${returnImages.values.where((f) => f != null).length})'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context);
                            await _simpleCompleteTestDriveWithFiles(
                                request, closingKm, returnImages);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Complete Test Drive',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleImageCard(String label, String fieldName,
      Map<String, File?> images, StateSetter setState) {
    final file = images[fieldName];
    Future<void> _pickImage(ImageSource source) async {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          images[fieldName] = File(picked.path);
        });
      }
    }

    void _showImageSourceDialog() {
      // Directly open camera without showing dialog
      _pickImage(ImageSource.camera);
    }

    return SizedBox(
      height: 60,
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
              color: file != null ? Colors.green : Colors.grey.shade300,
              width: file != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              if (file != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo,
                          size: 20, color: Colors.grey.shade400),
                      const SizedBox(height: 1),
                      Text(label,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                      const SizedBox(height: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('REQUIRED',
                            style: TextStyle(
                                fontSize: 5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              if (file != null)
                Positioned(
                  top: 1,
                  right: 1,
                  child: GestureDetector(
                    onTap: () => setState(() => images[fieldName] = null),
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child:
                          const Icon(Icons.close, color: Colors.white, size: 7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simpleCompleteTestDriveWithFiles(TestDriveListResponse request,
      int closingKm, Map<String, File?> returnImages) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Text(
              'Completing test drive...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
    try {
      final currentUser =
          Provider.of<UserTestDrivesProvider>(context, listen: false)
              .currentUser;
      if (currentUser == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('User data not found. Please login again.')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/employee/textdrives/status-update');
      final requestMultipart = http.MultipartRequest('POST', uri)
        ..fields['employee_id'] = currentUser.id.toString()
        ..fields['status'] = 'completed'
        ..fields['testdrive_id'] = request.id.toString()
        ..fields['closing_km'] = closingKm.toString();
      // Attach images
      for (final entry in returnImages.entries) {
        if (entry.value != null) {
          requestMultipart.files.add(
              await http.MultipartFile.fromPath(entry.key, entry.value!.path));
        }
      }
      requestMultipart.headers.addAll(ApiConfig.defaultHeaders);
      final streamedResponse = await requestMultipart.send();
      final response = await http.Response.fromStream(streamedResponse);
      Navigator.pop(context);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      responseData['message'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
          Provider.of<UserTestDrivesProvider>(context, listen: false)
              .removeTestDrive(request.id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      responseData['message'].isNotEmpty
                          ? responseData['message']
                          : 'Failed to complete test drive',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Connection error. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Connection error. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showRejectDialog(TestDriveListResponse request) {
    // Check permission before showing dialog
    final canChangeTestDriveStatus =
        Provider.of<UserTestDrivesProvider>(context, listen: false)
                .currentUser
                ?.role
                ?.permissions
                .canChangeTestDriveStatus ??
            false;
    final canDeleteTestDrive =
        Provider.of<UserTestDrivesProvider>(context, listen: false)
                .currentUser
                ?.role
                ?.permissions
                .canDeleteTestDrive ??
            false;

    if (!canChangeTestDriveStatus && !canDeleteTestDrive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('You don\'t have permission to reject test drives'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: Colors.red.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Reject Test Drive',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          // <-- Make dialog scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to reject the test drive for ${request.car?.name ?? 'Unknown'}?',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason for rejection (optional):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason for rejection...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red.shade400),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. The test drive will be permanently rejected.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Test Drive',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectTestDrive(request, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reject Test Drive'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTestDrive(TestDriveListResponse request, int closingKm,
      Map<String, String> returnImages) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Text(
              'Completing test drive...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Get current user data to get employee ID
      final currentUser =
          Provider.of<UserTestDrivesProvider>(context, listen: false)
              .currentUser;
      if (currentUser == null) {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('User data not found. Please login again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      // Prepare return images map for API
      Map<String, String> returnImagesMap = {};
      for (final entry in returnImages.entries) {
        returnImagesMap[entry.key] = entry.value;
      }

      // Call the complete test drive API with the correct method
      final response = await ApiService().completeTestDrive(
        testDriveId: request.id,
        employeeId: currentUser.id,
        closingKm: closingKm,
        returnImages: returnImagesMap,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.success) {
        // Close detail modal and return true to indicate data was updated
        Navigator.pop(context, true);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.message,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Optimistically remove the completed test drive from cache
        Provider.of<UserTestDrivesProvider>(context, listen: false)
            .removeTestDrive(request.id);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.message.isNotEmpty
                        ? response.message
                        : 'Failed to complete test drive',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Connection error. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _rejectTestDrive(
      TestDriveListResponse request, String reason) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Text(
              'Rejecting test drive...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Get current user data to get employee ID
      final currentUser =
          Provider.of<UserTestDrivesProvider>(context, listen: false)
              .currentUser;
      if (currentUser == null) {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('User data not found. Please login again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      final rejectDescription =
          reason.isNotEmpty ? reason : 'User rejected the approved test drive';

      final response = await ApiService().cancelTestDrive(
        request.id,
        rejectDescription,
        currentUser.id,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.success) {
        // Close detail modal
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.message,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Refresh the list to remove the rejected test drive
        Provider.of<UserTestDrivesProvider>(context, listen: false).refresh();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.message.isNotEmpty
                        ? response.message
                        : 'Failed to reject test drive',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Connection error. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _rescheduleTestDrive(
      TestDriveListResponse request, DateTime newDate, String reason) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Text(
              'Rescheduling test drive...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Get current user data to get employee ID
      final currentUser =
          Provider.of<UserTestDrivesProvider>(context, listen: false)
              .currentUser;
      if (currentUser == null) {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('User data not found. Please login again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      // Format the new date
      final formattedDate =
          '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';

      // Call the reschedule API
      final response = await ApiService().rescheduleTestDrive(
        request.id,
        formattedDate,
        currentUser.id,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (response.success) {
        // Close detail modal and return true to indicate data was updated
        Navigator.pop(context, true);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.message,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Optimistically remove the rescheduled test drive from cache
        Provider.of<UserTestDrivesProvider>(context, listen: false)
            .removeTestDrive(request.id);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.message,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Connection error. Please try again.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString; // Return original string if parsing fails
    }
  }

  Widget _buildCarImage(TestDriveCar? car) {
    if (car == null) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.directions_car,
          color: Colors.grey.shade400,
          size: 32,
        ),
      );
    }

    // Try to get the main image first
    String? imageUrl = car.mainImage;

    // If no main image, try to get the first image from the images array
    if ((imageUrl == null || imageUrl.isEmpty) &&
        car.images != null &&
        car.images!.isNotEmpty) {
      imageUrl = car.images!.first.imagePath;
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.directions_car,
          color: Colors.grey.shade400,
          size: 32,
        ),
      );
    }

    // Construct the full URL if it's a relative path
    String fullImageUrl = imageUrl;
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      fullImageUrl = '${ApiConfig.baseUrl}/$imageUrl';
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
            Icons.directions_car,
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





  Widget _buildSimpleImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.image,
          color: Colors.grey.shade400,
          size: 24,
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
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: Icon(
            Icons.image,
            color: Colors.grey.shade400,
            size: 24,
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

  Widget _buildDriverDetailsSection(TestDriveUser? driver) {
    if (driver == null) return const SizedBox.shrink();
    return _buildDetailSection(
      'Driver Details',
      [
        if (driver.avatarUrl != null && driver.avatarUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(driver.avatarUrl!),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        _buildDetailRow('Name', driver.name ?? 'Unknown'),
        _buildDetailRow(
            'Mobile', driver.mobileNo ?? driver.mobile ?? 'Unknown'),
        _buildDetailRow('Email', driver.email ?? 'Unknown'),
        _buildDetailRow('Aadhar', driver.aadharNo ?? 'Unknown'),
        _buildDetailRow(
            'Driving License', driver.drivingLicenseNo ?? 'Unknown'),
      ],
    );
  }
}
