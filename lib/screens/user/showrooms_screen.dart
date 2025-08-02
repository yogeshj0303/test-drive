import 'package:flutter/material.dart';
import 'cars_screen.dart';
import 'search_screen.dart';
import '../../services/api_service.dart';
import '../../services/api_config.dart';
import '../../services/storage_service.dart';
import '../../models/showroom_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ShowroomsScreen extends StatefulWidget {
  const ShowroomsScreen({super.key});

  @override
  State<ShowroomsScreen> createState() => _ShowroomsScreenState();
}

class _ShowroomsScreenState extends State<ShowroomsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  List<Showroom> _showrooms = [];
  List<Showroom> _filteredShowrooms = [];
  Map<int, int> _carCounts = {}; // Store car counts for each showroom
  bool _isLoading = true;
  String? _errorMessage;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initializeSpeech();
    _fetchShowrooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (error) {
          setState(() {
            _isListening = false;
          });
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      setState(() {});
    } catch (e) {
      _speechEnabled = false;
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      setState(() {
        _isListening = true;
      });
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _searchController.text = result.recognizedWords;
              _isListening = false;
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: \\${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredShowrooms = _showrooms.where((showroom) {
        return showroom.name.toLowerCase().contains(query) ||
            showroom.locationDisplay.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchCarCountsForShowrooms(List<Showroom> showrooms) async {
    for (final showroom in showrooms) {
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

  Future<void> _fetchShowrooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getAllShowrooms();
      if (response.success) {
        final allShowrooms = response.data ?? [];
        setState(() {
          _showrooms = allShowrooms;
          _filteredShowrooms = allShowrooms;
          _isLoading = false;
        });
        _fetchCarCountsForShowrooms(_showrooms);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF0095D9),
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back',
              )
            : null,
        title: const Text(
          'Showrooms',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isLoading)
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF1A1A1A),
                  size: 22,
                ),
              ),
              onSelected: (value) {
                if (value == 'grid') {
                  setState(() {
                    _isGridView = true;
                  });
                } else if (value == 'list') {
                  setState(() {
                    _isGridView = false;
                  });
                }
              },
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: 'grid',
                  checked: _isGridView,
                  child: const Text('Grid View'),
                ),
                CheckedPopupMenuItem(
                  value: 'list',
                  checked: !_isGridView,
                  child: const Text('List View'),
                ),
              ],
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Icon(
                        Icons.search_rounded,
                        color: Colors.grey[600],
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search showrooms...',
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_speechEnabled)
                        IconButton(
                          icon: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color:
                                  _isListening ? Colors.red : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          onPressed:
                              _isListening ? _stopListening : _startListening,
                          tooltip:
                              _isListening ? 'Stop listening' : 'Voice search',
                        ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                          },
                          child: Icon(Icons.clear,
                              color: Colors.grey[500], size: 20),
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                if (_isListening)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Listening... Speak now',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_speechEnabled && _showrooms.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Voice search not available on this device',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
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
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
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
      );
    }

    if (_errorMessage != null) {
      return Center(
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
      );
    }

    if (_filteredShowrooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No showrooms found',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search keyword',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _isGridView
        ? GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredShowrooms.length,
            itemBuilder: (context, index) {
              final showroom = _filteredShowrooms[index];
              return _buildShowroomCard(showroom);
            },
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredShowrooms.length,
            itemBuilder: (context, index) {
              final showroom = _filteredShowrooms[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildShowroomCard(showroom),
              );
            },
          );
  }

  Widget _buildShowroomCard(Showroom showroom) {
    return Card(
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
              builder: (context) => CarsScreen(
                showroomName: showroom.name,
                availableCars: [], // Will be populated when cars API is available
                showroomLocation: showroom.locationDisplay,
                showroomRating: showroom.ratting.toString(),
                locationType: showroom.locationType ?? '',
                showroomDistance: 'N/A',
                showroomId: showroom.id,
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
            mainAxisSize: MainAxisSize.min,
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
                                        const Color(0xFF0095D9)
                                            .withOpacity(0.15),
                                        const Color(0xFF0095D9)
                                            .withOpacity(0.08),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0095D9)
                                            .withOpacity(0.1),
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
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF0095D9)
                                            .withOpacity(0.15),
                                        const Color(0xFF0095D9)
                                            .withOpacity(0.08),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF0095D9)),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: double.infinity,
                              height: 100,
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
                                    color: const Color(0xFF0095D9)
                                        .withOpacity(0.1),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
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
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Showroom name
                    Text(
                      showroom.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Location
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
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            showroom.locationDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Available cars
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.directions_car_rounded,
                            size: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Available cars',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0095D9).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _carCounts[showroom.id]?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 9,
                              color: const Color(0xFF0095D9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Book Drive button
                    SizedBox(
                      width: double.infinity,
                      height: 26,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CarsScreen(
                                showroomName: showroom.name,
                                availableCars: [], // Will be populated when cars API is available
                                showroomLocation: showroom.locationDisplay,
                                showroomRating: showroom.ratting.toString(),
                                showroomDistance: 'N/A',
                                showroomId: showroom.id,
                                locationType: showroom.locationType ?? '',
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
                            fontSize: 10,
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
