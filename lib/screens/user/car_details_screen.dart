import 'package:flutter/material.dart';
import 'request_test_drive_screen.dart';
import '../../services/api_service.dart';
import '../../models/car_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CarDetailsScreen extends StatefulWidget {
  final String carName;
  final String showroomName;
  final String showroomLocation;
  final int showroomId; // Add showroom ID for API calls

  const CarDetailsScreen({
    super.key,
    required this.carName,
    required this.showroomName,
    required this.showroomLocation,
    required this.showroomId,
  });

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentImageIndex = 0;

  // API service and data
  final ApiService _apiService = ApiService();
  Car? _car;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController(initialPage: 1000);
    _fetchCar();
  }

  Future<void> _fetchCar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getCarsByShowroom(widget.showroomId);
      
      if (response.success) {
        // Find the specific car by name
        final car = response.data?.firstWhere(
          (car) => car.name.toLowerCase().contains(widget.carName.toLowerCase()),
          orElse: () => response.data!.first,
        );
        
        setState(() {
          _car = car;
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
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095D9)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading car details...',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _car == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Car not found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchCar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0095D9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _car!;
    final price = double.tryParse(data.price) ?? 1500;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Compact gradient background
          Container(
            height: 200,
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
                  // Compact top bar with only back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Compact car image and info card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      transform: Matrix4.translationValues(0, 5, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Compact car image gallery
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: data.images.isNotEmpty
                                  ? PageView.builder(
                                      controller: _pageController,
                                      itemCount: data.images.length * 1000,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentImageIndex = index % data.images.length;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        final imageIndex = index % data.images.length;
                                        return Container(
                                          margin: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: CachedNetworkImage(
                                              imageUrl: data.images[imageIndex],
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.grey[300]!,
                                                      Colors.grey[200]!,
                                                      Colors.grey[300]!,
                                                    ],
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095D9)),
                                                        ),
                                                      ),
                                                      SizedBox(height: 6),
                                                      Text(
                                                        'Loading...',
                                                        style: TextStyle(
                                                          color: Color(0xFF0095D9),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.grey[100]!,
                                                      Colors.grey[50]!,
                                                    ],
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.directions_car_rounded,
                                                        size: 32,
                                                        color: Color(0xFF0095D9),
                                                      ),
                                                      SizedBox(height: 6),
                                                      Text(
                                                        'Image not available',
                                                        style: TextStyle(
                                                          color: Color(0xFF0095D9),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.grey[100]!,
                                            Colors.grey[50]!,
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.directions_car_rounded,
                                              size: 48,
                                              color: Color(0xFF0095D9),
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'No images available',
                                              style: TextStyle(
                                                color: Color(0xFF0095D9),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            // Compact image indicator dots
                            if (data.images.length > 1) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  data.images.length,
                                  (index) => Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == _currentImageIndex ? const Color(0xFF0095D9) : Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Compact car name and type
                            Text(
                              data.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.bodyType ?? 'Car',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            // Compact rating
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5722).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.white, size: 12),
                                  const SizedBox(width: 2),
                                  const Text(
                                    '4.5',
                                    style: TextStyle(
                                      color: Colors.white, 
                                      fontWeight: FontWeight.w700, 
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Compact features grid
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                _buildFeatureItem(Icons.local_gas_station, data.fuelType),
                                _buildFeatureItem(Icons.settings, data.transmission),
                                _buildFeatureItem(Icons.event_seat, '${data.seatingCapacity} Seater'),
                                _buildFeatureItem(Icons.palette, data.color.split(',').first.trim()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Compact Showroom Information Section
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0095D9).withOpacity(0.1),
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
                                'Showroom Information',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildSpecificationRow('Showroom', widget.showroomName),
                          _buildSpecificationRow('Location', widget.showroomLocation),
                          _buildSpecificationRow('Available', 'Yes'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  // Compact Book Now Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0095D9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RequestTestDriveScreen(
                                  showroomName: widget.showroomName,
                                  availableCars: [widget.carName],
                                  selectedStartDate: DateTime.now(),
                                  selectedEndDate: DateTime.now().add(const Duration(days: 1)),
                                  pickupLocation: "Showroom Location",
                                  carId: _car?.id ?? 3,
                                  showroomId: _car?.showroom.id ?? widget.showroomId,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Request Test Drive',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon, VoidCallback? onTap, bool isRequired = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isRequired ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isRequired 
                    ? Colors.orange.withOpacity(0.1)
                    : const Color(0xFF0095D9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isRequired ? Colors.orange : const Color(0xFF0095D9),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isRequired ? Colors.orange : const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF0095D9).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF0095D9).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF0095D9),
            size: 16,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF0095D9),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF0095D9),
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 