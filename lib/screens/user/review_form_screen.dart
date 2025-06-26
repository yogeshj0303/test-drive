import 'package:flutter/material.dart';
import '../../models/test_drive_model.dart';
import '../../models/review_model.dart' as review;
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class ReviewFormScreen extends StatefulWidget {
  final TestDriveListResponse? testDrive;

  const ReviewFormScreen({super.key, this.testDrive});

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  // Mock data for test drive requests
  final List<Map<String, dynamic>> _testDriveRequests = [
    {
      'id': 'TD001',
      'carName': 'Tata Nexon EV',
      'showroom': 'Tata Motors, Andheri East',
      'date': '2024-03-25',
      'time': '14:00',
      'status': 'completed',
      'duration': '30 mins',
      'hasReview': false,
    },
    {
      'id': 'TD002',
      'carName': 'Mahindra XUV700',
      'showroom': 'Mahindra Auto, Powai',
      'date': '2024-03-28',
      'time': '11:30',
      'status': 'completed',
      'duration': '45 mins',
      'hasReview': true,
    },
    {
      'id': 'TD003',
      'carName': 'Hyundai Creta',
      'showroom': 'Hyundai Motors, Vikhroli',
      'date': '2024-03-20',
      'time': '15:30',
      'status': 'completed',
      'duration': '30 mins',
      'hasReview': false,
    },
  ];

  void _showReviewForm(Map<String, dynamic> request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ReviewFormContent(
          carName: request['carName'],
          showroom: request['showroom'],
          testDrive: null, // For mock data, we don't have a test drive object
        ),
      ),
    ).then((_) {
      // Refresh the list after review submission
      setState(() {
        request['hasReview'] = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // If a test drive is provided, show the review form directly
    if (widget.testDrive != null) {
      return _ReviewFormContent(
        carName: widget.testDrive!.car.name,
        showroom: widget.testDrive!.showroom.name,
        testDrive: widget.testDrive,
      );
    }

    // Filter only completed test drives
    final completedTestDrives = _testDriveRequests
        .where((request) => request['status'] == 'completed')
        .toList();

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
      body: completedTestDrives.isEmpty
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
              itemCount: completedTestDrives.length,
              itemBuilder: (context, index) {
                final request = completedTestDrives[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: InkWell(
                    onTap: request['hasReview']
                        ? null
                        : () => _showReviewForm(request),
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
                                      request['carName'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      request['showroom'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (request['hasReview'])
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
                                  request['date'],
                                  Icons.calendar_today_outlined,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Time',
                                  request['time'],
                                  Icons.access_time_rounded,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Duration',
                                  request['duration'],
                                  Icons.timer_outlined,
                                ),
                              ),
                            ],
                          ),
                          if (!request['hasReview']) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0095D9).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Tap to Leave a Review',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0095D9),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

        // Get test drive ID from the passed test drive or use a default
        int testDriveId = 3; // Default fallback
        if (widget.testDrive != null) {
          testDriveId = widget.testDrive!.id;
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
          testDriveId: testDriveId,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Review submitted successfully'),
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