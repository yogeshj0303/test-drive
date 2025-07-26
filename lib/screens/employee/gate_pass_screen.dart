import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../models/test_drive_model.dart';
import '../../models/gate_pass_model.dart' as gate_pass;
import '../../models/employee_model.dart';
import '../../services/driver_api_service.dart';
import '../../services/employee_storage_service.dart';
import '../../services/api_config.dart';
import '../../background_location_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeGatePassScreen extends StatefulWidget {
  final AssignedTestDrive testDrive;
  const EmployeeGatePassScreen({super.key, required this.testDrive});

  @override
  State<EmployeeGatePassScreen> createState() => _EmployeeGatePassScreenState();
}

class _EmployeeGatePassScreenState extends State<EmployeeGatePassScreen> {
  final EmployeeApiService _apiService = EmployeeApiService();
  
  bool _isLoading = true;
  String? _errorMessage;
  gate_pass.GatePass? _gatePass;
  Employee? _currentEmployee;

  // Location tracking
  Timer? _locationTimer;
  bool _trackingStarted = false;
  bool _isCompleted = false; // Set to true when test drive is completed

  @override
  void initState() {
    super.initState();
    _loadGatePass();
    _startLocationTracking();
  }

  @override
  void dispose() {
    // Don't stop tracking when leaving screen - let background service continue
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    if (_trackingStarted) return;
    
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    if (permission == geo.LocationPermission.denied) {
      setState(() {
        _errorMessage = 'Location permission denied.';
      });
      return;
    }
    if (permission == geo.LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Location permission permanently denied.';
      });
      return;
    }
    
    // Show notification that location tracking is starting
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Starting location tracking...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    try {
      // Try to start background service first
      await initializeService(widget.testDrive.id, widget.testDrive.car?.id ?? 0);
      
      // Check if background service started successfully
      final isRunning = await isServiceRunning();
      
      if (isRunning) {
        // Background service is running, also start local timer for immediate feedback
        _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
          await _sendLocationUpdate();
        });
        
        _trackingStarted = true;
        
        // Send initial location update
        await _sendLocationUpdate();
        
        // Show success notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Background tracking active (continues when app is closed)'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Background service failed, fallback to local tracking only
        _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
          await _sendLocationUpdate();
        });
        _trackingStarted = true;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Local tracking only (background service unavailable)'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Failed to start background service: $e');
      // Fallback to local tracking only
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        await _sendLocationUpdate();
      });
      _trackingStarted = true;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Local tracking only (background service failed)'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sendLocationUpdate() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition();
      final testDriveId = widget.testDrive.id.toString();
      final carId = widget.testDrive.car?.id.toString() ?? '';
      final trackingId = 'track_001';
      
      print('📍 Sending location update: testDriveId=$testDriveId, carId=$carId, lat=${position.latitude}, lng=${position.longitude}');
      
      final response = await http.post(
        Uri.parse('https://varenyam.acttconnect.com/api/update-location'),
        body: {
          'testdrive_id': testDriveId,
          'car_id': carId,
          'car_latitude': position.latitude.toString(),
          'car_longitude': position.longitude.toString(),
          'tracking_id': trackingId,
        },
      );
      
      if (response.statusCode == 200) {
        print('✅ Location update sent successfully for test drive #$testDriveId');
      } else {
        print('❌ Failed to send location update: ${response.statusCode} - ${response.body}');
      }
      
      // Store locally
      final point = LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
      await EmployeeStorageService.addLocationPoint(widget.testDrive.id, point);
    } catch (e) {
      print('❌ Error sending location update: $e');
    }
  }

  void _stopLocationTracking() {
    if (_trackingStarted) {
      _locationTimer?.cancel();
      _locationTimer = null;
      _trackingStarted = false;
      
      // Stop background service
      stopService();
      
      // Show notification that location tracking has stopped
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏹️ Location tracking stopped'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _checkTrackingStatus() async {
    try {
      final isRunning = await isServiceRunning();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRunning 
              ? '✅ Background tracking is active' 
              : '❌ Background tracking is not running'),
            backgroundColor: isRunning ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error checking tracking status: $e');
    }
  }

  Future<void> _loadGatePass() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current employee data
      final employee = await EmployeeStorageService.getEmployeeData();
      if (employee == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Employee data not found. Please login again.';
        });
        return;
      }

      _currentEmployee = employee;

      // Fetch gate pass data
      final response = await _apiService.getGatePass(
        driverId: employee.id,
        testDriveId: widget.testDrive.id,
      );

      if (response.success && response.data != null && response.data!.data.isNotEmpty) {
        setState(() {
          _gatePass = response.data!.data.first;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message ?? 'No gate pass found for this test drive';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gate Pass',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3080A5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF3080A5)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Location tracking status indicator
          if (_trackingStarted)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Tracking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          // Check tracking status button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3080A5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, size: 16, color: Color(0xFF3080A5)),
            ),
            onPressed: _checkTrackingStatus,
            tooltip: 'Check tracking status',
          ),
          if (!_isLoading && _errorMessage == null)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3080A5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh, size: 16, color: Color(0xFF3080A5)),
              ),
              onPressed: _loadGatePass,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3080A5)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading gate pass...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? _buildErrorWidget()
                : _gatePass == null
                    ? _buildNoGatePassWidget()
                    : _buildGatePassContent(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Gate Pass',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadGatePass,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3080A5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGatePassWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.qr_code_2_outlined,
                size: 48,
                color: Colors.orange[400],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Gate Pass Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gate pass has not been generated for this test drive yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatePassContent() {
    final gatePass = _gatePass!;
    final testDrive = gatePass.textdriveDetails;
    final car = testDrive.car;
    final showroom = car.showroom;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Gate Pass Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Company Logo/Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3080A5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 32,
                    color: Color(0xFF3080A5),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'VARENYAM MOTORCAR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'TEST DRIVE OFFICIAL USE',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Gate Pass ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3080A5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'GP-${gatePass.id.toString().padLeft(6, '0')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF3080A5),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(gatePass.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getStatusColor(gatePass.status).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(gatePass.status),
                            size: 14,
                            color: _getStatusColor(gatePass.status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            gatePass.status.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: _getStatusColor(gatePass.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Customer Information
          _buildInfoSection(
            'Customer Information',
            Icons.person,
            [
              _buildInfoRow('Name', testDrive.userName),
              _buildInfoRow('Address', testDrive.pickupAddress),
              _buildInfoRow('Mobile', testDrive.userMobile),
              _buildInfoRow('Email', testDrive.userEmail),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Vehicle Information
          _buildInfoSection(
            'Vehicle Information',
            Icons.directions_car,
            [
              _buildInfoRow('Model', car.name),
              _buildInfoRow('Showroom', showroom.name),
              _buildInfoRow('Year', car.yearOfManufacture.toString()),
              _buildInfoRow('Color', car.color),
              _buildInfoRow('Fuel Type', car.fuelType),
              _buildInfoRow('Transmission', car.transmission),
              _buildInfoRow('Seating', '${car.seatingCapacity} seats'),
              _buildInfoRow('Body Type', car.bodyType),
              if (car.registrationNumber != null && car.registrationNumber!.isNotEmpty)
                _buildInfoRow('Registration', car.registrationNumber!),
              if (car.vin != null && car.vin!.isNotEmpty)
                _buildInfoRow('VIN', car.vin!),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Test Drive Details
          _buildInfoSection(
            'Test Drive Details',
            Icons.schedule,
            [
              _buildInfoRow('Test Drive ID', 'TD-${testDrive.id.toString().padLeft(6, '0')}'),
              _buildInfoRow('Date', testDrive.date),
              _buildInfoRow('Time', testDrive.time),
              _buildInfoRow('Status', testDrive.status.toUpperCase()),
              _buildInfoRow('Valid Date', gatePass.validDate),
            ],
          ),
          

          
          const SizedBox(height: 16),
          
          // Car Image
          if (car.mainImage.isNotEmpty)
            _buildInfoSection(
              'Vehicle Image',
              Icons.photo_library,
              [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    '${ApiConfig.baseUrl}/${car.mainImage}',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3080A5)),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Gate Pass Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                const Text(
                  'Gate Pass Generated',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${_formatDateTime(gatePass.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (gatePass.updatedAt != gatePass.createdAt)
                  Text(
                    'Updated: ${_formatDateTime(gatePass.updatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3080A5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF3080A5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    final displayValue = value?.isNotEmpty == true ? value! : 'Not provided';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: value?.isNotEmpty == true ? const Color(0xFF1E293B) : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return const Color(0xFF10B981);
      case 'expired':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return Icons.check_circle;
      case 'expired':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }
} 