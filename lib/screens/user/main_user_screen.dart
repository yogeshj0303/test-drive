import 'package:flutter/material.dart';
import 'user_home_screen.dart';
import 'showrooms_screen.dart';
import 'search_screen.dart';
import 'user_profile_screen.dart';
import 'test_drive_status_screen.dart';

class MainUserScreen extends StatefulWidget {
  const MainUserScreen({super.key});

  @override
  State<MainUserScreen> createState() => _MainUserScreenState();
}

class _MainUserScreenState extends State<MainUserScreen> {
  int _currentIndex = 0;

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
          const ShowroomsScreen(),
          const SearchScreen(),
          const TestDriveStatusScreen(showBackButton: false),
          const UserProfileScreen(showBackButton: false),
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
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Expanded(child: _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                )),
                Expanded(child: _buildNavItem(
                  icon: Icons.store_outlined,
                  activeIcon: Icons.store_rounded,
                  label: 'Showrooms',
                  index: 1,
                )),
                Expanded(child: _buildNavItem(
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search_rounded,
                  label: 'Search',
                  index: 2,
                )),
                Expanded(child: _buildNavItem(
                  icon: Icons.update_outlined,
                  activeIcon: Icons.update_rounded,
                  label: 'Status',
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

    return GestureDetector(
      onTap: () => _onTabTapped(index),
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
    );
  }
} 