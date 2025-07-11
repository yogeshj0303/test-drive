import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../models/showroom_model.dart';
import '../../main.dart';
import 'personal_info_screen.dart';
import 'change_password_screen.dart';
import 'about_screen.dart';
import 'completed_test_drives_screen.dart';
import 'user_expense_screen.dart';
import 'test_drive_status_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final bool showBackButton;
  
  const UserProfileScreen({
    Key? key,
    this.showBackButton = true,
  }) : super(key: key);

  // Static cache to store user data across instances
  static User? _cachedUser;
  static int _cachedTestDriveCount = 0;
  static int _cachedCompletedTestDriveCount = 0;
  static Showroom? _cachedShowroom;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  static List<Function()> _refreshCallbacks = [];

  // Method to clear cache (call this when user data is updated)
  static void clearCache() {
    _cachedUser = null;
    _cachedTestDriveCount = 0;
    _cachedCompletedTestDriveCount = 0;
    _cachedShowroom = null;
    _lastCacheTime = null;
  }

  // Getter methods to access cached data
  static User? get cachedUser => _cachedUser;
  static int get cachedTestDriveCount => _cachedTestDriveCount;
  static int get cachedCompletedTestDriveCount => _cachedCompletedTestDriveCount;
  static Showroom? get cachedShowroom => _cachedShowroom;
  static DateTime? get lastCacheTime => _lastCacheTime;
  static Duration get cacheValidDuration => _cacheValidDuration;

  // Method to update cache
  static void updateCache(User user, int testDriveCount, int completedTestDriveCount, [Showroom? showroom]) {
    _cachedUser = user;
    _cachedTestDriveCount = testDriveCount;
    _cachedCompletedTestDriveCount = completedTestDriveCount;
    _cachedShowroom = showroom;
    _lastCacheTime = DateTime.now();
    
    // Notify all active profile screens to refresh
    for (final callback in _refreshCallbacks) {
      callback();
    }
  }

  // Method to register refresh callback
  static void registerRefreshCallback(Function() callback) {
    _refreshCallbacks.add(callback);
  }

  // Method to unregister refresh callback
  static void unregisterRefreshCallback(Function() callback) {
    _refreshCallbacks.remove(callback);
  }

  // Static method to force refresh profile data
  static Future<void> forceRefreshProfileData() async {
    try {
      final storageService = StorageService();
      final currentUser = await storageService.getUser();
      if (currentUser != null) {
        final apiService = ApiService();
        final testDrivesResponse = await apiService.getUserTestDrives(currentUser.id);
        
        final testDriveCount = testDrivesResponse.success ? testDrivesResponse.data!.length : 0;
        final completedTestDriveCount = testDrivesResponse.success 
            ? testDrivesResponse.data!.where((testDrive) => 
                testDrive.status?.toLowerCase() == 'completed').length 
            : 0;
        
        // Update cache with new counts
        if (_cachedUser != null) {
          updateCache(_cachedUser!, testDriveCount, completedTestDriveCount, _cachedShowroom);
        }
      }
      
    } catch (e) {
      print('Error forcing profile refresh: $e');
    }
  }

  // Static method to force refresh showroom data
  static Future<void> forceRefreshShowroomData() async {
    try {
      if (_cachedUser != null) {
        final apiService = ApiService();
        Showroom? showroom;
        
        try {
          final showroomResponse = await apiService.getShowroomById(_cachedUser!.showroomId);
          if (showroomResponse.success && showroomResponse.data != null) {
            showroom = showroomResponse.data;
          } else {
            // Fallback: get all showrooms and find the matching one
            final allShowroomsResponse = await apiService.getShowrooms();
            if (allShowroomsResponse.success && allShowroomsResponse.data != null) {
              showroom = allShowroomsResponse.data!.firstWhere(
                (s) => s.id == _cachedUser!.showroomId,
                orElse: () => Showroom(
                  id: 0,
                  authId: 0,
                  name: '',
                  address: '',
                  city: '',
                  state: '',
                  district: '',
                  pincode: '',
                  ratting: 0,
                  createdAt: '',
                  updatedAt: '',
                ),
              );
            }
          }
        } catch (e) {
          print('Error fetching showroom details: $e');
        }
        
        if (showroom != null) {
          updateCache(_cachedUser!, _cachedTestDriveCount, _cachedCompletedTestDriveCount, showroom);
        }
      }
    } catch (e) {
      print('Error forcing showroom refresh: $e');
    }
  }

  @override
  State<UserProfileScreen> createState() => UserProfileScreenState();
}

class UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDarkMode = false;
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  User? _user;
  Showroom? _showroom;
  bool _isLoading = true;
  String? _errorMessage;
  int _testDriveCount = 0;
  int _completedTestDriveCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    
    // Register refresh callback
    UserProfileScreen.registerRefreshCallback(_refreshProfileData);
    
    _loadUserProfile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh data when app becomes active
      _refreshProfileData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes active (but only once)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isLoading) {
        _refreshProfileData();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    // Check if we have valid cached data
    if (UserProfileScreen.cachedUser != null && UserProfileScreen.lastCacheTime != null) {
      final timeSinceLastCache = DateTime.now().difference(UserProfileScreen.lastCacheTime!);
      if (timeSinceLastCache < UserProfileScreen.cacheValidDuration) {
        setState(() {
          _user = UserProfileScreen.cachedUser;
          _showroom = UserProfileScreen.cachedShowroom;
          _testDriveCount = UserProfileScreen.cachedTestDriveCount;
          _completedTestDriveCount = UserProfileScreen.cachedCompletedTestDriveCount;
          _isLoading = false;
        });
        
        // If showroom data is missing from cache, try to fetch it separately
        if (_showroom == null && UserProfileScreen.cachedUser != null) {
          _fetchShowroomData(UserProfileScreen.cachedUser!.showroomId);
        }
        
        return;
      }
    }

    try {
      final currentUser = await _storageService.getUser();
      if (currentUser != null) {
        // Load user profile, test drive count, and showroom details in parallel
        final profileResponse = await _apiService.getUserProfile(currentUser.id);
        final testDrivesResponse = await _apiService.getUserTestDrives(currentUser.id);
        
        // Try to get showroom details - first try individual showroom, then fallback to all showrooms
        Showroom? showroom;
        try {
          print('Debug: Fetching showroom for ID: ${currentUser.showroomId}');
          final showroomResponse = await _apiService.getShowroomById(currentUser.showroomId);
          print('Debug: Individual showroom response: ${showroomResponse.success}');
          if (showroomResponse.success && showroomResponse.data != null) {
            showroom = showroomResponse.data;
            print('Debug: Found showroom via individual API: ${showroom!.name}');
          } else {
            print('Debug: Individual showroom API failed, trying all showrooms');
            // Fallback: get all showrooms and find the matching one
            final allShowroomsResponse = await _apiService.getShowrooms();
            print('Debug: All showrooms response: ${allShowroomsResponse.success}');
            if (allShowroomsResponse.success && allShowroomsResponse.data != null) {
              print('Debug: Found ${allShowroomsResponse.data!.length} showrooms');
              showroom = allShowroomsResponse.data!.firstWhere(
                (s) => s.id == currentUser.showroomId,
                orElse: () {
                  print('Debug: No matching showroom found for ID: ${currentUser.showroomId}');
                  return Showroom(
                    id: 0,
                    authId: 0,
                    name: '',
                    address: '',
                    city: '',
                    state: '',
                    district: '',
                    pincode: '',
                    ratting: 0,
                    createdAt: '',
                    updatedAt: '',
                  );
                },
              );
              print('Debug: Found showroom via all showrooms: ${showroom.name}');
            }
          }
        } catch (e) {
          print('Error fetching showroom details: $e');
        }
        
        if (profileResponse.success && profileResponse.data != null) {
          final testDriveCount = testDrivesResponse.success ? testDrivesResponse.data!.length : 0;
          
          // Filter completed test drives from the main response
          final completedTestDriveCount = testDrivesResponse.success 
              ? testDrivesResponse.data!.where((testDrive) => 
                  testDrive.status?.toLowerCase() == 'completed').length 
              : 0;
          
          // Cache the data
          UserProfileScreen.updateCache(
            profileResponse.data!,
            testDriveCount,
            completedTestDriveCount,
            showroom
          );
          
          setState(() {
            _user = profileResponse.data;
            _showroom = showroom;
            _testDriveCount = testDriveCount;
            _completedTestDriveCount = completedTestDriveCount;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = profileResponse.message;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No user data found';
          _isLoading = false;
        });
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Method to refresh data and update cache
  Future<void> _refreshProfile() async {
    // Clear cache to force fresh data
    UserProfileScreen.clearCache();
    await _loadUserProfile();
  }

  // Method to fetch showroom data separately
  Future<void> _fetchShowroomData(int showroomId) async {
    try {
      Showroom? showroom;
      try {
        final showroomResponse = await _apiService.getShowroomById(showroomId);
        if (showroomResponse.success && showroomResponse.data != null) {
          showroom = showroomResponse.data;
        } else {
          // Fallback: get all showrooms and find the matching one
          final allShowroomsResponse = await _apiService.getShowrooms();
          if (allShowroomsResponse.success && allShowroomsResponse.data != null) {
            showroom = allShowroomsResponse.data!.firstWhere(
              (s) => s.id == showroomId,
              orElse: () => Showroom(
                id: 0,
                authId: 0,
                name: '',
                address: '',
                city: '',
                state: '',
                district: '',
                pincode: '',
                ratting: 0,
                createdAt: '',
                updatedAt: '',
              ),
            );
          }
        }
      } catch (e) {
        print('Error fetching showroom details: $e');
      }
      
      if (showroom != null && mounted) {
        setState(() {
          _showroom = showroom;
        });
        
        // Update cache with showroom data
        if (UserProfileScreen.cachedUser != null) {
          UserProfileScreen.updateCache(
            UserProfileScreen.cachedUser!,
            UserProfileScreen.cachedTestDriveCount,
            UserProfileScreen.cachedCompletedTestDriveCount,
            showroom,
          );
        }
      }
    } catch (e) {
      print('Error fetching showroom data: $e');
    }
  }

  // Method to refresh profile data without clearing cache (for real-time updates)
  Future<void> _refreshProfileData() async {
    try {
      final currentUser = await _storageService.getUser();
      if (currentUser != null) {
        // Only refresh the counts, not the entire profile
        final testDrivesResponse = await _apiService.getUserTestDrives(currentUser.id);
        
        final testDriveCount = testDrivesResponse.success ? testDrivesResponse.data!.length : 0;
        
        // Filter completed test drives from the main response
        final completedTestDriveCount = testDrivesResponse.success 
            ? testDrivesResponse.data!.where((testDrive) => 
                testDrive.status?.toLowerCase() == 'completed').length 
            : 0;
        
        // Update cache with new counts
        if (UserProfileScreen.cachedUser != null) {
          UserProfileScreen.updateCache(
            UserProfileScreen.cachedUser!,
            testDriveCount,
            completedTestDriveCount,
            UserProfileScreen.cachedShowroom,
          );
        }
        
        // Update UI if counts have changed
        if (mounted && (_testDriveCount != testDriveCount || _completedTestDriveCount != completedTestDriveCount)) {
          setState(() {
            _testDriveCount = testDriveCount;
            _completedTestDriveCount = completedTestDriveCount;
          });
        }
      }
      
    } catch (e) {
      // Silently handle errors to avoid disrupting the UI
      print('Error refreshing profile data: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    
    // Unregister refresh callback
    UserProfileScreen.unregisterRefreshCallback(_refreshProfileData);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Loading profile...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Error Loading Profile',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingM),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _refreshProfile();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No user data available',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: size.height * 0.28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          right: -size.width * 0.1,
                          top: -size.width * 0.1,
                          child: Container(
                            width: size.width * 0.8,
                            height: size.width * 0.8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: AppTheme.spacingM,
                    right: AppTheme.spacingM,
                    top: size.height * 0.08,
                    child: _buildProfileHeader(context),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: size.height * 0.12,
                  left: AppTheme.spacingM,
                  right: AppTheme.spacingM,
                  bottom: AppTheme.spacingM,
                ),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingXS),
                              Text(
                                'Activity',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatsSection(context),
                        const SizedBox(height: AppTheme.spacingL),
                        Container(
                          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingXS),
                              Text(
                                'Settings',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildSettingsSection(context),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildLogoutButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showBackButton)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 40), // Placeholder to maintain spacing
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _user?.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _user!.avatarUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.fill,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 50,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                      ),
                      const SizedBox(width: 40), // Placeholder to maintain spacing
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                _user!.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                _user!.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: AppTheme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primaryContainer,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      _getLocationDisplay(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
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

  Widget _buildStatsSection(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: AppTheme.spacingXS,
      crossAxisSpacing: AppTheme.spacingXS,
      childAspectRatio: 0.9,
      padding: EdgeInsets.zero,
      children: [
        _buildStatCard(
          context,
          'Test Drives',
          '$_testDriveCount',
          Icons.directions_car_outlined,
          theme.colorScheme.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TestDriveStatusScreen(),
              ),
            );
          },
        ),
        _buildStatCard(
          context,
          'Completed',
          '$_completedTestDriveCount',
          Icons.check_circle_outline,
          Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CompletedTestDrivesScreen(),
              ),
            );
          },
        ),
        _buildStatCard(
          context,
          'Member Since',
          _formatMemberSinceDate(),
          Icons.calendar_today_outlined,
          AppTheme.successColor,
        ),
      ],
    );
  }

  String _formatMemberSinceDate() {
    if (_user?.createdAt == null) {
      return 'Not available';
    }
    
    try {
      final date = _user!.createdAt!;
      
      // Format as "Jun 17, 2025"
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      final monthName = months[date.month - 1];
      final day = date.day;
      final year = date.year;
      
      return '$monthName $day, $year';
    } catch (e) {
      return 'Not available';
    }
  }

  String _getLocationDisplay() {
    if (_showroom == null) {
      return 'Not specified';
    }
    
    // Use the showroom's locationDisplay method if available, otherwise format manually
    if (_showroom!.city.isNotEmpty && _showroom!.state.isNotEmpty) {
      return '${_showroom!.city}, ${_showroom!.state}';
    } else if (_showroom!.city.isNotEmpty) {
      return _showroom!.city;
    } else if (_showroom!.state.isNotEmpty) {
      return _showroom!.state;
    } else {
      return 'Not specified';
    }
  }



  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    {VoidCallback? onTap}
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final theme = Theme.of(context);
    final settingsGroups = [
      {
        'title': 'Account',
        'items': [
          {
            'icon': Icons.person_outline,
            'title': 'Personal Information',
            'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalInfoScreen(),
                  ),
                ),
          },
          {
            'icon': Icons.lock_outline,
            'title': 'Change Password',
            'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                ),
          },
        ],
      },
      {
        'title': 'Test Drives',
        'items': [
          {
            'icon': Icons.check_circle_outline,
            'title': 'Completed Test Drives',
            'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CompletedTestDrivesScreen(),
                  ),
                ),
          },
        ],
      },
      {
        'title': 'Expenses',
        'items': [
          {
            'icon': Icons.receipt_long_outlined,
            'title': 'Manage Expenses',
            'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserExpenseScreen(),
                  ),
                ),
          },
        ],
      },
      {
        'title': 'Support',
        'items': [
          {
            'icon': Icons.help_outline,
            'title': 'Help & Support',
            'onTap': () {},
          },
          {
            'icon': Icons.info_outline,
            'title': 'About',
            'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                ),
          },
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: settingsGroups.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.spacingXS,
                bottom: AppTheme.spacingXS,
              ),
              child: Text(
                group['title'] as String,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...(group['items'] as List).map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingXS),
                child: Card(
                  color: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    selectedColor: Colors.transparent,
                    selectedTileColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    splashColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingXS,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      item['title'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        letterSpacing: 0.2,
                      ),
                    ),
                    trailing: item['trailing'] ??
                        (item['onTap'] != null
                            ? Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              )
                            : null),
                    onTap: item['onTap'] as VoidCallback?,
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: AppTheme.spacingM),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'Version 1.0.0',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.error,
                theme.colorScheme.error.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.error.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showLogoutDialog(context),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.logout,
                      color: theme.colorScheme.onError,
                      size: 18,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      'Logout',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onError,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Logout',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: theme.textTheme.bodyLarge?.copyWith(
            letterSpacing: 0.2,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.primary,
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
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingXS,
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      // Clear profile cache
      UserProfileScreen.clearCache();
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Center(
            child: CircularProgressIndicator(),
          ),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Expose this method for parent to call
  void refreshProfileData() {
    _refreshProfileData();
  }

  // Expose this method for parent to call
  void refreshShowroomData() {
    if (UserProfileScreen.cachedUser != null) {
      _fetchShowroomData(UserProfileScreen.cachedUser!.showroomId);
    }
  }
}
