import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_home_screen.dart';
// import 'showrooms_screen.dart'; // Commented out - no longer used in bottom navigation
import 'user_expense_screen.dart';
import 'user_profile_screen.dart';
import 'test_drive_status_screen.dart';
import 'user_activities_screen.dart';
import '../../providers/user_test_drives_provider.dart';

class MainUserScreen extends StatefulWidget {
  const MainUserScreen({super.key});

  @override
  State<MainUserScreen> createState() => _MainUserScreenState();
}

class _MainUserScreenState extends State<MainUserScreen> {
  int _currentIndex = 0;
  final GlobalKey<UserProfileScreenState> _profileKey = GlobalKey<UserProfileScreenState>();
  final GlobalKey<TestDriveStatusScreenState> _statusKey = GlobalKey<TestDriveStatusScreenState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      
      // Use smart refresh to avoid unnecessary API calls
      final provider = Provider.of<UserTestDrivesProvider>(context, listen: false);
      
      if (index == 2) { // Status tab selected
        // Use smart refresh - only fetches if cache is stale
        provider.smartRefresh();
        _statusKey.currentState?.refreshData();
      } else if (index == 3) { // Activities tab selected
        // Activities screen will refresh automatically when navigated to
      } else if (index == 4) { // Profile tab selected
        // Use smart refresh for test drive counts
        provider.smartRefresh();
        _profileKey.currentState?.refreshProfileData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const UserHomeScreen(),
          // const ShowroomsScreen(), // Commented out - showroom is now shown in home screen
          const UserExpenseScreen(showBackButton: false),
          TestDriveStatusScreen(key: _statusKey, showBackButton: false),
          const UserActivitiesScreen(showBackButton: false),
          UserProfileScreen(key: _profileKey, showBackButton: false),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Expanded(child: _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                )),
                // Expanded(child: _buildNavItem(
                //   icon: Icons.store_outlined,
                //   activeIcon: Icons.store_rounded,
                //   label: 'Showrooms',
                //   index: 1,
                // )), // Commented out - showroom is now shown in home screen
                Expanded(child: _buildNavItem(
                  icon: Icons.receipt_outlined,
                  activeIcon: Icons.receipt_rounded,
                  label: 'Expenses',
                  index: 1,
                )),
                Expanded(child: _buildNavItem(
                  icon: Icons.update_outlined,
                  activeIcon: Icons.update_rounded,
                  label: 'Status',
                  index: 2,
                )),
                Expanded(child: _buildNavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'Activities',
                  index: 3,
                )),
                Expanded(child: _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  index: 4,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected 
                    ? theme.primaryColor
                    : Colors.grey[500],
                size: 20,
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                      ? theme.primaryColor
                      : Colors.grey[500],
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 