import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/api_service.dart';
import '../../models/test_drive_model.dart';
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
import 'personal_info_screen.dart';

class RequestTestDriveScreen extends StatefulWidget {
  final String? showroomName;
  final List<String>? availableCars;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final String? pickupLocation;
  final int? carId;
  final int? showroomId;
  
  const RequestTestDriveScreen({
    super.key,
    this.showroomName,
    this.availableCars,
    this.selectedStartDate,
    this.selectedEndDate,
    this.pickupLocation,
    this.carId,
    this.showroomId,
  });

  @override
  State<RequestTestDriveScreen> createState() => _RequestTestDriveScreenState();
}

class _RequestTestDriveScreenState extends State<RequestTestDriveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _showroomController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _pickupCityController = TextEditingController();
  final _pickupPincodeController = TextEditingController();
  final _drivingLicenseController = TextEditingController();
  final _aadharNoController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedCar;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedDuration = '30 mins';
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;

  final List<String> _durationOptions = ['30 mins', '45 mins', '60 mins'];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.showroomName != null) {
      _showroomController.text = widget.showroomName!;
    }
    if (widget.availableCars != null && widget.availableCars!.isNotEmpty) {
      _selectedCar = widget.availableCars!.first;
    } else {
      _selectedCar = _carOptions.first;
    }
    
    // Use passed dates if available
    if (widget.selectedStartDate != null) {
      _selectedDate = widget.selectedStartDate;
    }
    
    // Set default time if not provided
    if (_selectedTime == null) {
      _selectedTime = TimeOfDay.now();
    }
    
    // Get current location and user data
    _getCurrentLocation();
    _loadUserData();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        _setDefaultLocation();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever
        _setDefaultLocation();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _pickupAddressController.text = '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}'.trim();
          _pickupCityController.text = place.locality ?? place.subAdministrativeArea ?? 'Unknown City';
          _pickupPincodeController.text = place.postalCode ?? '';
        });
      } else {
        _setDefaultLocation();
      }
    } catch (e) {
      // If there's any error, set default location
      _setDefaultLocation();
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _pickupAddressController.text = 'Current Location';
      _pickupCityController.text = 'Your City';
      _pickupPincodeController.text = '';
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = await StorageService().getUser();
      if (user != null) {
        // Load user profile to get updated information
        final profileResponse = await _apiService.getUserProfile(user.id);
        if (profileResponse.success && profileResponse.data != null) {
          final userProfile = profileResponse.data!;
          
          setState(() {
            // Populate driving license if available
            if (userProfile.drivingLicenseNo != null && userProfile.drivingLicenseNo!.isNotEmpty) {
              _drivingLicenseController.text = userProfile.drivingLicenseNo!;
            }
            
            // Populate Aadhar number if available
            if (userProfile.aadharNo != null && userProfile.aadharNo!.isNotEmpty) {
              _aadharNoController.text = userProfile.aadharNo!;
            }
          });
          

        }
      }
    } catch (e) {
      // Silently handle errors to avoid disrupting the UI
      print('Error loading user data: $e');
    }
  }



  List<String> get _carOptions {
    if (widget.availableCars != null && widget.availableCars!.isNotEmpty) {
      return widget.availableCars!;
    }
    // Default car options when no specific cars are provided
    return [
      'Tata Nexon EV',
      'Mahindra XUV700',
      'Hyundai Creta',
      'Maruti Suzuki Baleno',
      'Kia Seltos',
      'Honda City',
      'Toyota Innova',
      'MG Hector',
    ];
  }

  @override
  void dispose() {
    _showroomController.dispose();
    _pickupAddressController.dispose();
    _pickupCityController.dispose();
    _pickupPincodeController.dispose();
    _drivingLicenseController.dispose();
    _aadharNoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user data when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0095D9),
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0095D9),
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

  Future<void> _submitRequest() async {
    // Check if we have dates from CarDetailsScreen or user selection
    bool hasValidDates = widget.selectedStartDate != null || _selectedDate != null;
    
    if (_formKey.currentState!.validate() &&
        _selectedCar != null &&
        hasValidDates &&
        _selectedTime != null &&
        _drivingLicenseController.text.isNotEmpty &&
        _aadharNoController.text.isNotEmpty) {
      
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        // Get user ID from storage
        final user = await StorageService().getUser();
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Validate user has required information
        if (user.name.isEmpty || user.mobileNo.isEmpty || user.email.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User profile incomplete. Please update your profile first.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Get car ID (you might need to pass this from CarDetailsScreen)
        // For now, using a default value - you should get the actual car ID
        final carId = widget.carId ?? 3; // This should be passed from CarDetailsScreen
        
        // Format date and time
        final selectedDate = _selectedDate ?? widget.selectedStartDate!;
        final dateString = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
        
        // Create test drive request
        final testDriveRequest = TestDriveRequest(
          carId: carId,
          frontUserId: user.id,
          date: dateString,
          time: timeString,
          pickupAddress: _pickupAddressController.text,
          pickupCity: _pickupCityController.text,
          pickupPincode: _pickupPincodeController.text,
          drivingLicense: _drivingLicenseController.text,
          aadharNo: _aadharNoController.text,
          note: _noteController.text,
          status: 'pending',
          showroomId: widget.showroomId ?? 2, // This should be passed from CarDetailsScreen
          userName: user.name,
          userMobile: user.mobileNo,
          userEmail: user.email,
          userAdhar: user.aadharNo ?? _aadharNoController.text,
        );
        
        // Debug log the request
        print('Test Drive Request Data:');
        print('Car ID: $carId');
        print('User ID: ${user.id}');
        print('Date: $dateString');
        print('Time: $timeString');
        print('Showroom ID: ${widget.showroomId ?? 2}');
        print('User Name: ${user.name}');
        print('User Mobile: ${user.mobileNo}');
        print('User Email: ${user.email}');
        print('User Aadhar: ${user.aadharNo ?? _aadharNoController.text}');
        
        // Submit request
        final response = await _apiService.requestTestDrive(testDriveRequest);
        
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Test drive request submitted successfully'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context);
        } else {
          // Show error with retry option for server errors
          final isServerError = response.message.contains('maintenance') == true || 
                               response.message.contains('Server') == true;
          
          if (isServerError) {
            _showServerErrorDialog(response.message ?? 'Server error occurred');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message ?? 'Failed to submit test drive request'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _submitRequest(),
                ),
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      String errorMessage = 'Please fill in all required fields';
      if (!hasValidDates) {
        errorMessage = 'Please select a test drive date';
      } else if (_selectedTime == null) {
        errorMessage = 'Please select a test drive time';
      } else if (_drivingLicenseController.text.isEmpty) {
        errorMessage = 'Please enter your driving license number';
      } else if (_aadharNoController.text.isEmpty) {
        errorMessage = 'Please enter your Aadhar number';
      } else if (_pickupAddressController.text.isEmpty) {
        errorMessage = 'Please enter pickup address';
      } else if (_pickupCityController.text.isEmpty) {
        errorMessage = 'Please enter pickup city';
      } else if (_pickupPincodeController.text.isEmpty) {
        errorMessage = 'Please enter pickup pincode';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showServerErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Server Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitRequest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0095D9),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Enhanced gradient background
          Container(
            height: 100, // Reduced from 150
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0095D9),
                  Color(0xFF0077B6),
                  Color(0xFF005A8B),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Enhanced top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Request Test Drive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40), // Balance the layout
                      ],
                    ),
                  ),
                  const SizedBox(height: 8), // Reduced from 12
                  // Main form content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12), // Reduced from 16
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20), // Increased from 12
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Combined Car Details & Schedule Section
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0095D9).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: Color(0xFF0095D9),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Schedule Details',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Showroom field
                              TextFormField(
                                controller: _showroomController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Showroom',
                                  labelStyle: const TextStyle(fontSize: 14),
                                  hintText: 'Enter showroom name',
                                  hintStyle: const TextStyle(fontSize: 14),
                                  prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0095D9), size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF0095D9), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter showroom name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              // Two-column layout for date and time
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectDate(context),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Date',
                                          labelStyle: const TextStyle(fontSize: 14),
                                          prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF0095D9), size: 20),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFF0095D9), width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        child: Text(
                                          _selectedDate != null
                                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                              : 'Select date',
                                          style: TextStyle(
                                            color: _selectedDate != null
                                                ? const Color(0xFF1A1A1A)
                                                : Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectTime(context),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Time',
                                          labelStyle: const TextStyle(fontSize: 14),
                                          prefixIcon: const Icon(Icons.access_time_rounded, color: Color(0xFF0095D9), size: 20),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFF0095D9), width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        child: Text(
                                          _selectedTime != null
                                              ? _selectedTime!.format(context)
                                              : 'Select time',
                                          style: TextStyle(
                                            color: _selectedTime != null
                                                ? const Color(0xFF1A1A1A)
                                                : Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Duration Dropdown
                              DropdownButtonFormField<String>(
                                value: _selectedDuration,
                                decoration: InputDecoration(
                                  labelText: 'Duration',
                                  labelStyle: const TextStyle(fontSize: 14),
                                  prefixIcon: const Icon(Icons.timer_outlined, color: Color(0xFF0095D9), size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF0095D9), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: _durationOptions.map((String duration) {
                                  return DropdownMenuItem<String>(
                                    value: duration,
                                    child: Text(
                                      duration,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedDuration = newValue;
                                    });
                                  }
                                },
                                menuMaxHeight: 150,
                              ),
                              const SizedBox(height: 12),
                              // Personal Information Section
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0095D9).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF0095D9),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Pickup Address with location button
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _pickupAddressController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Pickup Address',
                                        labelStyle: const TextStyle(fontSize: 14),
                                        hintText: 'Enter pickup address',
                                        hintStyle: const TextStyle(fontSize: 14),
                                        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0095D9), size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFF0095D9), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter pickup address';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0095D9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: IconButton(
                                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                                      icon: _isLoadingLocation
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.my_location, color: Colors.white, size: 20),
                                      tooltip: 'Use Current Location',
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Two-column layout for city and pincode
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _pickupCityController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Pickup City',
                                        labelStyle: const TextStyle(fontSize: 14),
                                        hintText: 'Enter pickup city',
                                        hintStyle: const TextStyle(fontSize: 14),
                                        prefixIcon: const Icon(Icons.location_city_outlined, color: Color(0xFF0095D9), size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFF0095D9), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter pickup city';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _pickupPincodeController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Pickup Pincode',
                                        labelStyle: const TextStyle(fontSize: 14),
                                        hintText: 'Enter pickup pincode',
                                        hintStyle: const TextStyle(fontSize: 14),
                                        prefixIcon: const Icon(Icons.pin_drop_outlined, color: Color(0xFF0095D9), size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFF0095D9), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter pickup pincode';
                                        }
                                        if (value.length != 6) {
                                          return 'Pincode must be 6 digits';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Driving License field
                              TextFormField(
                                controller: _drivingLicenseController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Driving License',
                                  labelStyle: const TextStyle(fontSize: 14),
                                  hintText: _drivingLicenseController.text.isEmpty 
                                      ? 'Enter license number' 
                                      : 'License number',
                                  hintStyle: const TextStyle(fontSize: 14),
                                  prefixIcon: const Icon(Icons.card_membership_outlined, color: Color(0xFF0095D9), size: 20),
                                  suffixIcon: _drivingLicenseController.text.isNotEmpty
                                      ? Container(
                                          margin: const EdgeInsets.all(6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                                          ),
                                          child: const Text(
                                            '✓',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          margin: const EdgeInsets.all(6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                          ),
                                          child: const Text(
                                            '!',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF0095D9), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter driving license number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              
                              // Aadhar Number field
                              TextFormField(
                                controller: _aadharNoController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Aadhar Number',
                                  labelStyle: const TextStyle(fontSize: 14),
                                  hintText: _aadharNoController.text.isEmpty 
                                      ? 'Enter 12-digit Aadhar' 
                                      : 'Aadhar number',
                                  hintStyle: const TextStyle(fontSize: 14),
                                  prefixIcon: const Icon(Icons.credit_card_outlined, color: Color(0xFF0095D9), size: 20),
                                  suffixIcon: _aadharNoController.text.isNotEmpty
                                      ? Container(
                                          margin: const EdgeInsets.all(6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                                          ),
                                          child: const Text(
                                            '✓',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          margin: const EdgeInsets.all(6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                          ),
                                          child: const Text(
                                            '!',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF0095D9), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter Aadhar number';
                                  }
                                  if (value.length != 12) {
                                    return 'Aadhar number must be 12 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              
                              // Note field
                              TextFormField(
                                controller: _noteController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Additional Notes (Optional)',
                                  labelStyle: const TextStyle(fontSize: 14),
                                  hintText: 'Enter any additional notes',
                                  hintStyle: const TextStyle(fontSize: 14),
                                  prefixIcon: const Icon(Icons.note_outlined, color: Color(0xFF0095D9), size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF0095D9), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                maxLines: 2, // Reduced from 3
                              ),
                              const SizedBox(height: 12),
                              
                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0095D9),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 14
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8), // Reduced from 10
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSubmitting
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 10), // Reduced from 12
                                            Text(
                                              'Submitting...',
                                              style: TextStyle(
                                                fontSize: 14, // Reduced from 15
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          'Submit Request',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                                                    const SizedBox(height: 12), // Reduced from 16
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 