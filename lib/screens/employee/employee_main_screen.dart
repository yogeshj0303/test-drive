import 'package:DriveEasy/screens/Employee/add_expense_screen.dart';
import 'package:DriveEasy/screens/Employee/employee_profile_screen.dart';
import 'package:flutter/material.dart';
import 'employee_home_screen.dart';
import 'assigned_test_drives_screen.dart';

class EmployeeMainScreen extends StatefulWidget {
  const EmployeeMainScreen({super.key});

  @override
  State<EmployeeMainScreen> createState() => _EmployeeMainScreenState();
}

class _EmployeeMainScreenState extends State<EmployeeMainScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;
  final GlobalKey<AssignedTestDrivesScreenState> _assignedTestDrivesKey = GlobalKey<AssignedTestDrivesScreenState>();
  final GlobalKey<State<EmployeeProfileScreen>> _profileScreenKey = GlobalKey<State<EmployeeProfileScreen>>();
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const EmployeeHomeScreen(),
      AssignedTestDrivesScreen(key: _assignedTestDrivesKey, showBackButton: false),
      const AddExpenseScreen(showBackButton: false),
      EmployeeProfileScreen(key: _profileScreenKey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _previousIndex = 0;
          });
          return false; // Prevent app exit
        } else {
          // Show professional confirmation dialog
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white, // Ensures white background
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              titlePadding: const EdgeInsets.only(top: 24),
              title: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red[50],
                    radius: 28,
                    child: Icon(Icons.exit_to_app, color: Colors.red[400], size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Exit Application',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: const Text(
                'Are you sure you want to exit the app?',
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
          return shouldExit ?? false;
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
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
                  Expanded(child: _buildNavItem(
                    icon: Icons.directions_car_outlined,
                    activeIcon: Icons.directions_car_rounded,
                    label: 'Test Drives',
                    index: 1,
                  )),
                  Expanded(child: _buildNavItem(
                    icon: Icons.receipt_outlined,
                    activeIcon: Icons.receipt_rounded,
                    label: 'Expenses',
                    index: 2,
                  )),
                  Expanded(child: _buildNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 3,
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    FocusScope.of(context).unfocus(); // Dismiss keyboard on tab change
    // Check if we're navigating to the Test Drives tab from a different tab
    if (index == 1 && _previousIndex != 1) {
      // Call onScreenVisible method to refresh data
      _assignedTestDrivesKey.currentState?.onScreenVisible();
    }
    
    // Check if we're navigating to the Profile tab from a different tab
    if (index == 3 && _previousIndex != 3) {
      // Call onScreenVisible method to refresh data
      (_profileScreenKey.currentState as dynamic)?.onScreenVisible();
    }
    
    setState(() {
      _currentIndex = index;
      _previousIndex = index;
    });
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

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
                    ? const Color(0xFF3080A5)
                    : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                      ? const Color(0xFF3080A5)
                      : Colors.grey[600],
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