import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/employee_storage_service.dart';
import '../../services/employee_api_service.dart';
import '../../models/employee_model.dart';
import '../../models/activity_log_model.dart';
import 'employee_main_screen.dart';
import 'employee_notification_screen.dart';
import 'assigned_test_drives_screen.dart';
import 'update_status_screen.dart';
import 'add_expense_screen.dart';
import 'location_tracking_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Employee? _currentEmployee;
  PerformanceCountData? _performanceData;
  bool _isLoadingPerformance = true;
  List<ActivityLog> _recentActivities = [];
  bool _isLoadingActivities = true;
  String? _activityError;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
    
    // Load employee data and performance data
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    final employee = await EmployeeStorageService.getEmployeeData();
    if (mounted) {
      setState(() {
        _currentEmployee = employee;
      });
      
      // Load performance data if employee is available
      if (employee != null) {
        await _loadPerformanceData(employee.id);
        await _loadRecentActivities(employee.id);
      }
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

  Future<void> _loadRecentActivities(int userId) async {
    setState(() {
      _isLoadingActivities = true;
      _activityError = null;
    });
    try {
      final response = await EmployeeApiService().getRecentActivities(userId: userId);
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
          if (response.success) {
            _recentActivities = response.data?.data ?? [];
          } else {
            _activityError = response.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
          _activityError = 'Failed to load activities';
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color primaryBlue = Color(0xFF3080A5);
    const Color secondaryBlue = Color(0xFF0095D9);
    const Color darkGray = Color(0xFF1D1B1C);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (_currentEmployee != null) {
                    await _loadPerformanceData(_currentEmployee!.id);
                  }
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(primaryBlue),
                      const SizedBox(height: 20),
                      _buildQuickStats(primaryBlue, secondaryBlue),
                      const SizedBox(height: 24),
                      _buildQuickActions(primaryBlue),
                      const SizedBox(height: 20),
                      _buildRecentActivity(primaryBlue),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryBlue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_car, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Varenyam',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeNotificationScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_outlined, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(Color primaryBlue, Color darkGray) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue,
            primaryBlue.withOpacity(0.9),
            primaryBlue.withOpacity(0.8),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.work_outline,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${_currentEmployee?.name ?? 'Employee'}!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ready to manage today\'s test drives?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (_currentEmployee != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Showroom ID: ${_currentEmployee!.showroomId} | Status: ${_currentEmployee!.status}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  Widget _buildQuickStats(Color primaryBlue, Color secondaryBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Test Drives', 
                  _isLoadingPerformance ? '...' : '${_performanceData?.totalTestdrives ?? 0}', 
                  primaryBlue, 
                  Icons.directions_car_outlined, 
                  '${_performanceData?.pendingTestdrives ?? 0} pending'
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusCard(
                  'Pending', 
                  _isLoadingPerformance ? '...' : '${_performanceData?.pendingTestdrives ?? 0}', 
                  Colors.orange, 
                  Icons.pending_outlined, 
                  'Need attention'
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusCard(
                  'This Month', 
                  _isLoadingPerformance ? '...' : '${_performanceData?.thisMonthTestdrives ?? 0}', 
                  Colors.purple, 
                  Icons.calendar_month_outlined, 
                  '${_getCurrentMonthName()} test drives'
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String current, String target, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
              Text(
                current,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '2 pending',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
              _isLoadingPerformance 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Color primaryBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssignedTestDrivesScreen(),
                  ),
                );
              },
              child: _buildActionCard('Assigned Drives', Icons.directions_car_outlined, 'View and manage test drives', primaryBlue),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddExpenseScreen(),
                  ),
                );
              },
              child: _buildActionCard('Add Expense', Icons.receipt_long_outlined, 'Submit expense reports', Colors.green),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationSetupPage(key: GlobalKey<LocationSetupPageState>()),
                  ),
                );
              },
              child: _buildActionCard('Location Tracking', Icons.location_on_outlined, 'Track your location', Colors.purple),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeNotificationScreen(),
                  ),
                );
              },
              child: _buildActionCard('Notifications', Icons.notifications_outlined, 'View notifications', Colors.orange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Color primaryBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingActivities)
          Center(child: CircularProgressIndicator()),
        if (_activityError != null)
          Center(child: Text(_activityError!, style: TextStyle(color: Colors.red))),
        if (!_isLoadingActivities && _activityError == null)
          _recentActivities.isEmpty
              ? Center(child: Text('No recent activities'))
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _recentActivities.take(5).map((activity) {
                      return Column(
                        children: [
                          _buildActivityItem(
                            activity.operation,
                            activity.operationDescription,
                            _formatActivityTime(activity.createdAt),
                            _getActivityIcon(activity),
                            _getActivityColor(activity),
                          ),
                          if (activity != _recentActivities.take(5).last)
                            const Divider(height: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _formatActivityTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  IconData _getActivityIcon(ActivityLog activity) {
    if (activity.tableName == 'expenses') return Icons.receipt_outlined;
    if (activity.operation.toLowerCase().contains('canceled')) return Icons.cancel_outlined;
    if (activity.operation.toLowerCase().contains('completed')) return Icons.check_circle_outline;
    return Icons.info_outline;
  }

  Color _getActivityColor(ActivityLog activity) {
    if (activity.tableName == 'expenses') return Colors.blue;
    if (activity.operation.toLowerCase().contains('canceled')) return Colors.red;
    if (activity.operation.toLowerCase().contains('completed')) return Colors.green;
    return Colors.grey;
  }

  String _getCurrentMonthName() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[DateTime.now().month - 1];
  }
} 