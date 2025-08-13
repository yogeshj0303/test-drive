import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../models/test_drive_model.dart';
import '../../services/storage_service.dart';
import '../../models/car_model.dart';

class RequestTestDriveScreen extends StatefulWidget {
  final String? showroomName;
  final List<Car>? availableCars;
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
  final _openingKmController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userMobileController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();

  String? _selectedCar;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedDuration = '30 mins';
  bool _isSubmitting = false;
  Map<String, File?> _selectedImages = {
    'image1': null, // car_front_img
    'image2': null, // right_side_img
    'image3': null, // back_car_img
    'image4': null, // left_side_img
    'image5': null, // upper_view
  };
  final ImagePicker _picker = ImagePicker();

  final List<String> _durationOptions = ['30 mins', '45 mins', '60 mins'];
  final ApiService _apiService = ApiService();

  List<Car> _cars = [];

  @override
  void initState() {
    super.initState();
    print('RequestTestDriveScreen initState - carId: ${widget.carId}, showroomId: ${widget.showroomId}');
    print('Available cars: ${widget.availableCars?.length ?? 0}');
    
    if (widget.showroomName != null) {
      _showroomController.text = widget.showroomName!;
    }
    if (widget.availableCars != null && widget.availableCars!.isNotEmpty) {
      _cars = widget.availableCars!;
      _selectedCar = _cars.first.name;
      print('Using available cars, selected: $_selectedCar');
      _setLastClosingKmForSelectedCar(_selectedCar);
    } else if (widget.showroomId != null) {
      print('Fetching cars by showroom ID: ${widget.showroomId}');
      _fetchCarsByShowroom(widget.showroomId!);
    } else {
      _selectedCar = _carOptions.first;
      print('Using default car options, selected: $_selectedCar');
    }

    // Use passed dates if available
    if (widget.selectedStartDate != null) {
      _selectedDate = widget.selectedStartDate;
    }

    // Set default time if not provided
    if (_selectedTime == null) {
      _selectedTime = TimeOfDay.now();
    }

    // Get current location
    _getCurrentLocation();
    // Do not auto-fill user info fields
    // _loadUserData();
    // _initializeUserFields();
  }

  // Remove _initializeUserFields and its call
  // void _initializeUserFields() async {
  //   final user = await StorageService().getUser();
  //   if (user != null) {
  //     _userNameController.text = user.name ?? '';
  //     _userMobileController.text = user.mobileNo ?? '';
  //     _userEmailController.text = user.email ?? '';
  //   }
  // }

