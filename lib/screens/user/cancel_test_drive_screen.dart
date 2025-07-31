import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/test_drive_model.dart';
import '../../models/user_model.dart';
import '../../services/api_config.dart';
import 'package:provider/provider.dart';
import '../../providers/user_test_drives_provider.dart';

class CancelTestDriveScreen extends StatefulWidget {
  const CancelTestDriveScreen({super.key});

  @override
  State<CancelTestDriveScreen> createState() => _CancelTestDriveScreenState();
}

class _CancelTestDriveScreenState extends State<CancelTestDriveScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  List<TestDriveListResponse> _cancelledTestDrives = [];
  bool _isLoading = true;
  String? _errorMessage;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Use smart refresh with screen-specific caching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserTestDrivesProvider>(context, listen: false);
      provider.smartRefresh(screenName: 'rejected');
    });
  }

  void _showTestDriveDetails(TestDriveListResponse testDrive) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12),
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
                  // Car Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildCarImage(testDrive.car),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testDrive.car?.name ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        // const SizedBox(height: 2),
                        // if (testDrive.car?.modelNumber != null) ...[
                        //   Text(
                        //     testDrive.car!.modelNumber!,
                        //     style: TextStyle(
                        //       fontSize: 13,
                        //       color: Colors.grey[600],
                        //     ),
                        //   ),
                        //   const SizedBox(height: 2),
                        // ],
                        Text(
                          testDrive.showroom?.name ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'REJECTED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.red[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car Images Gallery
                    if (testDrive.car?.images != null && testDrive.car!.images!.isNotEmpty)
                      _buildCarImagesGallery(testDrive.car!.images!),
                    
                    const SizedBox(height: 16),
                    // Main Details Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildModernDetailRow('Date', testDrive.date ?? 'Unknown', Icons.calendar_today_outlined),
                          const SizedBox(height: 12),
                          _buildModernDetailRow('Time', testDrive.time ?? 'Unknown', Icons.access_time_rounded),
                          const SizedBox(height: 12),
                          _buildModernDetailRow('Pickup Address', testDrive.pickupAddress ?? 'Unknown', Icons.location_on_outlined),
                          const SizedBox(height: 12),
                          _buildModernDetailRow('Pickup City', testDrive.pickupCity ?? 'Unknown', Icons.location_city_outlined),
                          const SizedBox(height: 12),
                          _buildModernDetailRow('Status', testDrive.status?.toUpperCase() ?? 'Unknown', Icons.info_outline),
                          if (testDrive.approvedOrRejectDate != null && testDrive.approvedOrRejectDate!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildModernDetailRow('Rejected On', _formatDateTime(testDrive.approvedOrRejectDate!), Icons.cancel_outlined),
                          ],
                        ],
                      ),
                    ),
                    
                    // Rejection Reason Section
                    if (testDrive.rejectDescription != null && testDrive.rejectDescription!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.block_outlined,
                                  size: 14,
                                  color: Colors.red[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Rejection Reason',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              testDrive.rejectDescription!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Note Section
                    if (testDrive.note?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.note_outlined,
                                  size: 14,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Note',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              testDrive.note ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Rejected By Section
                    if (testDrive.approverRejecter != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.orange[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_off_outlined,
                                  size: 14,
                                  color: Colors.orange[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Rejected By',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              testDrive.approverRejecter!.name ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (testDrive.approverRejecter!.email != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                testDrive.approverRejecter!.email!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    
                    // After the main details and before the action buttons in the test drive detail modal, add:
                    if (testDrive.approverRejecter != null && testDrive.approvedOrRejectDate != null) ...[
                      const SizedBox(height: 16),
                      _buildModernDetailRow('Rejected By', testDrive.approverRejecter?.name ?? 'Unknown', Icons.person_off_outlined),
                      _buildModernDetailRow('Email', testDrive.approverRejecter?.email ?? 'Unknown', Icons.email_outlined),
                      _buildModernDetailRow('Date', _formatDateTime(testDrive.approvedOrRejectDate!), Icons.cancel_outlined),
                      if (testDrive.rejectDescription != null && testDrive.rejectDescription!.isNotEmpty)
                        _buildModernDetailRow('Reason', testDrive.rejectDescription!, Icons.block_outlined),
                    ],
                    
                    // Bottom padding for safe area
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Close Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0095D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: const Color(0xFF0095D9),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final date = DateTime.parse(dateTimeString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateTimeString; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserTestDrivesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Rejected Test Drives',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
              onPressed: () => Navigator.pop(context, true), // Return true to indicate screen was visited
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 16),
                ),
                onPressed: provider.refresh,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.grey[200],
              ),
            ),
          ),
          body: provider.isLoadingForScreen('rejected')
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
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[800],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: provider.refresh,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0095D9),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : provider.rejectedTestDrives.isEmpty
                      ? _buildEmptyStateWidget(provider.lastApiMessage, provider.refresh)
                      : RefreshIndicator(
                          onRefresh: provider.refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: provider.rejectedTestDrives.length,
                            itemBuilder: (context, index) {
                              final testDrive = provider.rejectedTestDrives[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                                child: InkWell(
                                  onTap: () => _showTestDriveDetails(testDrive),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          testDrive.car?.name ?? 'Unknown',
                                                          style: const TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF1A1A1A),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                                                        ),
                                                        child: Text(
                                                          'REJECTED',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.red[700],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${testDrive.userName ?? 'Unknown'} • ${testDrive.date ?? 'Unknown'} • ${testDrive.time ?? 'Unknown'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.location_on,
                                                        size: 12,
                                                        color: Colors.grey[600],  
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Expanded(
                                                        child: Text(
                                                          '${testDrive.pickupCity ?? 'Unknown'}, ${testDrive.pickupPincode ?? 'Unknown'}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
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
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildInfoItem(
                                                'Date',
                                                testDrive.date ?? 'Unknown',
                                                Icons.calendar_today_outlined,
                                              ),
                                            ),
                                            Expanded(
                                              child: _buildInfoItem(
                                                'Time',
                                                testDrive.time ?? 'Unknown',
                                                Icons.access_time_rounded,
                                              ),
                                            ),
                                            Expanded(
                                              child: _buildInfoItem(
                                                'Location',
                                                testDrive.pickupCity ?? 'Unknown',
                                                Icons.location_on_outlined,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (testDrive.note?.isNotEmpty == true) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.note_outlined,
                                                  size: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    testDrive.note ?? ''    ,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (testDrive.rejectDescription != null && testDrive.rejectDescription!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.block_outlined,
                                                  size: 12,
                                                  color: Colors.red[600],
                                                ),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    testDrive.rejectDescription!,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.red[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        );
      },
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
              size: 12,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
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
    if ((imageUrl == null || imageUrl.isEmpty) && car.images != null && car.images!.isNotEmpty) {
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
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarImagesGallery(List<CarImage> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Car Images',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: index < images.length - 1 ? 8 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildGalleryImage(image.imagePath),
                ),
              );
            },
          ),
        ),
      ],
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
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateWidget(String? message, VoidCallback onRefresh) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No Rejected Test Drives',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'You don\'t have any rejected test drives at the moment',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
} 