import 'package:flutter/material.dart';
import '../../models/test_drive_model.dart';
import '../../models/showroom_model.dart';

class RescheduledTestDrivesScreen extends StatefulWidget {
  const RescheduledTestDrivesScreen({super.key});

  @override
  State<RescheduledTestDrivesScreen> createState() => _RescheduledTestDrivesScreenState();
}

class _RescheduledTestDrivesScreenState extends State<RescheduledTestDrivesScreen> {
  List<TestDriveListResponse> _rescheduledTestDrives = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  Future<void> _loadDummyData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Dummy data for rescheduled test drives
    final dummyData = [
      TestDriveListResponse(
        id: 1,
        carId: 1,
        frontUserId: 1,
        date: '2024-01-25',
        time: '11:30 AM',
        pickupAddress: '123 Main Street, Apartment 4B',
        pickupCity: 'Mumbai',
        pickupPincode: '400001',
        note: 'Rescheduled due to personal emergency. New time confirmed.',
        car: TestDriveCar(
          id: 1,
          showroomId: 1,
          yearOfManufacture: 2024,
          seatingCapacity: 5,
          name: 'Honda City',
          modelNumber: '2024',
          mainImage: null,
        ),
        showroom: Showroom(
          id: 1,
          authId: 1,
          name: 'Honda Showroom - Andheri',
          address: 'Andheri West',
          city: 'Mumbai',
          state: 'Maharashtra',
          district: 'Mumbai',
          pincode: '400001',
          ratting: 4,
          createdAt: '2024-01-01',
          updatedAt: '2024-01-01',
        ),
      ),
      TestDriveListResponse(
        id: 2,
        carId: 2,
        frontUserId: 1,
        date: '2024-01-28',
        time: '3:00 PM',
        pickupAddress: '456 Park Avenue, Floor 2',
        pickupCity: 'Delhi',
        pickupPincode: '110001',
        note: 'Rescheduled due to weather conditions. Showroom confirmed new slot.',
        car: TestDriveCar(
          id: 2,
          showroomId: 2,
          yearOfManufacture: 2024,
          seatingCapacity: 5,
          name: 'Maruti Swift',
          modelNumber: '2024',
          mainImage: null,
        ),
        showroom: Showroom(
          id: 2,
          authId: 2,
          name: 'Maruti Suzuki - Connaught Place',
          address: 'Connaught Place',
          city: 'Delhi',
          state: 'Delhi',
          district: 'New Delhi',
          pincode: '110001',
          ratting: 4,
          createdAt: '2024-01-01',
          updatedAt: '2024-01-01',
        ),
      ),
      TestDriveListResponse(
        id: 3,
        carId: 3,
        frontUserId: 1,
        date: '2024-01-30',
        time: '10:00 AM',
        pickupAddress: '789 Lake Road, Villa 12',
        pickupCity: 'Bangalore',
        pickupPincode: '560001',
        note: 'Rescheduled due to vehicle availability. New time suits better.',
        car: TestDriveCar(
          id: 3,
          showroomId: 3,
          yearOfManufacture: 2024,
          seatingCapacity: 5,
          name: 'Hyundai i20',
          modelNumber: '2024',
          mainImage: null,
        ),
        showroom: Showroom(
          id: 3,
          authId: 3,
          name: 'Hyundai Motors - Koramangala',
          address: 'Koramangala',
          city: 'Bangalore',
          state: 'Karnataka',
          district: 'Bangalore',
          pincode: '560001',
          ratting: 4,
          createdAt: '2024-01-01',
          updatedAt: '2024-01-01',
        ),
      ),
      TestDriveListResponse(
        id: 4,
        carId: 4,
        frontUserId: 1,
        date: '2024-02-02',
        time: '2:00 PM',
        pickupAddress: '321 Garden Street, Flat 8C',
        pickupCity: 'Chennai',
        pickupPincode: '600001',
        note: 'Rescheduled due to showroom maintenance. New date confirmed.',
        car: TestDriveCar(
          id: 4,
          showroomId: 4,
          yearOfManufacture: 2024,
          seatingCapacity: 7,
          name: 'Toyota Innova',
          modelNumber: '2024',
          mainImage: null,
        ),
        showroom: Showroom(
          id: 4,
          authId: 4,
          name: 'Toyota Showroom - T Nagar',
          address: 'T Nagar',
          city: 'Chennai',
          state: 'Tamil Nadu',
          district: 'Chennai',
          pincode: '600001',
          ratting: 4,
          createdAt: '2024-01-01',
          updatedAt: '2024-01-01',
        ),
      ),
    ];

