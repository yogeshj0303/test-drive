import 'package:flutter/material.dart';
import '../../models/test_drive_model.dart';
import '../../models/review_model.dart' as review;
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../screens/user/user_profile_screen.dart';

class ReviewFormScreen extends StatefulWidget {
  final TestDriveListResponse? testDrive;

  const ReviewFormScreen({super.key, this.testDrive});

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  List<TestDriveListResponse> _completedTestDrives = [];
  Set<int> _reviewedTestDriveIds = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadCompletedTestDrives();
  }

  Future<void> _loadCompletedTestDrives() async {
    if (widget.testDrive != null) {
      // If a specific test drive is provided, we don't need to load the list
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = await _storageService.getUser();
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User data not found. Please login again.';
        });
        return;
      }

      // Load both completed test drives and reviewed test drive IDs
      final response = await _apiService.getUserCompletedTestDrives(user.id);
      
      // Handle storage errors gracefully
      Set<int> reviewedTestDrives = <int>{};
      try {
        reviewedTestDrives = await _storageService.getReviewedTestDrives();
      } catch (e) {
        print('Error loading reviewed test drives: $e');
        // Continue with empty set if storage fails
      }
      
      if (response.success) {
        setState(() {
          _completedTestDrives = response.data ?? [];
          _reviewedTestDriveIds = reviewedTestDrives;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load completed test drives';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    await _loadCompletedTestDrives();
    setState(() {
      _isRefreshing = false;
    });
  }

  void _showReviewForm(TestDriveListResponse testDrive) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ReviewFormContent(
          carName: testDrive.car?.name ?? 'Unknown',
          showroom: testDrive.showroom?.name ?? 'Unknown',
          testDrive: testDrive,
        ),
      ),
    ).then((_) {
      // Refresh the list after review submission
      _loadCompletedTestDrives();
    });
  }

  @override
  Widget build(BuildContext context) {
    // If a test drive is provided, show the review form directly
    if (widget.testDrive != null) {
      return _ReviewFormContent(
        carName: widget.testDrive!.car?.name ?? 'Unknown',
        showroom: widget.testDrive!.showroom?.name ?? 'Unknown',
        testDrive: widget.testDrive,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Review Test Drive',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095D9)),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Test Drives',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCompletedTestDrives,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095D9),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _completedTestDrives.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Test Drives to Review',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete a test drive to leave a review',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _completedTestDrives.length,
                      itemBuilder: (context, index) {
                        final testDrive = _completedTestDrives[index];
                        final hasReview = _reviewedTestDriveIds.contains(testDrive.id);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          child: InkWell(
                            onTap: hasReview ? null : () => _showReviewForm(testDrive),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0095D9).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.directions_car_outlined,
                                          color: Color(0xFF0095D9),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              testDrive.car?.name ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              testDrive.showroom?.name ?? 'Unknown',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (hasReview)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Reviewed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF4CAF50),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoItem(
                                          'Date',
                                          testDrive.date ?? 'Unknown',
                                          Icons.calendar_today_outlined,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildInfoItem(
                                          'Time',
                                          testDrive.time ?? 'Unknown',
                                          Icons.access_time_rounded,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildInfoItem(
                                          'Duration',
                                          '30 mins', // Default duration since it's not in the model
                                          Icons.timer_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: hasReview 
                                        ? Colors.grey[100]
                                        : const Color(0xFF0095D9).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        hasReview ? 'Already Reviewed' : 'Tap to Leave a Review',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: hasReview 
                                            ? Colors.grey[600]
                                            : const Color(0xFF0095D9),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _ReviewFormContent extends StatefulWidget {
  final String carName;
  final String showroom;
  final TestDriveListResponse? testDrive;

  const _ReviewFormContent({
    required this.carName,
    required this.showroom,
    this.testDrive,
  });

  @override
  State<_ReviewFormContent> createState() => _ReviewFormContentState();
}

class _ReviewFormContentState extends State<_ReviewFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final StorageService _storageService = StorageService();
  double _overallRating = 0;
  double _comfortRating = 0;
  double _performanceRating = 0;
  double _valueRating = 0;
  bool _wouldRecommend = true;

  final List<String> _ratingLabels = [
    'Poor',
    'Fair',
    'Good',
    'Very Good',
    'Excellent'
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getRatingLabel(double rating) {
    if (rating <= 0) return 'Select rating';
    return _ratingLabels[(rating - 1).round()];
  }

  void _submitReview() async {
    if (_formKey.currentState!.validate() && _overallRating > 0) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095D9)),
              ),
            );
          },
        );

        // Get user data from storage
        final storageService = StorageService();
        final user = await storageService.getUser();
        
        if (user == null) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User data not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Get test drive ID from the passed test drive
        if (widget.testDrive == null) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test drive data not found.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Convert ratings to string values
        String _ratingToString(double rating) {
          if (rating <= 1) return 'Poor';
          if (rating <= 2) return 'Fair';
          if (rating <= 3) return 'Good';
          if (rating <= 4) return 'Very Good';
          return 'Excellent';
        }

        // Create review request
        final reviewRequest = review.ReviewRequest(
          userId: user.id,
          testDriveId: widget.testDrive!.id,
          overallExperience: _ratingToString(_overallRating),
          comfortInterior: _ratingToString(_comfortRating),
          performanceHandling: _ratingToString(_performanceRating),
          valueMoney: _ratingToString(_valueRating),
          recommend: _wouldRecommend,
          comment: _commentController.text.trim(),
        );

        // Submit review via API
        final apiService = ApiService();
        final response = await apiService.submitReview(reviewRequest);

        Navigator.pop(context); // Close loading dialog

        if (response.success) {
          // Mark the test drive as reviewed in local storage
          try {
            await _storageService.markTestDriveAsReviewed(widget.testDrive!.id);
            
            // Force refresh profile data
            await UserProfileScreen.forceRefreshProfileData();
          } catch (e) {
            print('Error marking test drive as reviewed: $e');
            // Continue even if storage fails - don't block the success flow
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message ?? 'Review submitted successfully'
              ),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to submit review'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an overall rating'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRatingSection(
    String title,
    double rating,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF0095D9),
                  inactiveTrackColor: Colors.grey[200],
                  thumbColor: const Color(0xFF0095D9),
                  overlayColor: const Color(0xFF0095D9).withOpacity(0.1),
                  valueIndicatorColor: const Color(0xFF0095D9),
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Slider(
                  value: rating,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: _getRatingLabel(rating),
                  onChanged: onChanged,
                ),
              ),
            ),
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: rating > 0
                    ? const Color(0xFF0095D9).withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getRatingLabel(rating),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: rating > 0
                      ? const Color(0xFF0095D9)
                      : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Review Test Drive',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car and Showroom Info
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
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car_outlined,
                            color: Color(0xFF0095D9),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.carName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF0095D9),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.showroom,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Overall Rating
                _buildRatingSection(
                  'Overall Experience',
                  _overallRating,
                  (value) => setState(() => _overallRating = value),
                ),
                const SizedBox(height: 24),
                // Comfort Rating
                _buildRatingSection(
                  'Comfort & Interior',
                  _comfortRating,
                  (value) => setState(() => _comfortRating = value),
                ),
                const SizedBox(height: 24),
                // Performance Rating
                _buildRatingSection(
                  'Performance & Handling',
                  _performanceRating,
                  (value) => setState(() => _performanceRating = value),
                ),
                const SizedBox(height: 24),
                // Value Rating
                _buildRatingSection(
                  'Value for Money',
                  _valueRating,
                  (value) => setState(() => _valueRating = value),
                ),
                const SizedBox(height: 24),
                // Would Recommend
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.thumb_up_outlined,
                        color: Color(0xFF0095D9),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Would you recommend this car?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Switch(
                        value: _wouldRecommend,
                        onChanged: (value) =>
                            setState(() => _wouldRecommend = value),
                        activeColor: const Color(0xFF0095D9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Comments
                TextFormField(
                  controller: _commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Additional Comments',
                    hintText: 'Share your experience with this car...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0095D9)),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.length > 500) {
                      return 'Comments cannot exceed 500 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0095D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit Review',
                      style: TextStyle(
                        fontSize: 16,
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
    );
  }
} 