  Future<void> _getCurrentLocation() async {
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
          _pickupAddressController.text =
              '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}'
                  .trim();
          _pickupCityController.text =
              place.locality ?? place.subAdministrativeArea ?? 'Unknown City';
          _pickupPincodeController.text = place.postalCode ?? '';
        });
      } else {
        _setDefaultLocation();
      }
    } catch (e) {
      // If there's any error, set default location
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _pickupAddressController.text = 'Current Location';
      _pickupCityController.text = 'Your City';
      _pickupPincodeController.text = '';
    });
  }

  // Remove Aadhar auto-fill from _loadUserData
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
            if (userProfile.drivingLicenseNo != null &&
                userProfile.drivingLicenseNo!.isNotEmpty) {
              _drivingLicenseController.text = userProfile.drivingLicenseNo!;
            }
            // Do not auto-fill Aadhar
            // if (userProfile.aadharNo != null && userProfile.aadharNo!.isNotEmpty) {
            //   _aadharNoController.text = userProfile.aadharNo!;
            // }
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
      return widget.availableCars!.map((car) => car.name).toList();
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
    _openingKmController.dispose();
    _userNameController.dispose();
    _userMobileController.dispose();
    _userEmailController.dispose();
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
    bool hasValidDates =
        widget.selectedStartDate != null || _selectedDate != null;

    if (_formKey.currentState!.validate() &&
        _selectedCar != null &&
        hasValidDates &&
        _selectedTime != null &&
        _drivingLicenseController.text.isNotEmpty &&
        _selectedImages['image1'] != null &&
        _selectedImages['image2'] != null &&
        _selectedImages['image3'] != null &&
        _selectedImages['image4'] != null &&
        _selectedImages['image5'] != null) {
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
              content: Text(
                  'User profile incomplete. Please update your profile first.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Get car ID (you might need to pass this from CarDetailsScreen)
        // For now, using a default value - you should get the actual car ID
        final carId =
            widget.carId ?? 3; // This should be passed from CarDetailsScreen

        // Format date and time
        final selectedDate = _selectedDate ?? widget.selectedStartDate!;
        final dateString =
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        final timeString =
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

        // Get last closing KM value
        final lastClosingKm = int.tryParse(_openingKmController.text) ?? 0;

        // Create test drive request with images in correct order
        final orderedImages = [
          _selectedImages['image1'], // car_front_img
          _selectedImages['image2'], // right_side_img
          _selectedImages['image3'], // back_car_img
          _selectedImages['image4'], // left_side_img
          _selectedImages['image5'], // upper_view
        ].where((file) => file != null).cast<File>().toList();

        final testDriveRequest = TestDriveRequest(
          carId: carId,
          frontUserId: user.id,
          date: dateString,
          time: timeString,
          pickupAddress: _pickupAddressController.text,
          pickupCity: _pickupCityController.text,
          pickupPincode: _pickupPincodeController.text,
          drivingLicense: _drivingLicenseController.text,
          aadharNo: user.aadharNo ?? " ",
          note: _noteController.text,
          status: 'pending',
          showroomId: widget.showroomId ??
              2, // This should be passed from CarDetailsScreen
          userName: _userNameController.text,
          userMobile: _userMobileController.text,
          userEmail: _userEmailController.text,
          userAdhar: _aadharNoController.text,
          openingKm: lastClosingKm,
          carImages: orderedImages,
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
        print('Last Closing KM: $lastClosingKm');
        print('Number of Images: ${orderedImages.length}');
        print(
            'Image 1: ${_selectedImages['image1'] != null ? 'Uploaded' : 'Missing'}');
        print(
            'Image 2: ${_selectedImages['image2'] != null ? 'Uploaded' : 'Missing'}');
        print(
            'Image 3: ${_selectedImages['image3'] != null ? 'Uploaded' : 'Missing'}');
        print(
            'Image 4: ${_selectedImages['image4'] != null ? 'Uploaded' : 'Missing'}');
        print(
            'Image 5: ${_selectedImages['image5'] != null ? 'Uploaded' : 'Missing'}');

        // Submit request
        final response = await _apiService.requestTestDrive(testDriveRequest);

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context);
        } else {
          // Show error with retry option for server errors
          final isServerError =
              response.message.contains('maintenance') == true ||
                  response.message.contains('Server') == true;

          if (isServerError) {
            _showServerErrorDialog(response.message);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
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
      } else if (_pickupAddressController.text.isEmpty) {
        errorMessage = 'Please enter pickup address';
      } else if (_pickupCityController.text.isEmpty) {
        errorMessage = 'Please enter pickup city';
      } else if (_pickupPincodeController.text.isEmpty) {
        errorMessage = 'Please enter pickup pincode';
      } else if (_selectedImages['image1'] == null) {
        errorMessage = 'Please upload car image 1';
      } else if (_selectedImages['image2'] == null) {
        errorMessage = 'Please upload car image 2';
      } else if (_selectedImages['image3'] == null) {
        errorMessage = 'Please upload car image 3';
      } else if (_selectedImages['image4'] == null) {
        errorMessage = 'Please upload car image 4';
      } else if (_selectedImages['image5'] == null) {
        errorMessage = 'Please upload car image 5';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source, String position) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages[position] = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(String position) {
    setState(() {
      _selectedImages[position] = null;
    });
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

  Future<void> _fetchCarsByShowroom(int showroomId) async {
    final response = await _apiService.getCarsByShowroom(showroomId);
    if (response.success && response.data != null) {
      setState(() {
        _cars = response.data!;
        if (_cars.isNotEmpty) {
          // Try to find the specific car by ID if provided
          if (widget.carId != null) {
            final specificCar = _cars.firstWhere(
              (c) => c.id == widget.carId,
              orElse: () => _cars.first,
            );
            _selectedCar = specificCar.name;
            print('Selected specific car: ${specificCar.name} with last closing KM: ${specificCar.lastClosingKm}');
          } else {
            _selectedCar = _cars.first.name;
          }
          _setLastClosingKmForSelectedCar(_selectedCar);
        }
      });
    }
  }

  void _setLastClosingKmForSelectedCar(String? carName) {
    if (carName == null || _cars.isEmpty) return;
    final car = _cars.firstWhere(
      (c) => c.name == carName,
      orElse: () => _cars.first,
    );
    print('Setting last closing KM for car: ${car.name}, ID: ${car.id}, lastClosingKm: ${car.lastClosingKm}');
    if (car.lastClosingKm != null && car.lastClosingKm!.isNotEmpty) {
      _openingKmController.text = car.lastClosingKm!;
      print('Set opening KM controller to: ${car.lastClosingKm}');
    } else {
      _openingKmController.text = '';
      print('No last closing KM available for this car');
    }
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4), // Reduced vertical padding
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 16),
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
                        borderRadius:
                            BorderRadius.circular(12), // Reduced from 16
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
                                      color: const Color(0xFF0095D9)
                                          .withOpacity(0.1),
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
                                  prefixIcon: const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFF0095D9),
                                      size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF0095D9), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
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
                                          labelStyle:
                                              const TextStyle(fontSize: 14),
                                          prefixIcon: const Icon(
                                              Icons.calendar_today_outlined,
                                              color: Color(0xFF0095D9),
                                              size: 20),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                                color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: Color(0xFF0095D9),
                                                width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
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
                                          labelStyle:
                                              const TextStyle(fontSize: 14),
                                          prefixIcon: const Icon(
                                              Icons.access_time_rounded,
                                              color: Color(0xFF0095D9),
                                              size: 20),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                                color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: Color(0xFF0095D9),
                                                width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
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
                                  prefixIcon: const Icon(Icons.timer_outlined,
                                      color: Color(0xFF0095D9), size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF0095D9), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
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
                              // Location Information Section
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0095D9)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF0095D9),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Location Information',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _pickupAddressController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Pickup Address',
                                        labelStyle:
                                            const TextStyle(fontSize: 14),
                                        hintText: _pickupAddressController
                                                .text.isEmpty
                                            ? 'Enter pickup address'
                                            : 'Pickup Address',
                                        hintStyle:
                                            const TextStyle(fontSize: 14),
                                        prefixIcon: const Icon(
                                            Icons.home_outlined,
                                            color: Color(0xFF0095D9),
                                            size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF0095D9),
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                      ),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? 'Please enter pickup address'
                                              : null,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _pickupCityController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Pickup City',
                                        labelStyle:
                                            const TextStyle(fontSize: 14),
                                        hintText:
                                            _pickupCityController.text.isEmpty
                                                ? 'Enter pickup city'
                                                : 'Pickup City',
                                        hintStyle:
                                            const TextStyle(fontSize: 14),
                                        prefixIcon: const Icon(
                                            Icons.location_city_outlined,
                                            color: Color(0xFF0095D9),
                                            size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF0095D9),
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                      ),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? 'Please enter pickup city'
                                              : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // User Information Section Heading (matching other headings)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0095D9)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF0095D9),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'User Information',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _userNameController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Name',
                                        labelStyle:
                                            const TextStyle(fontSize: 14),
                                        hintText:
                                            _userNameController.text.isEmpty
                                                ? 'Enter your name'
                                                : 'Name',
                                        hintStyle:
                                            const TextStyle(fontSize: 14),
                                        prefixIcon: const Icon(
                                            Icons.person_outline,
                                            color: Color(0xFF0095D9),
                                            size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF0095D9),
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        if (!RegExp(r'^[a-zA-Z]{3,}$')
                                            .hasMatch(value.trim())) {
                                          return 'Name should contain only letters and be at least 3 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _userMobileController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Mobile',
                                        labelStyle:
                                            const TextStyle(fontSize: 14),
                                        hintText:
                                            _userMobileController.text.isEmpty
                                                ? 'Enter your mobile number'
                                                : 'Mobile',
                                        hintStyle:
                                            const TextStyle(fontSize: 14),
                                        prefixIcon: const Icon(
                                            Icons.phone_outlined,
                                            color: Color(0xFF0095D9),
                                            size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF0095D9),
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your mobile number';
                                        }
                                        if (!RegExp(r'^[0-9]{10}$')
                                            .hasMatch(value.trim())) {
                                          return 'Enter a valid 10-digit mobile number';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        if (value.length == 10) {
                                          FocusScope.of(context).unfocus();
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _userEmailController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle:
                                            const TextStyle(fontSize: 14),
                                        hintText:
                                            _userEmailController.text.isEmpty
                                                ? 'Enter your email'
                                                : 'Email',
                                        hintStyle:
                                            const TextStyle(fontSize: 14),
                                        prefixIcon: const Icon(
                                            Icons.email_outlined,
                                            color: Color(0xFF0095D9),
                                            size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF0095D9),
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                            .hasMatch(value.trim())) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Aadhar Number field (moved here)
                                    TextFormField(
                                      controller: _aadharNoController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Aadhar Number (Optional)',
                                        labelStyle:
                                            const TextStyle(fontSize: 14),
                                        hintText:
                                            _aadharNoController.text.isEmpty
                                                ? 'Enter 12-digit Aadhar'
                                                : 'Aadhar number',
                                        hintStyle:
                                            const TextStyle(fontSize: 14),
                                        prefixIcon: const Icon(
                                            Icons.credit_card_outlined,
                                            color: Color(0xFF0095D9),
                                            size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF0095D9),
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                      ),
                                      keyboardType: TextInputType.number,
                                      maxLength: 12,
                                      validator: (value) {
                                        if (value != null &&
                                            value.trim().isNotEmpty) {
                                          if (!RegExp(r'^[0-9]{12} ?$')
                                              .hasMatch(value.trim())) {
                                            return 'Aadhar must be a 12-digit number';
                                          }
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        if (value.length == 12) {
                                          FocusScope.of(context).unfocus();
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Driving License field
                              TextFormField(
                                controller: _drivingLicenseController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Driving License',
                                  labelStyle: const TextStyle(fontSize: 14),
                                  hintText:
                                      _drivingLicenseController.text.isEmpty
                                          ? 'Enter license number'
                                          : 'License number',
                                  hintStyle: const TextStyle(fontSize: 14),
                                  prefixIcon: const Icon(
                                      Icons.card_membership_outlined,
                                      color: Color(0xFF0095D9),
                                      size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF0095D9), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter driving license number';
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
                                  prefixIcon: const Icon(Icons.note_outlined,
                                      color: Color(0xFF0095D9), size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF0095D9), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                maxLines: 2, // Reduced from 3
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _openingKmController,
                                style: const TextStyle(fontSize: 14),
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Opening KM',
                                  labelStyle: const TextStyle(fontSize: 14),
                                  hintText: 'Opening KM for test drive',
                                  hintStyle: const TextStyle(fontSize: 14),
                                  prefixIcon: const Icon(Icons.speed_outlined,
                                      color: Color(0xFF0095D9), size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF0095D9), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Last closing KM is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Car Images Section
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0095D9)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.photo_camera,
                                      color: Color(0xFF0095D9),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Car Images (All 5 Required)',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Image upload section
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[50],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upload all 5 car images (All required)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: _selectedImages.length,
                                      itemBuilder: (context, index) {
                                        final position = _selectedImages.keys
                                            .elementAt(index);
                                        final image = _selectedImages[position];
                                        // Define the correct image labels in order
                                        final imageLabels = [
                                          'Front Side',
                                          'Driver Side',
                                          'Rear Side',
                                          'Co-Driver Side',
                                          'Meter Reading',
                                        ];
                                        final imageLabel = imageLabels[index];
                                        return GestureDetector(
                                          onTap: image == null
                                              ? () => _pickImage(
                                                  ImageSource.camera, position)
                                              : null,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: image != null
                                                    ? const Color(0xFF0095D9)
                                                    : Colors.grey[300]!,
                                                width: image != null ? 2 : 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: Colors.white,
                                            ),
                                            child: Stack(
                                              children: [
                                                if (image != null)
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    child: Image.file(
                                                      image,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                                  )
                                                else
                                                  Container(
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.add_a_photo,
                                                          size: 32,
                                                          color:
                                                              Colors.grey[400],
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          imageLabel,
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.red,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: const Text(
                                                            'REQUIRED',
                                                            style: TextStyle(
                                                              fontSize: 8,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (image != null)
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: GestureDetector(
                                                      onTap: () => _removeImage(
                                                          position),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isSubmitting ? null : _submitRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0095D9),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12), // Reduced from 14
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          8), // Reduced from 10
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSubmitting
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(
                                                width: 10), // Reduced from 12
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
