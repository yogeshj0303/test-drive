import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cached_network_image/cached_network_image.dart';
import 'car_details_screen.dart';
import '../../services/api_service.dart';
import '../../models/car_model.dart';
import '../../models/user_model.dart';

class NotchedCardShape extends ShapeBorder {
  final double notchRadius;
  final double borderRadius;
  NotchedCardShape({this.notchRadius = 32, this.borderRadius = 12});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final r = borderRadius;
    final notchR = notchRadius;
    final path = Path();

    // Top left to top right
    path.moveTo(rect.left + r, rect.top);
    path.lineTo(rect.right - r, rect.top);
    path.quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + r);

    // Right edge to just above the notch
    path.lineTo(rect.right, rect.bottom - notchR);

    // Curve around the notch (quarter circle)
    path.arcToPoint(
      Offset(rect.right - notchR, rect.bottom),
      radius: Radius.circular(notchR),
      clockwise: false,
    );

    // Bottom edge to bottom left
    path.lineTo(rect.left + r, rect.bottom);
    path.quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - r);

    // Left edge to top left
    path.lineTo(rect.left, rect.top + r);
    path.quadraticBezierTo(rect.left, rect.top, rect.left + r, rect.top);

    path.close();
    return path;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class CarsScreen extends StatefulWidget {
  final String showroomName;
  final List<Car> availableCars;
  final String showroomLocation;
  final String showroomRating;
  final String showroomDistance;
  final int showroomId; // Add showroom ID for API calls
  final String locationType; // Add location type

  const CarsScreen({
    super.key,
    required this.showroomName,
    required this.availableCars,
    required this.showroomLocation,
    required this.showroomRating,
    required this.showroomDistance,
    required this.showroomId,
    required this.locationType,
  });

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Search and filter state variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Speech recognition variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  // API service and data
  final ApiService _apiService = ApiService();
  List<Car> _cars = [];
  List<Car> _filteredCars = []; // Add filtered cars list
  bool _isLoading = true;
  String? _errorMessage;

  // View and sort options
  String _viewMode = 'list'; // 'list' or 'grid'
  String _sortBy = 'name'; // 'name', 'price', 'newest'

  // Location type filter
  String _selectedLocationType = 'all'; // 'all', 'showroom', 'yard', 'workshop'
  List<String> _locationTypes = ['all', 'showroom', 'yard', 'workshop'];
  bool _isFilteringByLocation = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced from 800
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400), // Reduced from 600
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Reduced from 0.3
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
    _initSpeech();
    _fetchCars();
  }

  Future<void> _initSpeech() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status.isDenied) {
        _showErrorSnackBar(
            'Microphone permission is required for voice search');
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
        _showErrorSnackBar(
            'Speech recognition is not available on this device');
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
        _showErrorSnackBar(
            'Microphone permission is required for voice search');
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
                // Only perform search if we have a final result or enough characters
                if (result.finalResult || _searchQuery.length >= 2) {
                  _updateSearchQuery(_searchQuery);
                }
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
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Enhanced gradient background with multiple layers
          Container(
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
          // Subtle overlay pattern
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact top bar with back button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8), // Reduced padding
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16),
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                      const SizedBox(width: 8), // Reduced from 12
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Choose a Car',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18, // Reduced from 20
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.showroomName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11, // Reduced from 12
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Compact search bar and filter
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12), // Reduced from 16
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40, // Reduced from 44
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  _updateSearchQuery(value);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search cars or locations...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12, // Reduced from 13
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.all(
                                        6), // Reduced from 8
                                    margin: const EdgeInsets.only(
                                        right: 2), // Reduced from 4
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0095D9)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.search,
                                        color: Color(0xFF0095D9),
                                        size: 14), // Reduced from 16
                                  ),
                                  suffixIcon: Container(
                                    margin: const EdgeInsets.only(
                                        right: 2), // Reduced from 4
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: _isListening
                                            ? const Color(0xFF0095D9)
                                                .withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          IconButton(
                                            icon: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: Icon(
                                                _isListening
                                                    ? Icons.mic
                                                    : Icons.mic_none_rounded,
                                                key: ValueKey<bool>(
                                                    _isListening),
                                                color: _isListening
                                                    ? const Color(0xFF0095D9)
                                                    : Colors.grey[600],
                                                size: 16, // Reduced from 18
                                              ),
                                            ),
                                            onPressed: _startListening,
                                            tooltip: _isListening
                                                ? 'Stop listening'
                                                : 'Tap to start voice search',
                                            padding: const EdgeInsets.all(
                                                6), // Reduced from 8
                                            constraints: const BoxConstraints(
                                              minWidth: 28, // Reduced from 32
                                              minHeight: 28, // Reduced from 32
                                            ),
                                          ),
                                          if (_isListening)
                                            Positioned(
                                              right: 6, // Reduced from 8
                                              top: 6, // Reduced from 8
                                              child: Container(
                                                width: 5, // Reduced from 6
                                                height: 5, // Reduced from 6
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
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 10), // Reduced
                                  isDense: true,
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF0095D9),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12, // Reduced from 13
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8), // Reduced from 10
                          // Remove 3 dots from search bar area
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12), // Reduced from 16
                // Compact results count
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 0), // Reduced from 24
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _cars.isEmpty
                                ? 'No Results'
                                : _isFilteringByLocation
                                    ? '${_filteredCars.length} ${_getLocationTypeLabel(_selectedLocationType)}'
                                    : _filteredCars.length == _cars.length
                                        ? '${_filteredCars.length} Results'
                                        : '${_filteredCars.length} of ${_cars.length} Results',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11, // Reduced from 12
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: _showOptionsMenu,
                            child: Icon(Icons.more_horiz,
                                color: Colors.white.withOpacity(0.9),
                                size: 16), // Reduced from 18
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Reduced from 12
                // Compact car list with proper scrolling boundaries
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0095D9)),
                                  ),
                                  SizedBox(height: 12), // Reduced from 16
                                  Text(
                                    'Loading cars...',
                                    style: TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 14, // Reduced from 16
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _errorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 56, // Reduced from 64
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(
                                          height: 12), // Reduced from 16
                                      Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14, // Reduced from 16
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(
                                          height: 12), // Reduced from 16
                                      ElevatedButton(
                                        onPressed: _fetchCars,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0095D9),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              : _filteredCars.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _cars.isEmpty
                                                ? Icons.directions_car_outlined
                                                : Icons.search_off_rounded,
                                            size: 56, // Reduced from 64
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(
                                              height: 12), // Reduced from 16
                                          Text(
                                            _cars.isEmpty
                                                ? 'No cars available'
                                                : 'No cars match your filters',
                                            style: const TextStyle(
                                              color: Color(0xFF666666),
                                              fontSize: 14, // Reduced from 16
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: 6), // Reduced from 8
                                          Text(
                                            _cars.isEmpty
                                                ? 'Check back later for available cars'
                                                : _isFilteringByLocation
                                                    ? 'No cars found in ${_getLocationTypeLabel(_selectedLocationType).toLowerCase()}'
                                                    : 'Try adjusting your search or filters',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13, // Reduced from 14
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (_cars.isNotEmpty &&
                                              (_searchQuery.isNotEmpty ||
                                                  _isFilteringByLocation))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 12), // Reduced from 16
                                              child: TextButton(
                                                onPressed: _clearAllFilters,
                                                child: const Text(
                                                  'Clear all filters',
                                                  style: TextStyle(
                                                    color: Color(0xFF0095D9),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  : NotificationListener<ScrollNotification>(
                                      onNotification:
                                          (ScrollNotification scrollInfo) {
                                        // Handle scroll notifications if needed
                                        return false;
                                      },
                                      child: _viewMode == 'grid'
                                          ? _buildGridView()
                                          : _buildListView(),
                                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Car car, int index) {
    const double buttonDiameter = 48;

    return TweenAnimationBuilder<double>(
      duration:
          Duration(milliseconds: 500 + (index * 80)), // Reduced from 600 + 100
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)), // Reduced from 30
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.only(
                  bottom: 8, top: 1, left: 1, right: 1), // Reduced padding
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main card container
                  Material(
                    elevation: 0,
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16, // Reduced from 20
                            offset: const Offset(0, 6), // Reduced from 8
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4, // Reduced from 6
                            offset: const Offset(0, 1), // Reduced from 2
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact header with rating and deals
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                12, 12, 12, 0), // Reduced from 16
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Rating badge with enhanced design
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF8A65),
                                        Color(0xFFFF5722)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF5722)
                                            .withOpacity(0.25),
                                        blurRadius: 8, // Reduced from 12
                                        offset: const Offset(
                                            0, 3), // Reduced from 4
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Colors.white,
                                          size: 12), // Reduced from 14
                                      const SizedBox(
                                          width: 3), // Reduced from 4
                                      const Text(
                                        '4.5',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11, // Reduced from 12
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Deals badge with enhanced design
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4CAF50),
                                        Color(0xFF388E3C)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4CAF50)
                                            .withOpacity(0.25),
                                        blurRadius: 8, // Reduced from 12
                                        offset: const Offset(
                                            0, 3), // Reduced from 4
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.local_offer_rounded,
                                          color: Colors.white,
                                          size: 12), // Reduced from 14
                                      const SizedBox(
                                          width: 3), // Reduced from 4
                                      Text(
                                        '${car.hasDiscount ? "Discount" : "New"}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11, // Reduced from 12
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12), // Reduced from 16
                          // Compact car image section
                          Container(
                            height: 150, // Reduced from 120
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12), // Reduced from 16
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  // Car image
                                  Positioned.fill(
                                    child: CachedNetworkImage(
                                      imageUrl: car.mainImage,
                                      fit: BoxFit.fill,
                                      placeholder: (context, url) => Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFF0095D9)
                                                  .withOpacity(0.05),
                                              const Color(0xFF0095D9)
                                                  .withOpacity(0.02),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF0095D9)
                                                .withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 18, // Reduced from 20
                                                height: 18, // Reduced from 20
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          Color(0xFF0095D9)),
                                                ),
                                              ),
                                              SizedBox(
                                                  height: 6), // Reduced from 8
                                              Text(
                                                'Loading...',
                                                style: TextStyle(
                                                  color: Color(0xFF0095D9),
                                                  fontSize:
                                                      11, // Reduced from 12
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFF0095D9)
                                                  .withOpacity(0.05),
                                              const Color(0xFF0095D9)
                                                  .withOpacity(0.02),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF0095D9)
                                                .withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.directions_car_rounded,
                                                size: 32, // Reduced from 40
                                                color: Color(0xFF0095D9),
                                              ),
                                              SizedBox(
                                                  height: 4), // Reduced from 6
                                              Text(
                                                'Image not available',
                                                style: TextStyle(
                                                  color: Color(0xFF0095D9),
                                                  fontSize:
                                                      10, // Reduced from 11
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Subtle overlay for depth
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withOpacity(0.1),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12), // Reduced from 16
                          // Compact car details section
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12), // Reduced from 16
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Car name with enhanced typography
                                Text(
                                  car.name,
                                  style: const TextStyle(
                                    fontSize: 16, // Reduced from 18
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4), // Reduced from 6
                                // Car specifications row
                                Row(
                                  children: [
                                    _buildSpecItem('Fuel', car.fuelType,
                                        Icons.local_gas_station_rounded),
                                    const SizedBox(width: 8), // Reduced from 12
                                    _buildSpecItem('Trans', car.transmission,
                                        Icons.settings_rounded),
                                    const SizedBox(width: 8), // Reduced from 12
                                    _buildSpecItem(
                                        'Seats',
                                        '${car.seatingCapacity}',
                                        Icons
                                            .airline_seat_recline_normal_rounded),
                                  ],
                                ),
                                const SizedBox(height: 12), // Reduced from 16
                                // Price and action section
                                Row(
                                  children: [
                                    // Book test drive button (full width)
                                    Expanded(
                                      child: Container(
                                        height: 40, // Reduced from 44
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF0095D9),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0095D9)
                                                  .withOpacity(0.15),
                                              blurRadius: 6, // Reduced from 8
                                              offset: const Offset(
                                                  0, 1), // Reduced from 2
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CarDetailsScreen(
                                                    carName: car.name,
                                                    showroomName:
                                                        widget.showroomName,
                                                    locationType:
                                                        widget.locationType,
                                                    showroomLocation:
                                                        widget.showroomLocation,
                                                    showroomId:
                                                        widget.showroomId,
                                                  ),
                                                ),
                                              );
                                            },
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: const Center(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .directions_car_rounded,
                                                    color: Color(0xFF0095D9),
                                                    size: 14, // Reduced from 16
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          3), // Reduced from 4
                                                  Text(
                                                    'Request to test drive',
                                                    style: TextStyle(
                                                      color: Color(0xFF0095D9),
                                                      fontSize:
                                                          12, // Reduced from 13
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8), // Reduced from 12
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4), // Reduced from 6
            decoration: BoxDecoration(
              color: const Color(0xFF0095D9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 12, // Reduced from 14
              color: const Color(0xFF0095D9),
            ),
          ),
          const SizedBox(width: 6), // Reduced from 8
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9, // Reduced from 10
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1), // Reduced from 2
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11, // Reduced from 12
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ApiResponse<List<Car>> response;

      if (_isFilteringByLocation && _selectedLocationType != 'all') {
        // Fetch cars by location type
        response =
            await _apiService.getCarsByLocationType(_selectedLocationType);
      } else {
        // Fetch cars by showroom (default behavior)
        response = await _apiService.getCarsByShowroom(widget.showroomId);
      }

      if (response.success) {
        setState(() {
          _cars = response.data ?? [];
          _filteredCars = _cars;
          _isLoading = false;
        });
        _applyFilters();
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

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<Car> filtered = List.from(_cars);

    // Apply search filter only
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((car) {
        final query = _searchQuery.toLowerCase();
        return car.name.toLowerCase().contains(query) ||
            car.fuelType.toLowerCase().contains(query) ||
            car.transmission.toLowerCase().contains(query) ||
            car.showroom.name.toLowerCase().contains(query) ||
            car.modelNumber.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'newest':
        filtered
            .sort((a, b) => b.yearOfManufacture.compareTo(a.yearOfManufacture));
        break;
    }

    setState(() {
      _filteredCars = filtered;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedLocationType = 'all';
      _isFilteringByLocation = false;
    });
    _applyFilters();
    _fetchCars();
  }

  void _resetLocationFilter() {
    setState(() {
      _selectedLocationType = 'all';
      _isFilteringByLocation = false;
    });
    _fetchCars();
  }

  // Menu functionality methods
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOptionsMenu(),
    );
  }

  Widget _buildOptionsMenu() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.more_horiz, color: Color(0xFF0095D9), size: 20),
                SizedBox(width: 12),
                Text(
                  'More Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20), // Reduced spacing

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // View Mode Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'View Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMenuOption(
                              icon: Icons.view_list,
                              title: 'List View',
                              subtitle: 'Detailed cards',
                              isSelected: _viewMode == 'list',
                              onTap: () {
                                setState(() => _viewMode = 'list');
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMenuOption(
                              icon: Icons.grid_view,
                              title: 'Grid View',
                              subtitle: 'Compact layout',
                              isSelected: _viewMode == 'grid',
                              onTap: () {
                                setState(() => _viewMode = 'grid');
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Reduced spacing

                  // Sort Options Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSortOption(
                        icon: Icons.sort_by_alpha,
                        title: 'Name (A-Z)',
                        isSelected: _sortBy == 'name',
                        onTap: () {
                          setState(() => _sortBy = 'name');
                          _applySorting();
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildSortOption(
                        icon: Icons.new_releases,
                        title: 'Newest First',
                        isSelected: _sortBy == 'newest',
                        onTap: () {
                          setState(() => _sortBy = 'newest');
                          _applySorting();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Reduced spacing

                  // Location Filter Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location Filter',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLocationFilterOption(
                        icon: Icons.public,
                        title: 'All Locations',
                        isSelected: _selectedLocationType == 'all',
                        onTap: () {
                          Navigator.pop(context);
                          _onLocationTypeChanged('all');
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildLocationFilterOption(
                        icon: Icons.store,
                        title: 'Showrooms',
                        isSelected: _selectedLocationType == 'showroom',
                        onTap: () {
                          Navigator.pop(context);
                          _onLocationTypeChanged('showroom');
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildLocationFilterOption(
                        icon: Icons.local_parking,
                        title: 'Yards',
                        isSelected: _selectedLocationType == 'yard',
                        onTap: () {
                          Navigator.pop(context);
                          _onLocationTypeChanged('yard');
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildLocationFilterOption(
                        icon: Icons.build,
                        title: 'Workshops',
                        isSelected: _selectedLocationType == 'workshop',
                        onTap: () {
                          Navigator.pop(context);
                          _onLocationTypeChanged('workshop');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Reduced spacing

                  // Actions Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildActionOption(
                        icon: Icons.refresh,
                        title: 'Refresh Cars',
                        subtitle: 'Update car list',
                        onTap: () {
                          Navigator.pop(context);
                          _fetchCars();
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionOption(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get assistance',
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpDialog();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Reduced bottom spacing
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0095D9).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0095D9) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0095D9) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0095D9)
                    : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0095D9).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0095D9) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0095D9) : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0095D9)
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF0095D9),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF0095D9),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _applySorting() {
    List<Car> sorted = List.from(_filteredCars);

    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'newest':
        sorted
            .sort((a, b) => b.yearOfManufacture.compareTo(a.yearOfManufacture));
        break;
    }

    setState(() {
      _filteredCars = sorted;
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0095D9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.help_outline, color: Color(0xFF0095D9)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to use the Cars screen:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('• Use the search bar to find specific cars'),
            Text('• Tap the microphone for voice search'),
            Text('• Use location filters to find cars by type'),
            Text('• Use the menu (⋮) for view options and sorting'),
            Text('• Tap "Book" to view car details'),
            SizedBox(height: 12),
            Text(
              'Location Types:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('• Showrooms: Cars available at showroom locations'),
            Text('• Yards: Cars stored in yard facilities'),
            Text('• Workshops: Cars being serviced or repaired'),
            SizedBox(height: 12),
            Text(
              'Need more help?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('Contact support at support@Varenyam.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: Color(0xFF0095D9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 8), // Reduced from 12
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final car = _filteredCars[index];
                return _buildCarCard(car, index);
              },
              childCount: _filteredCars.length,
            ),
          ),
        ),
        // Add extra padding at the bottom for better scrolling experience
        const SliverToBoxAdapter(
          child: SizedBox(height: 12), // Reduced from 16
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: 4, vertical: 8), // Reduced from 6
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 4, // Reduced from 6
              mainAxisSpacing: 4, // Reduced from 6
              childAspectRatio: 1, // Reduced from 0.7 for smaller cards
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final car = _filteredCars[index];
                return _buildGridCard(car, index);
              },
              childCount: _filteredCars.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 6), // Reduced from 8
        ),
      ],
    );
  }

  Widget _buildGridCard(Car car, int index) {
    return TweenAnimationBuilder<double>(
      duration:
          Duration(milliseconds: 500 + (index * 80)), // Reduced from 600 + 100
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)), // Reduced from 30
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8, // Reduced from 12
                    offset: const Offset(0, 2), // Reduced from 4
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car image
                  Expanded(
                    flex: 2, // Reduced from 4 to make image smaller
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: car.mainImage,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit
                            .cover, // Changed back to cover for better aspect ratio
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: const Color(0xFF0095D9).withOpacity(0.05),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0095D9)),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: const Color(0xFF0095D9).withOpacity(0.05),
                          child: const Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: Color(0xFF0095D9),
                              size: 16, // Reduced from 20
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Car details
                  Expanded(
                    flex: 3, // Increased from 2 to give more space for car data
                    child: Padding(
                      padding: const EdgeInsets.all(4), // Increased from 3
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Car name
                          Text(
                            car.name,
                            style: const TextStyle(
                              fontSize: 12, // Increased from 10
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2), // Increased from 1
                          // Car specifications
                          Row(
                            children: [
                              Expanded(
                                child: _buildGridSpecItem('Fuel', car.fuelType,
                                    Icons.local_gas_station_rounded),
                              ),
                              const SizedBox(width: 3), // Increased from 2
                              Expanded(
                                child: _buildGridSpecItem('Trans',
                                    car.transmission, Icons.settings_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2), // Increased from 1
                          // Seating capacity and last closing km
                          Row(
                            children: [
                              Expanded(
                                child: _buildGridSpecItem(
                                    'Seats',
                                    '${car.seatingCapacity}',
                                    Icons.airline_seat_recline_normal_rounded),
                              ),
                              const SizedBox(width: 3), // Increased from 2
                              Expanded(
                                child: _buildGridSpecItem(
                                    car.lastClosingKm != null ? 'KM' : 'Year',
                                    car.lastClosingKm != null 
                                        ? '${car.lastClosingKm}'
                                        : '${car.yearOfManufacture}',
                                    car.lastClosingKm != null 
                                        ? Icons.speed_rounded
                                        : Icons.calendar_today_rounded),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Book button
                          SizedBox(
                            width: double.infinity,
                            height: 20, // Increased from 16
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CarDetailsScreen(
                                      carName: car.name,
                                      showroomName: widget.showroomName,
                                      locationType: widget.locationType,
                                      showroomLocation: widget.showroomLocation,
                                      showroomId: widget.showroomId,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0095D9),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              child: const Text(
                                'Request to test drive',
                                style: TextStyle(
                                  fontSize: 9, // Increased from 7
                                  fontWeight: FontWeight.w600,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridSpecItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2), // Increased from 1
          decoration: BoxDecoration(
            color: const Color(0xFF0095D9).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 8, // Increased from 6
            color: const Color(0xFF0095D9),
          ),
        ),
        const SizedBox(width: 3), // Increased from 2
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 8, // Increased from 6
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 9, // Increased from 7
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationFilterOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0095D9).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0095D9) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0095D9) : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0095D9)
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF0095D9),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _onLocationTypeChanged(String locationType) {
    setState(() {
      _selectedLocationType = locationType;
      _isFilteringByLocation = locationType != 'all';
    });
    _fetchCars();
  }

  IconData _getLocationTypeIcon(String locationType) {
    switch (locationType) {
      case 'all':
        return Icons.public;
      case 'showroom':
        return Icons.store;
      case 'yard':
        return Icons.local_parking;
      case 'workshop':
        return Icons.build;
      default:
        return Icons.public;
    }
  }

  String _getLocationTypeLabel(String locationType) {
    switch (locationType) {
      case 'all':
        return 'All Locations';
      case 'showroom':
        return 'Showrooms';
      case 'yard':
        return 'Yards';
      case 'workshop':
        return 'Workshops';
      default:
        return 'All Locations';
    }
  }
}
