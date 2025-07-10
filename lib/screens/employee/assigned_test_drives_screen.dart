import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;               
import 'package:varenyam/screens/Employee/gate_pass_screen.dart';
import 'package:varenyam/screens/Employee/update_status_screen.dart';
import '../../services/driver_api_service.dart';
import '../../services/employee_storage_service.dart';
import '../../services/api_config.dart';
import '../../models/test_drive_model.dart';

class AssignedTestDrivesScreen extends StatefulWidget {
  const AssignedTestDrivesScreen({super.key});

  @override
  State<AssignedTestDrivesScreen> createState() => AssignedTestDrivesScreenState();
}

class AssignedTestDrivesScreenState extends State<AssignedTestDrivesScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final EmployeeApiService _apiService = EmployeeApiService();
  
  bool _isListening = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isInitialized = false;
  String? _errorMessage;
  
  List<AssignedTestDrive> _testDrives = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
    _loadAssignedTestDrives();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app becomes visible
    if (state == AppLifecycleState.resumed) {
      _loadAssignedTestDrives();
    }
  }

  Future<void> _loadAssignedTestDrives() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Get employee data to get the driver ID
      final employee = await EmployeeStorageService.getEmployeeData();
      if (employee == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Employee data not found. Please login again.';
        });
        return;
      }

      final response = await _apiService.getAssignedTestDrives(employee.id);
      
      if (response.success && response.data != null) {
        setState(() {
          _testDrives = response.data!.data;
          _isLoading = false;
          _errorMessage = null;
          _isInitialized = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message ?? 'Failed to load assigned test drives';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadAssignedTestDrives();
    setState(() {
      _isRefreshing = false;
    });
  }

  // Method to be called when screen becomes visible from bottom navigation
  void onScreenVisible() {
    // Only refresh if already initialized and not currently loading
    if (_isInitialized && !_isLoading && _errorMessage == null) {
      _loadAssignedTestDrives();
    }
  }

  Future<void> _initSpeech() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status.isDenied) {
        _showErrorSnackBar('Microphone permission is required for voice search');
        return;
      }

      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          } else if (status == 'notListening') {
            setState(() => _isListening = false);
          } else if (status == 'listening') {
            setState(() => _isListening = true);
          }
        },
        onError: (error) {
          // Handle specific error cases more gracefully
          String errorMessage = 'Speech recognition error';
          String helpfulTip = '';
          
          if (error.errorMsg.contains('no match') || error.errorMsg.contains('error_no_match')) {
            errorMessage = 'No speech detected or unclear pronunciation';
            helpfulTip = '💡 Tip: Try saying complete words like "John" instead of "J", or "BMW" instead of "B"';
          } else if (error.errorMsg.contains('network')) {
            errorMessage = 'Network error. Please check your connection';
            helpfulTip = '💡 Tip: Ensure you have a stable internet connection';
          } else if (error.errorMsg.contains('audio')) {
            errorMessage = 'Audio error. Please try again';
            helpfulTip = '💡 Tip: Check your microphone and try speaking louder';
          } else if (error.errorMsg.contains('permission')) {
            errorMessage = 'Microphone permission denied';
            helpfulTip = '💡 Tip: Enable microphone access in app settings';
          } else {
            errorMessage = 'Speech recognition error: ${error.errorMsg}';
            helpfulTip = '💡 Tip: Try speaking clearly in a quiet environment';
          }
          
          _showErrorSnackBar('$errorMessage\n$helpfulTip');
          setState(() => _isListening = false);
        },
      );

      if (!available) {
        _showErrorSnackBar('Speech recognition is not available on this device');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to initialize speech recognition');
    }
  }

  List<AssignedTestDrive> get _filteredTestDrives {
    return _testDrives.where((testDrive) {
      final matchesSearch = (testDrive.userName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (testDrive.car?.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          testDrive.id.toString().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _selectedFilter == 'All' || 
          _getStatusDisplayName(testDrive.status ?? '') == _selectedFilter;
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  String _getStatusDisplayName(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Scheduled';
      case 'in_progress':
      case 'in progress':
        return 'Scheduled'; // Treat in_progress as scheduled since we removed the option
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

  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF3B82F6);
      case 'in_progress':
      case 'in progress':
        return const Color(0xFF3B82F6); // Use same color as approved/scheduled
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFEF4444);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null || status.isEmpty) return Icons.help;
    
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.schedule;
      case 'in_progress':
      case 'in progress':
        return Icons.schedule; // Use same icon as approved/scheduled
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel;
      case 'rejected':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Assigned Test Drives',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              // Header Section with Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3080A5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: Color(0xFF3080A5),
                            size: 20,
                          ),
                          if (_isRefreshing)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF3080A5),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(1.5),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3080A5)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoading 
                                ? 'Loading...' 
                                : '${_filteredTestDrives.length} Test Drives',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            _isLoading 
                                ? 'Fetching your assigned test drives' 
                                : _isRefreshing
                                    ? 'Refreshing data...'
                                    : 'Manage your assigned test drives',
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
              
              // Error Message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.red[700], size: 20),
                        onPressed: _loadAssignedTestDrives,
                        tooltip: 'Retry',
                      ),
                    ],
                  ),
                ),
              
              // Search and Filter Section
              if (!_isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.none,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search test drives...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                            suffixIcon: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isListening 
                                    ? const Color(0xFF3080A5).withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  IconButton(
                                    icon: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(
                                        _isListening ? Icons.mic : Icons.mic_none_rounded,
                                        key: ValueKey<bool>(_isListening),
                                        color: _isListening ? const Color(0xFF3080A5) : Colors.grey[400],
                                        size: 22,
                                      ),
                                    ),
                                    onPressed: _startListening,
                                    tooltip: _isListening 
                                        ? 'Stop listening' 
                                        : 'Tap to start voice search\n💡 Tip: Say "John Smith" instead of "J"\n💡 Tip: Say "BMW X5" instead of "B"',
                                  ),
                                  if (_isListening)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filter Chips
                      SingleChildScrollView(
                        clipBehavior: Clip.none,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', Icons.list_alt),
                            _buildFilterChip('Scheduled', Icons.schedule),
                            _buildFilterChip('Completed', Icons.check_circle),
                            _buildFilterChip('Cancelled', Icons.cancel),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Test Drives List
              Expanded(
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
                              'Loading assigned test drives...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredTestDrives.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.none,
                                  child: Icon(
                                    Icons.directions_car_outlined,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage != null 
                                      ? 'Failed to load test drives'
                                      : 'No test drives found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _errorMessage != null
                                      ? 'Please check your connection and try again'
                                      : 'Try adjusting your search or filters',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _loadAssignedTestDrives,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3080A5),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredTestDrives.length,
                            itemBuilder: (context, index) {
                              final testDrive = _filteredTestDrives[index];
                              return _buildTestDriveCard(testDrive);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        clipBehavior: Clip.none,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF3080A5),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF3080A5),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF3080A5),
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3080A5) : Colors.grey[300]!,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildTestDriveCard(AssignedTestDrive testDrive) {
    Color statusColor = _getStatusColor(testDrive.status);
    IconData statusIcon = _getStatusIcon(testDrive.status);
    String statusText = _getStatusDisplayName(testDrive.status);
    
    bool isCompleted = _getStatusDisplayName(testDrive.status) == 'Completed';
    bool isCancelled = _getStatusDisplayName(testDrive.status) == 'Cancelled';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3080A5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    testDrive.id.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF3080A5),
                    ),
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
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Customer and Vehicle Info Row
            Row(
              children: [
                // Customer Info
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3080A5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF3080A5),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testDrive.userName ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              testDrive.userMobile ?? 'No phone',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                                
                // Vehicle Info
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.directions_car,
                              color: const Color(0xFF3080A5),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                testDrive.car?.name ?? 'Unknown Car',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          testDrive.car?.showroom?.name ?? 'Unknown Showroom',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date and Time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '${testDrive.date ?? 'No date'} at ${testDrive.time ?? 'No time'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            if (testDrive.note?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 12,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        testDrive.note ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewDetails(testDrive),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3080A5),
                          side: const BorderSide(color: Color(0xFF3080A5)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isCompleted && !isCancelled)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(testDrive),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Update Status', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3080A5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    if (isCompleted || isCancelled)
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isCompleted ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            isCompleted ? 'Completed' : 'Cancelled',
                            style: TextStyle(
                              color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _viewGatePass(testDrive),
                      icon: const Icon(Icons.qr_code, size: 16),
                      label: const Text('View Gate Pass', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewDetails(AssignedTestDrive testDrive) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
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
                        const Text(
                          'Test Drive Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'ID: ${testDrive.id}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3080A5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF3080A5),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Customer Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Customer Details Grid
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCompactDetailRow('Name', testDrive.userName ?? 'Unknown', Icons.person_outline),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Phone', testDrive.userMobile ?? 'No phone', Icons.phone),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCompactDetailRow('Email', testDrive.userEmail ?? 'No email', Icons.email),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Aadhar', testDrive.userAdhar ?? 'No aadhar', Icons.credit_card),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Vehicle Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
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
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Vehicle Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Vehicle Details Grid
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCompactDetailRow('Model', testDrive.car?.name ?? 'Unknown', Icons.car_rental),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Showroom', testDrive.car?.showroom?.name ?? 'Unknown', Icons.store),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Year', testDrive.car?.yearOfManufacture.toString() ?? 'Unknown', Icons.calendar_today),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Color', testDrive.car?.color ?? 'Unknown', Icons.palette),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCompactDetailRow('Fuel Type', testDrive.car?.fuelType ?? 'Unknown', Icons.local_gas_station),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Transmission', testDrive.car?.transmission ?? 'Unknown', Icons.settings),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Seating', '${testDrive.car?.seatingCapacity ?? 0} seats', Icons.airline_seat_recline_normal),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Body Type', testDrive.car?.bodyType ?? 'Unknown', Icons.style),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Car Images Section
                    if (testDrive.car?.mainImage != null || (testDrive.car?.images != null && testDrive.car!.images!.isNotEmpty))
                      _buildDetailSection(
                        'Car Images',
                        Icons.photo_library,
                        [
                          // Main Image
                          if (testDrive.car?.mainImage != null) ...[
                            Container(
                              width: double.infinity,
                              height: 200,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                '${ApiConfig.baseUrl}/${testDrive.car!.mainImage!}',
                                fit: BoxFit.fill,
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
                                        size: 40,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          
                          // Additional Images
                          if (testDrive.car?.images != null && testDrive.car!.images!.isNotEmpty)
                            Container(
                              height: 120,
                              child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: testDrive.car!.images!.length,
                              itemBuilder: (context, index) {
                                final image = testDrive.car!.images![index];
                                final imageUrl = image.imagePath != null 
                                    ? '${ApiConfig.baseUrl}/${image.imagePath!}'
                                    : null;
                                
                                return Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: imageUrl != null
                                                                             ? Image.network(
                                           imageUrl,
                                           fit: BoxFit.fill,
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
                                                  size: 40,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Pickup Information Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3080A5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF3080A5),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Pickup Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Pickup Details
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCompactDetailRow('Address', testDrive.pickupAddress ?? 'No address', Icons.home),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactDetailRow('City', testDrive.pickupCity ?? 'No city', Icons.location_city),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildCompactDetailRow('Pincode', testDrive.pickupPincode ?? 'No pincode', Icons.pin_drop),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // License & Aadhar Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3080A5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.credit_card,
                                  color: Color(0xFF3080A5),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'License & Aadhar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // License & Aadhar Details
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactDetailRow('Driving License', testDrive.drivingLicense ?? 'No license', Icons.drive_eta),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildCompactDetailRow('Aadhar Number', testDrive.aadharNo ?? 'No aadhar', Icons.verified_user),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Test Drive Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3080A5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.schedule,
                                  color: Color(0xFF3080A5),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Test Drive Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Test Drive Details Grid
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCompactDetailRow('Date', testDrive.date ?? 'No date', Icons.calendar_today),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Time', testDrive.time ?? 'No time', Icons.access_time),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Status', _getStatusDisplayName(testDrive.status), Icons.info_outline),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCompactDetailRow('Driver ID', testDrive.driverId ?? 'Not assigned', Icons.person_pin),
                                    const SizedBox(height: 8),
                                    _buildCompactDetailRow('Update Date', testDrive.driverUpdateDate ?? 'Not updated', Icons.update),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    if (testDrive.note?.isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      
                      // Notes Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3080A5).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.note,
                                    color: Color(0xFF3080A5),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Notes Content
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                              ),
                              child: Text(
                                testDrive.note ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF92400E),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Bottom padding for safe area
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF3080A5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: const Color(0xFF3080A5),
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
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF3080A5),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  void _updateStatus(AssignedTestDrive testDrive) {
    // Navigate to update status screen with test drive data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateStatusScreen(selectedTestDrive: testDrive),
      ),
    ).then((_) {
      // Refresh data when returning from update status screen
      _loadAssignedTestDrives();
    });
  }

  void _viewGatePass(AssignedTestDrive testDrive) {
    // Navigate to gate pass screen with test drive data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeGatePassScreen(testDrive: testDrive),
      ),
    );
  }

  Future<void> _startListening() async {
    try {
      // Check microphone permission again before starting
      final status = await Permission.microphone.status;
      if (status.isDenied) {
        _showErrorSnackBar('Microphone permission is required for voice search');
        return;
      }

      if (!_isListening) {
        final available = await _speech.initialize();
        if (available) {
          setState(() => _isListening = true);
          
          // Show helpful tip when starting
          _showInfoSnackBar('🎤 Speak now! Try saying complete words like "John Smith" or "BMW X5"');
          
          await _speech.listen(
            onResult: (result) {
              final recognizedText = result.recognizedWords.trim();
              
              // Only update if we have meaningful text (more than just whitespace)
              if (recognizedText.isNotEmpty) {
                setState(() {
                  _searchQuery = recognizedText;
                  _searchController.text = _searchQuery;
                });
                
                // Provide feedback for very short inputs
                if (recognizedText.length <= 2) {
                  _showInfoSnackBar('💡 Tip: Try saying the full name or word for better recognition');
                }
              }
            },
            listenFor: const Duration(seconds: 60),
            pauseFor: const Duration(seconds: 3), // Reduced pause time for better responsiveness
            partialResults: true,
            localeId: 'en_US',
            cancelOnError: false,
            listenMode: stt.ListenMode.dictation,
          );
        } else {
          _showErrorSnackBar('Speech recognition is not available');
        }
      } else {
        setState(() => _isListening = false);
        _speech.stop();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start speech recognition: ${e.toString()}');
      setState(() => _isListening = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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