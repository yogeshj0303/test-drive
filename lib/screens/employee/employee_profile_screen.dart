import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'personal_info_screen.dart';
import 'about_screen.dart';
import 'employee_login_screen.dart';
import '../../services/employee_storage_service.dart';
import '../../services/driver_api_service.dart';
import '../../models/employee_model.dart';
import '../../theme/app_theme.dart';

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
  PerformanceCountData? _performanceData;
  bool _isLoading = true;
  bool _isLoadingPerformance = true;
  String? _errorMessage;

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

  Future<void> _loadEmployeeProfile() async {
    // Check if we have valid cached data
    if (EmployeeProfileScreen.cachedEmployee != null && EmployeeProfileScreen.lastCacheTime != null) {
      final timeSinceLastCache = DateTime.now().difference(EmployeeProfileScreen.lastCacheTime!);
      if (timeSinceLastCache < EmployeeProfileScreen.cacheValidDuration) {
        setState(() {
          _employee = EmployeeProfileScreen.cachedEmployee;
          _isLoading = false;
        });
        // Load performance data even if employee is cached
        if (_employee != null) {
          await _loadPerformanceData(_employee!.id);
        }
        return;
      }
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get employee data from storage
      final employee = await EmployeeStorageService.getEmployeeData();
      
      if (employee != null) {
        // Fetch fresh profile data from API
        final apiResponse = await EmployeeApiService().getProfile(employee.id);
        
        if (apiResponse.success && apiResponse.data != null) {
          // Cache the data
          EmployeeProfileScreen.updateCache(apiResponse.data!.user);
          
          setState(() {
            _employee = EmployeeProfileScreen.cachedEmployee;
            _isLoading = false;
          });
          
          // Load performance data
          await _loadPerformanceData(employee.id);
        } else {
          setState(() {
            _employee = employee; // Use cached data if API fails
            _isLoading = false;
            _errorMessage = apiResponse.message;
          });
          
          // Load performance data even if profile API fails
          await _loadPerformanceData(employee.id);
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
        _errorMessage = 'Failed to load profile: ${e.toString()}';
      });
    }
  }

  Future<void> _loadPerformanceData(int driverId) async {
    setState(() {
      _isLoadingPerformance = true;
    });

    try {
      final response = await EmployeeApiService().getPerformanceCount(driverId);
      
      if (mounted) {
        setState(() {
          _isLoadingPerformance = false;
          if (response.success) {
            _performanceData = response.data!.data;
          } else {
            // Handle error - keep default values
            _performanceData = PerformanceCountData(
              totalTestdrives: 0,
              pendingTestdrives: 0,
              thisMonthTestdrives: 0,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPerformance = false;
          // Set default values on error
          _performanceData = PerformanceCountData(
            totalTestdrives: 0,
            pendingTestdrives: 0,
            thisMonthTestdrives: 0,
          );
        });
      }
    }
  }

  Future<void> _refreshProfile() async {
    // Clear cache to force fresh data
    EmployeeProfileScreen.clearCache();
    await _loadEmployeeProfile();
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
        ),
      );
    }

    if (_errorMessage != null && _employee == null) {
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
                    height: size.height * 0.28,
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
                        if (_errorMessage != null) _buildErrorMessage(_errorMessage!),
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
                                'Performance',
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
                        if (_employee?.documents.isNotEmpty == true) ...[
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
                          const SizedBox(height: AppTheme.spacingL),
                        ],
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
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
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
          padding: const EdgeInsets.all(AppTheme.spacingL),
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
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                    ),
                    child: _employee?.avatarUrl != null
                      ? Image.network(
                          _employee!.avatarUrl!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: theme.colorScheme.primary,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: theme.colorScheme.onPrimary,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 100,
                              height: 100,
                              color: theme.colorScheme.primary,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: theme.colorScheme.onPrimary,
                              ),
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 50,
                          color: theme.colorScheme.onPrimary,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                _employee?.name ?? 'Employee Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                _employee?.email ?? 'Manage your account settings',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              if (_employee?.mobileNo != null) ...[
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
                        Icons.phone_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
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
          _isLoadingPerformance ? '...' : '${_performanceData?.totalTestdrives ?? 0}',
          Icons.directions_car_outlined,
          theme.colorScheme.primary,
        ),
        _buildStatCard(
          context,
          'Rating',
          '4.8',
          Icons.star_rounded,
          AppTheme.warningColor,
        ),
        _buildStatCard(
          context,
          'Documents',
          '${_employee?.documents.length ?? 0}',
          Icons.description_outlined,
          AppTheme.successColor,
        ),
      ],
    );
  }

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
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
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
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  _getDocumentIcon(document.documentName),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
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
                    const SizedBox(height: AppTheme.spacingXS),
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
                size: 16,
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
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.spacingS),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      // Clear employee data from storage
      await EmployeeStorageService.clearEmployeeData();
      
      if (mounted) {
        // Navigate back to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const EmployeeLoginScreen(),
          ),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildSettingsSection(BuildContext context) {
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
      child: Column(
        children: [
          _buildSettingItem(
            'Personal Information',
            'View your profile details',
            Icons.person_outline_rounded,
            theme.colorScheme.primary,
            () => _navigateToPersonalInfo(),
          ),
          _buildDivider(theme),
          _buildSettingItem(
            'About',
            'App version and information',
            Icons.info_outline_rounded,
            AppTheme.successColor,
            () => _navigateToAbout(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppTheme.spacingM),
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
                    const SizedBox(height: AppTheme.spacingXS),
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
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      color: theme.colorScheme.outline.withOpacity(0.2),
      indent: 56,
    );
  }

  Widget _buildErrorMessage(String message) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
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
            size: 20,
          ),
          const SizedBox(width: 8),
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
    _refreshProfile();
  }
}
