import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'request_test_drive_screen.dart';
import '../../services/api_service.dart';
import '../../services/api_config.dart';
import '../../models/showroom_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ApiService _apiService = ApiService();
  bool _isListening = false;
  String _searchQuery = '';
  List<Showroom> _allShowrooms = [];
  List<Showroom> _searchResults = [];
  Map<int, int> _carCounts = {}; // Store car counts for each showroom
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _fetchShowrooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _fetchShowrooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getShowrooms();
      
      if (response.success) {
        setState(() {
          _allShowrooms = response.data ?? [];
          _isLoading = false;
        });
        
        // Fetch car counts for each showroom
        _fetchCarCounts();
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

  Future<void> _fetchCarCounts() async {
    for (final showroom in _allShowrooms) {
      try {
        final carResponse = await _apiService.getCarsByShowroom(showroom.id);
        if (carResponse.success) {
          setState(() {
            _carCounts[showroom.id] = carResponse.data?.length ?? 0;
          });
        }
      } catch (e) {
        // If car count fetch fails, set to 0
        setState(() {
          _carCounts[showroom.id] = 0;
        });
      }
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

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF0095D9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
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
                // Only perform search if we have a final result or enough characters
                if (result.finalResult || _searchQuery.length >= 2) {
                  _performSearch(_searchQuery);
                }
              });
            },
            listenFor: const Duration(seconds: 60), // Increased from 30 to 60 seconds
            pauseFor: const Duration(seconds: 5), // Increased from 3 to 5 seconds
            partialResults: true,
            localeId: 'en_US',
            cancelOnError: false, // Changed from true to false to handle errors gracefully
            listenMode: stt.ListenMode.dictation, // Changed from confirmation to dictation for better letter recognition
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

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchResults = _allShowrooms.where((showroom) => 
        showroom.name.toLowerCase().contains(query.toLowerCase()) ||
        showroom.locationDisplay.toLowerCase().contains(query.toLowerCase()) ||
        showroom.city.toLowerCase().contains(query.toLowerCase()) ||
        showroom.state.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus && _isListening) {
                  _speech.stop();
                  setState(() => _isListening = false);
                }
              },
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search showrooms or locations',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[600],
                      size: 22,
                    ),
                  ),
                  suffixIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isListening 
                          ? theme.primaryColor.withOpacity(0.1)
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
                              color: _isListening ? theme.primaryColor : Colors.grey[600],
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
                  border: InputBorder.none,
                  // contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  isDense: false,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _performSearch(value);
                  });
                },
                onSubmitted: (value) {
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
        ),
        centerTitle: true,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Results with improved empty states
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095D9)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading showrooms...',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 16,
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
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchShowrooms,
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
                      )
                    : _searchQuery.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.store_rounded,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Search for showrooms',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 48),
                                  child: Text(
                                    'Find showrooms by name or location',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _searchResults.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.search_off_rounded,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No showrooms found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 48),
                                      child: Text(
                                        'Try different keywords or check your spelling',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final showroom = _searchResults[index];
                                  return _buildSearchResultCard(showroom);
                                },
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(Showroom showroom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestTestDriveScreen(
                showroomName: showroom.name,
                availableCars: [], // Will be populated when cars API is available
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with image and rating
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    // Showroom image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: showroom.showroomImage != null
                          ? Image.network(
                              '${ApiConfig.baseUrl}/${showroom.showroomImage!}',
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.fill,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF0095D9).withOpacity(0.15),
                                        const Color(0xFF0095D9).withOpacity(0.08),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0095D9).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.store_rounded,
                                        color: Color(0xFF0095D9),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF0095D9).withOpacity(0.15),
                                        const Color(0xFF0095D9).withOpacity(0.08),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0095D9)),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF0095D9).withOpacity(0.15),
                                    const Color(0xFF0095D9).withOpacity(0.08),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0095D9).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.store_rounded,
                                    color: Color(0xFF0095D9),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    // Rating badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFD700),
                              size: 11,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              showroom.ratting.toString(),
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Showroom name
                    Text(
                      showroom.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Full location (City, State)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            showroom.locationDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Address
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.home_rounded,
                            size: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${showroom.address}, ${showroom.pincode}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0095D9).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_carCounts[showroom.id]?.toString() ?? 'N/A'} cars',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF0095D9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Book Drive button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RequestTestDriveScreen(
                                showroomName: showroom.name,
                                availableCars: [], // Will be populated when cars API is available
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095D9),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Book Drive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 