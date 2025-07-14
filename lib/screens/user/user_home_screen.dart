import 'package:flutter/material.dart';
import 'rescheduled_test_drives_screen.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart' as api;
import '../../services/api_config.dart';
import '../../models/showroom_model.dart';
import '../../main.dart';
import 'cancel_test_drive_screen.dart';
import 'cars_screen.dart';
import 'notification_screen.dart';
import 'user_profile_screen.dart';
import 'search_screen.dart';
import 'showrooms_screen.dart';
import 'pending_test_drives_screen.dart';
import 'approved_test_drives_screen.dart';
import 'user_activities_screen.dart';
import '../../models/activity_log_model.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  final StorageService _storageService = StorageService();
  final api.ApiService _apiService = api.ApiService();
  
  List<Showroom> _showrooms = [];
  Map<int, int> _carCounts = {}; // Store car counts for each showroom
  bool _isLoadingShowrooms = true;
  String? _showroomsErrorMessage;
  
  // Recent activities variables
  List<ActivityLog> _recentActivities = [];
  bool _isLoadingActivities = true;
  String? _activityError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchShowrooms();
    _loadRecentActivities();
  }
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  Future<void> _fetchShowrooms() async {
    setState(() {
      _isLoadingShowrooms = true;
      _showroomsErrorMessage = null;
    });

    try {
      // Get current user to check their showroom_id
      final currentUser = await _storageService.getUser();
      if (currentUser == null) {
        setState(() {
          _showroomsErrorMessage = 'User not found. Please login again.';
          _isLoadingShowrooms = false;
        });
        return;
      }

      final response = await _apiService.getShowrooms();
      
      if (response.success) {
        // Filter showrooms to only show the one that matches user's showroom_id
        final allShowrooms = response.data ?? [];
        final filteredShowrooms = allShowrooms.where((showroom) => 
          showroom.id == currentUser.showroomId
        ).toList();
        
        setState(() {
          _showrooms = filteredShowrooms;
          _isLoadingShowrooms = false;
        });
        
        // Fetch car counts for each showroom
        _fetchCarCounts();
      } else {
        setState(() {
          _showroomsErrorMessage = response.message;
          _isLoadingShowrooms = false;
        });
      }
    } catch (e) {
      setState(() {
        _showroomsErrorMessage = 'An unexpected error occurred';
        _isLoadingShowrooms = false;
      });
    }
  }

  Future<void> _fetchCarCounts() async {
    for (final showroom in _showrooms) {
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

  Future<void> _loadRecentActivities() async {
    setState(() {
      _isLoadingActivities = true;
      _activityError = null;
    });
    
    try {
      final currentUser = await _storageService.getUser();
      if (currentUser == null) {
        setState(() {
          _activityError = 'User not found. Please login again.';
          _isLoadingActivities = false;
        });
        return;
      }

      debugPrint('Loading recent activities for user ID: ${currentUser.id}');
      final response = await _apiService.getRecentActivities(
        userId: currentUser.id,
        userType: 'users',
      );
      
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
          if (response.success) {
            _recentActivities = response.data?.data ?? [];
            debugPrint('Loaded ${_recentActivities.length} activities');
          } else {
            _activityError = response.message;
            debugPrint('Failed to load activities: ${response.message}');
          }
        });
      }
    } catch (e) {
      debugPrint('Exception loading activities: $e');
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
          _activityError = 'Failed to load activities';
        });
      }
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      // Clear profile cache
      UserProfileScreen.clearCache();
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Clear all stored data
      await _storageService.clearAllData();
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Logged out successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Navigate to auth screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Logout failed: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.blue,
                letterSpacing: 0.2,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_car_rounded,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Varenyam',
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          _buildTopBarIcon(
            Icons.notifications_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _buildTopBarIcon(
            Icons.person_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(showBackButton: true),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchShowrooms,
        color: const Color(0xFF0095D9),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Showrooms Section
              _buildSectionHeader(
                'My Showroom',
                'Your assigned showroom',
              ),
              Container(
                height: 220, // Reduced from 260
                child: _buildShowroomsContent(),
              ),
              // Quick Actions Section
              _buildSectionHeader(
                'Quick Actions',
                'Manage your test drive requests and reviews',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8, // Reduced from 12
                    crossAxisSpacing: 8, // Reduced from 12
                    childAspectRatio: 1.2, // Increased from 1.1 to make cards shorter
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final actions = [
                      {
                        'title': 'Pending Test Drive',
                        'icon': Icons.pending_actions_outlined,
                        'color': Colors.orange,
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PendingTestDrivesScreen(),
                            ),
                          );
                        },
                      },
                      {
                        'title': 'Rescheduled Test Drive',
                        'icon': Icons.schedule,
                        'color': Colors.orange,
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RescheduledTestDrivesScreen(),
                            ),
                          );
                        },
                      },
                      {
                        'title': 'Rejected Test Drive',
                        'icon': Icons.cancel_outlined,
                        'color': Colors.red,
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CancelTestDriveScreen(),
                            ),
                          );
                        },
                      },
                      {
                        'title': 'Approved Test Drive',
                        'icon': Icons.check_circle_outline,
                        'color': Colors.green,
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApprovedTestDrivesScreen(),
                            ),
                          );
                        },
                      },
                    ];
                    final action = actions[index];
                    return SizedBox(
                      height: 80, // Reduced from 100
                      child: _buildActionCard(
                        action['title'] as String,
                        action['icon'] as IconData,
                        action['color'] as Color,
                        action['onTap'] as VoidCallback,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16), // Reduced from 24
              
              // Recent Activities Section
              _buildSectionHeader(
                'Recent Activity',
                'Your recent system activities',
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserActivitiesScreen(showBackButton: true),
                    ),
                  );
                },
              ),
              _buildRecentActivity(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle,
      {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), // Reduced top from 24, bottom from 16
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18, // Reduced from 20
                          decoration: BoxDecoration(
                            color: const Color(0xFF0095D9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18, // Reduced from 20
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2), // Reduced from 4
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13, // Reduced from 14
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF757575),
                        letterSpacing: 0.2,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onViewAll != null) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0095D9).withOpacity(0.9),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: const Color(0xFF0095D9).withOpacity(0.9),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Reduced from 12, 8
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced from 8
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20, // Reduced from 24
                  color: color,
                ),
              ),
              const SizedBox(height: 6), // Reduced from 8
              Text(
                title,
                style: TextStyle(
                  fontSize: 12, // Reduced from 13
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: const Color(0xFF0095D9),
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF757575),
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildShowroomsContent() {
    if (_isLoadingShowrooms) {
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
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_showroomsErrorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              _showroomsErrorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchShowrooms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0095D9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_showrooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            const Text(
              'No showroom assigned',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please contact your administrator to assign a showroom',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildShowroomCard(_showrooms.first),
    );
  }

  Widget _buildShowroomCard(Showroom showroom) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 240, // Reduced from 300
        child: Column(
          children: [
            // Top image section with overlay
            Container(
              height: 100, // Reduced from 120
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  // Showroom image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: showroom.showroomImage != null
                        ? Image.network(
                            '${ApiConfig.baseUrl}/${showroom.showroomImage!}',
                            width: double.infinity,
                            height: 100, // Reduced from 120
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 100, // Reduced from 120
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF0095D9).withOpacity(0.8),
                                      const Color(0xFF0095D9).withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 100, // Reduced from 120
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF0095D9).withOpacity(0.8),
                                      const Color(0xFF0095D9).withOpacity(0.6),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            height: 100, // Reduced from 120
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF0095D9).withOpacity(0.8),
                                  const Color(0xFF0095D9).withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                  ),
                  // Gradient overlay for better text readability
                  Container(
                    width: double.infinity,
                    height: 100, // Reduced from 120
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Showroom name overlay
                  Positioned(
                    bottom: 10, // Reduced from 12
                    left: 16,
                    right: 16,
                    child: Text(
                      showroom.name,
                      style: const TextStyle(
                        fontSize: 16, // Reduced from 18
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    top: 10, // Reduced from 12
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced from 10, 6
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFF0095D9),
                            size: 12, // Reduced from 14
                          ),
                          const SizedBox(width: 3), // Reduced from 4
                          Text(
                            showroom.ratting.toString(),
                            style: const TextStyle(
                              color: Color(0xFF0095D9),
                              fontSize: 12, // Reduced from 13
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10), // Reduced from 12
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12, // Reduced from 14
                          color: Color(0xFF0095D9),
                        ),
                        const SizedBox(width: 3), // Reduced from 4
                        Expanded(
                          child: Text(
                            showroom.locationDisplay,
                            style: const TextStyle(
                              fontSize: 12, // Reduced from 13
                              color: Color(0xFF757575),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), // Reduced from 6
                    // Available cars info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3), // Reduced from 4
                          decoration: BoxDecoration(
                            color: const Color(0xFF0095D9).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            size: 12, // Reduced from 14
                            color: Color(0xFF0095D9),
                          ),
                        ),
                        const SizedBox(width: 4), // Reduced from 6
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Available Cars',
                                style: TextStyle(
                                  fontSize: 10, // Reduced from 11
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // const SizedBox(width: 4),
                              Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), // Reduced from 8, 2
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0095D9).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF0095D9).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _carCounts[showroom.id]?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 11, // Reduced from 12
                                    color: Color(0xFF0095D9),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // Reduced from 20
                    // const Spacer(),
                    // Book button
                    SizedBox(
                      width: double.infinity,
                      height: 36, // Reduced from 40
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CarsScreen(
                                showroomName: showroom.name,
                                availableCars: [],
                                showroomLocation: showroom.locationDisplay,
                                showroomRating: showroom.ratting.toString(),
                                showroomDistance: 'N/A',
                                showroomId: showroom.id,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095D9),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Book Test Drive',
                          style: TextStyle(
                            fontSize: 12, // Reduced from 13
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
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
    );
  }

  Widget _buildPromoBanner(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Handle banner tap
          },
          borderRadius: BorderRadius.circular(12),
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
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color.withOpacity(0.9),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Learn More',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarIcon(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.grey[700],
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isLoadingActivities)
            Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF0095D9)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading activities...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_activityError != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[400],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unable to load activities: $_activityError',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_isLoadingActivities && _activityError == null)
            _recentActivities.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No recent activities',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: _recentActivities.take(3).map((activity) {
                    return _buildProfessionalActivityItem(
                      activity,
                      activity != _recentActivities.take(3).last,
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildProfessionalActivityItem(ActivityLog activity, bool showDivider) {
    final color = _getActivityColor(activity);
    final icon = _getActivityIcon(activity);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 14,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Activity Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Title and Time in same row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatActivityTitle(activity.operation),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatActivityTime(activity.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 3),
                    
                    // Activity Description
                    Text(
                      activity.operationDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Divider
        if (showDivider)
          Container(
            margin: const EdgeInsets.only(left: 40),
            height: 1,
            color: Colors.grey.withOpacity(0.08),
          ),
      ],
    );
  }

  String _formatActivityTitle(String operation) {
    switch (operation.toLowerCase()) {
      case 'testdrive status update':
        return 'Test Drive Status Updated';
      case 'request for testdrive':
        return 'Test Drive Request';
      case 'expense submitted':
        return 'Expense Submitted';
      case 'expense approved':
        return 'Expense Approved';
      case 'expense rejected':
        return 'Expense Rejected';
      default:
        return operation.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  String _formatActivityTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    if (dateTime.year == now.year) {
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    } else {
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    }
  }

  IconData _getActivityIcon(ActivityLog activity) {
    if (activity.tableName == 'expenses') return Icons.receipt_outlined;
    if (activity.operation.toLowerCase().contains('cancelled') || 
        activity.operationDescription.toLowerCase().contains('cancelled')) return Icons.cancel_outlined;
    if (activity.operation.toLowerCase().contains('completed') || 
        activity.operationDescription.toLowerCase().contains('completed')) return Icons.check_circle_outline;
    if (activity.operation.toLowerCase().contains('rescheduled') || 
        activity.operationDescription.toLowerCase().contains('rescheduled')) return Icons.schedule_outlined;
    if (activity.operation.toLowerCase().contains('request for testdrive') || 
        activity.operationDescription.toLowerCase().contains('testdrive request')) return Icons.directions_car_outlined;
    if (activity.operation.toLowerCase().contains('status update')) return Icons.update_outlined;
    return Icons.info_outline;
  }

  Color _getActivityColor(ActivityLog activity) {
    if (activity.tableName == 'expenses') return Colors.blue;
    if (activity.operation.toLowerCase().contains('cancelled') || 
        activity.operationDescription.toLowerCase().contains('cancelled')) return Colors.red;
    if (activity.operation.toLowerCase().contains('completed') || 
        activity.operationDescription.toLowerCase().contains('completed')) return Colors.green;
    if (activity.operation.toLowerCase().contains('rescheduled') || 
        activity.operationDescription.toLowerCase().contains('rescheduled')) return Colors.orange;
    if (activity.operation.toLowerCase().contains('request for testdrive') || 
        activity.operationDescription.toLowerCase().contains('testdrive request')) return Colors.purple;
    if (activity.operation.toLowerCase().contains('status update')) return Colors.indigo;
    return Colors.grey;
  }
}