    setState(() {
      _rescheduledTestDrives = dummyData;
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    await _loadDummyData();
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Rescheduled Test Drives',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, size: 18),
            ),
            onPressed: _refreshData,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: _rescheduledTestDrives.isEmpty
                  ? _buildEmptyStateWidget()
                  : _buildTestDrivesList(),
            ),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading your rescheduled test drives...',
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

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Icon(
                Icons.schedule,
                color: Colors.orange.shade400,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Rescheduled Test Drives',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any rescheduled test drives at the moment.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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

  Widget _buildTestDrivesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _rescheduledTestDrives.length,
      itemBuilder: (context, index) {
        final request = _rescheduledTestDrives[index];
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Status Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.car?.name ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request.date ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request.time ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${request.pickupCity ?? 'Unknown'}, ${request.pickupPincode ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 13,
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
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        'Rescheduled',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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
        height: MediaQuery.of(context).size.height * 0.75,
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
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: Colors.orange.shade600,
                      size: 24,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            'Rescheduled',
                            style: TextStyle(
                              color: Colors.orange.shade700,
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
                        _buildDetailRow('Status', 'Rescheduled'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Pickup Details',
                      [
                        _buildDetailRow('Address', request.pickupAddress ?? 'Unknown'),
                        _buildDetailRow('City', request.pickupCity ?? 'Unknown'),
                        _buildDetailRow('Pincode', request.pickupPincode ?? 'Unknown'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Showroom Information',
                      [
                        _buildDetailRow('Name', request.showroom?.name ?? 'Unknown'),
                        _buildDetailRow('Location', '${request.showroom?.city ?? 'Unknown'}, ${request.showroom?.state ?? 'Unknown'}'),
                        _buildDetailRow('Rating', '${request.showroom?.ratting ?? 'N/A'} ⭐'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (request.note?.isNotEmpty == true)
                      _buildDetailSection(
                        'Rescheduling Notes',
                        [
                          _buildDetailRow('Note', request.note ?? ''),
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
        // Contact Showroom Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: () => _showContactDialog(request),
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Contact Showroom'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: BorderSide(color: Colors.blue.shade400),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        // Reschedule Again Button
        Container(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showRescheduleDialog(request),
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Reschedule Again'),
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
    );
  }

  void _showContactDialog(TestDriveListResponse request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.phone,
              color: Colors.blue.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Contact Showroom',
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
              'Showroom: ${request.showroom?.name ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactOption('Call Showroom', '+91 98765 43210', Icons.call, Colors.green),
            const SizedBox(height: 12),
            _buildContactOption('WhatsApp', '+91 98765 43210', Icons.message, Colors.green),
            const SizedBox(height: 12),
            _buildContactOption('Email', 'info@showroom.com', Icons.email, Colors.blue),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(String title, String contact, IconData icon, Color color) {
    return InkWell(
      onTap: () => _handleContactAction(title, contact),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    contact,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showRescheduleDialog(TestDriveListResponse request) {
    final TextEditingController reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                'Select new date and time for ${request.car?.name ?? 'Unknown'}:',
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
              const SizedBox(height: 12),
              // Time Selection
              InkWell(
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
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
                        Icons.access_time,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Time: ${selectedTime.format(context)}',
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
              Text(
                'Reason for rescheduling (optional):',
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
                  hintText: 'Enter reason for rescheduling...',
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
                    borderSide: BorderSide(color: Colors.orange.shade400),
                  ),
                  contentPadding: const EdgeInsets.all(12),
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
                _rescheduleTestDrive(request, selectedDate, selectedTime, reasonController.text.trim());
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

  void _handleContactAction(String action, String contact) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              action == 'Call Showroom' ? Icons.call : 
              action == 'WhatsApp' ? Icons.message : Icons.email,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Opening $action...'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _rescheduleTestDrive(TestDriveListResponse request, DateTime newDate, TimeOfDay newTime, String reason) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Close loading dialog
      Navigator.pop(context);

      // Close detail modal
      Navigator.pop(context);
      
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
              const Text('Test drive rescheduled successfully'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      // Refresh the list
      _loadDummyData();
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
              const Text('Failed to reschedule test drive'),
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
} 