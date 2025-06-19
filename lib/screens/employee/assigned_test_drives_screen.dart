import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'update_status_screen.dart';

class AssignedTestDrivesScreen extends StatefulWidget {
  const AssignedTestDrivesScreen({super.key});

  @override
  State<AssignedTestDrivesScreen> createState() => _AssignedTestDrivesScreenState();
}

class _AssignedTestDrivesScreenState extends State<AssignedTestDrivesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  // Mock data - in real app this would come from API
  final List<Map<String, dynamic>> _testDrives = [
    {
      'id': 'TD001',
      'customerName': 'Rahul Sharma',
      'customerPhone': '+91 98765 43210',
      'vehicleModel': 'Tata Nexon EV',
      'vehicleYear': '2024',
      'scheduledDate': '2024-01-15',
      'scheduledTime': '10:00 AM',
      'status': 'Scheduled',
      'location': 'Tata Motors Showroom, Andheri East',
      'notes': 'Customer interested in electric vehicles, looking for home charging options',
    },
    {
      'id': 'TD002',
      'customerName': 'Priya Patel',
      'customerPhone': '+91 98765 43211',
      'vehicleModel': 'Mahindra XUV700',
      'vehicleYear': '2024',
      'scheduledDate': '2024-01-15',
      'scheduledTime': '2:00 PM',
      'status': 'In Progress',
      'location': 'Mahindra Auto, Powai',
      'notes': 'Family looking for 7-seater SUV, interested in ADAS features',
    },
    {
      'id': 'TD003',
      'customerName': 'Amit Kumar',
      'customerPhone': '+91 98765 43212',
      'vehicleModel': 'Hyundai Creta',
      'vehicleYear': '2024',
      'scheduledDate': '2024-01-16',
      'scheduledTime': '11:30 AM',
      'status': 'Completed',
      'location': 'Hyundai Motors, Vikhroli',
      'notes': 'Young professional, interested in connected car features',
    },
    {
      'id': 'TD004',
      'customerName': 'Neha Singh',
      'customerPhone': '+91 98765 43213',
      'vehicleModel': 'Maruti Suzuki Brezza',
      'vehicleYear': '2024',
      'scheduledDate': '2024-01-16',
      'scheduledTime': '3:00 PM',
      'status': 'Scheduled',
      'location': 'Maruti Suzuki, Ghatkopar',
      'notes': 'First-time car buyer, budget-conscious, looking for fuel efficiency',
    },
    {
      'id': 'TD005',
      'customerName': 'Vikram Mehta',
      'customerPhone': '+91 98765 43214',
      'vehicleModel': 'Kia Seltos',
      'vehicleYear': '2024',
      'scheduledDate': '2024-01-17',
      'scheduledTime': '10:30 AM',
      'status': 'Scheduled',
      'location': 'Kia Motors, Bhandup',
      'notes': 'Tech-savvy customer, interested in premium features and design',
    },
    {
      'id': 'TD006',
      'customerName': 'Anjali Desai',
      'customerPhone': '+91 98765 43215',
      'vehicleModel': 'Honda City',
      'vehicleYear': '2024',
      'scheduledDate': '2024-01-17',
      'scheduledTime': '1:00 PM',
      'status': 'In Progress',
      'location': 'Honda Cars, Kandivali',
      'notes': 'Sedan enthusiast, looking for comfort and reliability',
    },
    {
      'id': 'TD007',
      'customerName': 'Rajesh Verma',
      'customerPhone': '+91 98765 43216',
      'vehicleModel': 'Tata Punch',
      'vehicleYear': '2024',
      'scheduledDate': '2024-01-18',
      'scheduledTime': '9:00 AM',
      'status': 'Completed',
      'location': 'Tata Motors Showroom, Thane',
      'notes': 'Compact SUV buyer, impressed with safety ratings',
    },
    {
      'id': 'TD008',
      'customerName': 'Sneha Reddy',
      'customerPhone': '+91 98765 43217',
      'vehicleModel': 'Mahindra Thar',
      'vehicleYear': '2024',
      'scheduledDate': '2024-01-18',
      'scheduledTime': '4:00 PM',
      'status': 'Cancelled',
      'location': 'Mahindra Auto, Navi Mumbai',
      'notes': 'Adventure enthusiast, cancelled due to long waiting period',
    },
    {
      'id': 'TD009',
      'customerName': 'Arjun Malhotra',
      'customerPhone': '+91 98765 43218',
      'vehicleModel': 'Hyundai Venue',
      'vehicleYear': '2024',
      'scheduledDate': '2024-01-19',
      'scheduledTime': '12:00 PM',
      'status': 'Scheduled',
      'location': 'Hyundai Motors, Borivali',
      'notes': 'Urban commuter, looking for compact SUV with good mileage',
    },
    {
      'id': 'TD010',
      'customerName': 'Pooja Gupta',
      'customerPhone': '+91 98765 43219',
      'vehicleModel': 'Maruti Suzuki Swift',
      'vehicleYear': '2024',
      'scheduledDate': '2024-01-19',
      'scheduledTime': '2:30 PM',
      'status': 'Scheduled',
      'location': 'Maruti Suzuki, Mulund',
      'notes': 'Hatchback buyer, interested in automatic transmission',
    },
  ];

  List<Map<String, dynamic>> get _filteredTestDrives {
    return _testDrives.where((testDrive) {
      final matchesSearch = testDrive['customerName'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          testDrive['vehicleModel'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          testDrive['id'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _selectedFilter == 'All' || testDrive['status'] == _selectedFilter;
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speech.stop();
    super.dispose();
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
          if (error.errorMsg.contains('no match')) {
            errorMessage = 'Try speaking more clearly or use longer words';
          } else if (error.errorMsg.contains('network')) {
            errorMessage = 'Network error. Please check your connection';
          } else if (error.errorMsg.contains('audio')) {
            errorMessage = 'Audio error. Please try again';
          } else {
            errorMessage = 'Speech recognition error: ${error.errorMsg}';
          }
          _showErrorSnackBar(errorMessage);
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
          await _speech.listen(
            onResult: (result) {
              setState(() {
                _searchQuery = result.recognizedWords;
                _searchController.text = _searchQuery;
              });
            },
            listenFor: const Duration(seconds: 60),
            pauseFor: const Duration(seconds: 5),
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
                          '${_filteredTestDrives.length} Test Drives',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Manage your assigned test drives',
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
            
            // Search and Filter Section
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
                                    : 'Tap to start voice search\nTip: Speak clearly and use complete words',
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
                        _buildFilterChip('In Progress', Icons.directions_car),
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
              child: _filteredTestDrives.isEmpty
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
                            'No test drives found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try adjusting your search or filters',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
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

  Widget _buildTestDriveCard(Map<String, dynamic> testDrive) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (testDrive['status']) {
      case 'Scheduled':
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.schedule;
        statusText = 'Scheduled';
        break;
      case 'In Progress':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.directions_car;
        statusText = 'In Progress';
        break;
      case 'Completed':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'Cancelled':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = testDrive['status'];
    }

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
                    testDrive['id'],
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
                              testDrive['customerName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              testDrive['customerPhone'],
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
                                testDrive['vehicleModel'],
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
                          testDrive['location'],
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
                  '${testDrive['scheduledDate']} at ${testDrive['scheduledTime']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            if (testDrive['notes'] != null && testDrive['notes'].isNotEmpty) ...[
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
                        testDrive['notes'],
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> testDrive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
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
            Expanded(
              child: Text(
                'Test Drive Details',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', testDrive['id']),
              _buildDetailRow('Customer', testDrive['customerName']),
              _buildDetailRow('Phone', testDrive['customerPhone']),
              _buildDetailRow('Vehicle', '${testDrive['vehicleModel']}'),
              _buildDetailRow('Date & Time', '${testDrive['scheduledDate']} at ${testDrive['scheduledTime']}'),
              _buildDetailRow('Status', testDrive['status']),
              _buildDetailRow('Location', testDrive['location']),
              if (testDrive['notes'] != null && testDrive['notes'].isNotEmpty)
                _buildDetailRow('Notes', testDrive['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF3080A5)),
            ),
          ),
        ],
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

  void _updateStatus(Map<String, dynamic> testDrive) {
    // Navigate to update status screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UpdateStatusScreen(),
      ),
    );
  }
} 