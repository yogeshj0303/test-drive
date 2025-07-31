import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'personal_info_screen.dart';
import 'about_screen.dart';
import 'change_password_screen.dart';
import 'employee_login_screen.dart';
import '../../services/employee_storage_service.dart';
import '../../services/driver_api_service.dart';
import '../../models/employee_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/logout_utils.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final bool showBackButton;
  
  const EmployeeProfileScreen({
    super.key,
    this.showBackButton = false,
  });

  // Static cache to store employee data across instances
  static Employee? _cachedEmployee;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Method to clear cache (call this when employee data is updated)
  static void clearCache() {
    _cachedEmployee = null;
    _lastCacheTime = null;
  }

  // Getter methods to access cached data
  static Employee? get cachedEmployee => _cachedEmployee;
  static DateTime? get lastCacheTime => _lastCacheTime;
  static Duration get cacheValidDuration => _cacheValidDuration;

  // Method to update cache
  static void updateCache(Employee employee) {
    _cachedEmployee = employee;
    _lastCacheTime = DateTime.now();
  }

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Employee? _employee;
  // PerformanceCountData? _performanceData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFetching = false; // Add a flag to prevent concurrent fetches
  DateTime? _lastFetchTime; // Track last fetch time
  static const Duration _minRefreshInterval = Duration(seconds: 2); // Prevent rapid repeat fetches
  // bool _isLoadingPerformance = true;

  @override
  void initState() {
    super.initState();
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
    
    _loadEmployeeProfile();
  }

  Future<void> _loadEmployeeProfile({bool forceRefresh = false}) async {
    if (_isFetching) return; // Prevent concurrent fetches
    _isFetching = true;
    // Only clear cache if forced or cache expired
    if (forceRefresh) EmployeeProfileScreen.clearCache();
    // Check if we have valid cached data
    if (!forceRefresh && EmployeeProfileScreen.cachedEmployee != null && EmployeeProfileScreen.lastCacheTime != null) {
      final timeSinceLastCache = DateTime.now().difference(EmployeeProfileScreen.lastCacheTime!);
      if (timeSinceLastCache < EmployeeProfileScreen.cacheValidDuration) {
        setState(() {
          _employee = EmployeeProfileScreen.cachedEmployee;
          _isLoading = false;
        });
        _isFetching = false;
        return;
      }
    }
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final employee = await EmployeeStorageService.getEmployeeData();
      if (employee != null) {
        final apiResponse = await EmployeeApiService().getProfile(employee.id);
        if (apiResponse.success && apiResponse.data != null) {
          EmployeeProfileScreen.updateCache(apiResponse.data!.user);
          setState(() {
            _employee = EmployeeProfileScreen.cachedEmployee;
            _isLoading = false;
          });
        } else {
          setState(() {
            _employee = employee;
            _isLoading = false;
            _errorMessage = apiResponse.message;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No employee data found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile:  [38;5;9m${e.toString()} [0m';
      });
    } finally {
      _isFetching = false;
      _lastFetchTime = DateTime.now();
    }
  }

  // Future<void> _loadPerformanceData(int driverId) async {
  //   setState(() {
  //     _isLoadingPerformance = true;
  //   });

  //   try {
  //     final response = await EmployeeApiService().getPerformanceCount(driverId);
      
  //     if (mounted) {
  //       setState(() {
  //         _isLoadingPerformance = false;
  //         if (response.success) {
  //           _performanceData = response.data!.data;
  //         } else {
  //           // Handle error - keep default values
  //           _performanceData = PerformanceCountData(
  //             totalTestdrives: 0,
  //             pendingTestdrives: 0,
  //             thisMonthTestdrives: 0,
  //           );
  //         }
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         _isLoadingPerformance = false;
  //         // Set default values on error
  //         _performanceData = PerformanceCountData(
  //           totalTestdrives: 0,
  //           pendingTestdrives: 0,
  //           thisMonthTestdrives: 0,
  //         );
  //       });
  //     }
  //   }
  // }

  Future<void> _refreshProfile() async {
    // Only refresh if not already loading/fetching
    if (_isFetching) return;
    await _loadEmployeeProfile(forceRefresh: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading profile...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null && _employee == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error Loading Profile',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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

    if (_employee == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No employee data available',
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
                    height: size.height * 0.22,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF3080A5),
                          const Color(0xFF3080A5).withOpacity(0.8),
                          const Color(0xFF3080A5).withOpacity(0.6),
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
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: size.height * 0.06,
                    child: _buildProfileHeader(context),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: size.height * 0.12,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) _buildErrorMessage(_errorMessage!),
                        if (_employee?.documents.isNotEmpty == true) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Documents',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildDocumentsSection(context),
                          const SizedBox(height: 16),
                        ],
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
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
                        const SizedBox(height: 16),
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
      constraints: const BoxConstraints(maxWidth: 280),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image Container
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                    ),
                    child: _employee?.avatarUrl != null
                      ? Image.network(
                          _employee!.avatarUrl!,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: theme.colorScheme.primary,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: theme.colorScheme.onPrimary,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 80,
                              height: 80,
                              color: theme.colorScheme.primary,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: theme.colorScheme.onPrimary,
                              ),
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 40,
                          color: theme.colorScheme.onPrimary,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _employee?.name ?? 'Employee Profile',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _employee?.email ?? 'Manage your account settings',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
              if (_employee?.mobileNo != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primaryContainer,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _employee!.mobileNo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildStatsSection(BuildContext context) {
  //   final theme = Theme.of(context);

  //   return GridView.count(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     crossAxisCount: 3,
  //     mainAxisSpacing: AppTheme.spacingXS,
  //     crossAxisSpacing: AppTheme.spacingXS,
  //     childAspectRatio: 0.9,
  //     padding: EdgeInsets.zero,
  //     children: [
  //       _buildStatCard(
  //         context,
  //         'Test Drives',
  //         _isLoadingPerformance ? '...' : '${_performanceData?.totalTestdrives ?? 0}',
  //         Icons.directions_car_outlined,
  //         theme.colorScheme.primary,
  //       ),
  //       _buildStatCard(
  //         context,
  //         'Rating',
  //         '4.8',
  //         Icons.star_rounded,
  //         AppTheme.warningColor,
  //       ),
  //       _buildStatCard(
  //         context,
  //         'Documents',
  //         '${_employee?.documents.length ?? 0}',
  //         Icons.description_outlined,
  //         AppTheme.successColor,
  //       ),
  //     ],
  //   );
  // }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingS),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _employee!.documents.map((document) {
          return _buildDocumentItem(document, theme);
        }).toList(),
      ),
    );
  }

  Widget _buildDocumentItem(EmployeeDocument document, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDocument(document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDocumentIcon(document.documentName),
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDocumentName(document.documentName),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Added on ${_formatDate(document.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String documentName) {
    switch (documentName.toLowerCase()) {
      case 'aadhar':
        return Icons.credit_card_rounded;
      case 'pan':
        return Icons.credit_card_rounded;
      case 'license':
        return Icons.drive_file_rename_outline_rounded;
      case 'insurance':
        return Icons.security_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  String _formatDocumentName(String documentName) {
    return documentName.split(' ').map((word) {
      return word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '';
    }).join(' ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openDocument(EmployeeDocument document) async {
    if (document.fileUrl.isNotEmpty) {
      try {
        final Uri url = Uri.parse(document.fileUrl);
        
        // Show loading message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${_formatDocumentName(document.documentName)}...'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Launch the URL
        await launchUrl(url);
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open document'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document URL not available'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Logout',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutScreen(),
      ),
    );
  }

  void _navigateToPersonalInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalInfoScreen(),
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  void _showLogoutDialog() {
    LogoutUtils.showLogoutDialog(context, isEmployee: true);
  }

  Future<void> _logout() async {
    await LogoutUtils.performEmployeeLogout(context);
  }

  Widget _buildSettingsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _buildSettingTile(
          'Personal Information',
          'View your profile details',
          Icons.person_outline_rounded,
          theme.colorScheme.primary,
          () => _navigateToPersonalInfo(),
        ),
        const SizedBox(height: 8),
        _buildSettingTile(
          'Change Password',
          'Update your account password',
          Icons.lock_outline_rounded,
          AppTheme.warningColor,
          () => _navigateToChangePassword(),
        ),
        const SizedBox(height: 8),
        _buildSettingTile(
          'About',
          'App version and information',
          Icons.info_outline_rounded,
          AppTheme.successColor,
          () => _navigateToAbout(),
        ),
      ],
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildDivider(ThemeData theme) {
  //   return Divider(
  //     height: 1,
  //     color: theme.colorScheme.outline.withOpacity(0.2),
  //     indent: 56,
  //   );
  // }

  Widget _buildErrorMessage(String message) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[600],
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to be called when screen becomes visible
  void onScreenVisible() {
    // Only refresh if not already loading/fetching and not refreshed very recently
    if (_isFetching) return;
    if (_lastFetchTime != null && DateTime.now().difference(_lastFetchTime!) < _minRefreshInterval) return;
    _loadEmployeeProfile();
  }
}
